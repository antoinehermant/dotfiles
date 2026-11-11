;;; anthe-monitors.el --- Monitors plugged in and out under EXWM -*- lexical-binding: t; -*-
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  A monitor service like those of the usual desktops: when a monitor is
;;  plugged in or out, the autorandr profile matching the monitors is loaded,
;;  and an unknown monitor extends the laptop screen.  The workspaces follow:
;;  workspace 0 on the laptop screen, 1 on the first external monitor, 2 on
;;  the second, whatever the output (HDMI-1, DP-1, ...).
;;
;;  SPC k m m switches between extending and mirroring the laptop screen,
;;  SPC k m s swaps the workspaces of the laptop and of the external monitor,
;;  SPC k m p chooses the primary monitor, the one a browser shares when it
;;  does not ask which (qutebrowser, for Zoom), and SPC k m d applies the
;;  monitors again, probing them first.
;;
;;; Code:

(require 'exwm-randr)

(defvar anthe-monitors-internal-regexp "\\`\\(eDP\\|LVDS\\)"
  "Regexp matching the name of the laptop screen output.")

(defvar anthe-monitors-extend-side "--right-of"
  "Where an unknown monitor goes, an xrandr option: --right-of or --left-of.")

(defvar anthe-monitors--connected nil
  "The names of the connected outputs, when the monitors were last applied.")

(defvar anthe-monitors--timer nil)

(defun anthe-monitors--outputs (&optional probe)
  "Return the outputs, each a plist (:name :connected :primary :geometry :modes
:mode :preferred).  The geometry is (X Y W H) when the output is on, :modes
are the standard modes, :mode the current one and :preferred the one the
monitor asks for, custom modes included.  With PROBE, the outputs are
probed again, which takes a while and makes some screens blink."
  (let (outputs)
    (dolist (line (process-lines-ignore-status "xrandr" (if probe "--query" "--current")))
      (cond ((string-match "\\`\\([^ ]+\\) \\(connected\\|disconnected\\)\\( primary\\)?\\(?: \\([0-9]+\\)x\\([0-9]+\\)\\+\\([0-9]+\\)\\+\\([0-9]+\\)\\)?" line)
             (push (list :name (match-string 1 line)
                         :connected (equal (match-string 2 line) "connected")
                         :primary (and (match-string 3 line) t)
                         :geometry (and (match-string 4 line)
                                        (mapcar (lambda (i) (string-to-number (match-string i line)))
                                                '(6 7 4 5))))
                   outputs))
            ((and outputs (string-match "\\`   \\([0-9]+x[0-9]+[^ ]*\\) +\\(.*\\)" line))
             (let ((output (car outputs))
                   (mode (match-string 1 line))
                   (rates (match-string 2 line)))
               (when (string-match-p "\\`[0-9]+x[0-9]+\\'" mode)
                 (setq output (plist-put output :modes
                                         (append (plist-get output :modes) (list mode)))))
               (when (string-search "*" rates)
                 (setq output (plist-put output :mode mode)))
               (when (string-search "+" rates)
                 (setq output (plist-put output :preferred mode)))
               (setcar outputs output)))))
    (nreverse outputs)))

(defun anthe-monitors--internal (outputs)
  "Return the laptop screen of OUTPUTS."
  (seq-find (lambda (o) (string-match-p anthe-monitors-internal-regexp (plist-get o :name)))
            outputs))

(defun anthe-monitors--externals (outputs)
  "Return the connected external monitors of OUTPUTS."
  (seq-filter (lambda (o) (and (plist-get o :connected)
                               (not (string-match-p anthe-monitors-internal-regexp
                                                    (plist-get o :name)))))
              outputs))

(defun anthe-monitors--mirrored-p (output internal)
  "Return non-nil if OUTPUT shows the same place as INTERNAL, mirroring it."
  (let ((a (plist-get output :geometry))
        (b (plist-get internal :geometry)))
    (and a b (equal (take 2 a) (take 2 b)))))

(defun anthe-monitors--xrandr (&rest args)
  "Run xrandr with ARGS, and return non-nil if it succeeded."
  (let ((status (apply #'call-process "xrandr" nil nil nil args)))
    (or (eql status 0)
        (progn (message "Monitors: xrandr %s failed" (string-join args " "))
               nil))))

(defun anthe-monitors--update-workspaces ()
  "Put workspace 0 on the laptop screen and the next ones on the external
monitors, from left to right, and lay the workspaces out again."
  (let* ((outputs (anthe-monitors--outputs))
         (internal (anthe-monitors--internal outputs))
         (externals (seq-filter (lambda (o) (and (plist-get o :geometry)
                                                 (not (and internal (anthe-monitors--mirrored-p o internal)))))
                                (anthe-monitors--externals outputs)))
         (externals (sort externals (lambda (a b) (< (car (plist-get a :geometry))
                                                     (car (plist-get b :geometry))))))
         (plist nil)
         (index 0))
    (when (and internal (plist-get internal :geometry))
      (setq plist (list 0 (plist-get internal :name))
            index 1))
    (dolist (output externals)
      (setq plist (append plist (list index (plist-get output :name)))
            index (1+ index)))
    (setq exwm-randr-workspace-monitor-plist plist)
    (exwm-randr-refresh)
    (when (fboundp 'efs/set-wallpaper)
      (efs/set-wallpaper))))

(defun anthe-monitors--autorandr ()
  "Load the autorandr profile matching the connected monitors, if any.
Return the name of the profile."
  (when-let* (((executable-find "autorandr"))
              (profile (car (process-lines-ignore-status "autorandr" "--detected"))))
    (call-process "autorandr" nil nil nil "--load" profile)
    ;; The Philips monitor needs a mode its EDID does not give
    (when (fboundp 'anthe/philips-display)
      (anthe/philips-display))
    profile))

(defun anthe-monitors--extend (internal external)
  "Extend the screen of INTERNAL onto EXTERNAL."
  (if internal
      (anthe-monitors--xrandr "--output" (plist-get external :name) "--auto" "--scale" "1x1"
                              anthe-monitors-extend-side (plist-get internal :name))
    (anthe-monitors--xrandr "--output" (plist-get external :name) "--auto" "--scale" "1x1")))

(defun anthe-monitors--mirror (internal externals)
  "Show the screen of INTERNAL on EXTERNALS too.
INTERNAL takes its own resolution.  EXTERNALS keep their mode (the one of their
autorandr profile), or take the one they prefer, and show the whole screen
scaled to it, a little stretched when their shape is not the one of INTERNAL."
  (let ((size (plist-get internal :preferred)))
    (apply #'anthe-monitors--xrandr
           "--output" (plist-get internal :name) "--auto" "--pos" "0x0" "--scale" "1x1"
           (mapcan (lambda (o)
                     (list "--output" (plist-get o :name)
                           "--mode" (or (and (plist-get o :geometry) (plist-get o :mode))
                                        (plist-get o :preferred))
                           "--pos" "0x0" "--scale-from" size))
                   externals))))

(defun anthe-monitors-apply (&optional probe)
  "Set up the connected monitors.
The autorandr profile matching them is loaded, and without one, the external
monitors that are off extend the laptop screen, and the disconnected ones are
turned off.  With PROBE, the outputs are probed first."
  (interactive (list t))
  (let* ((outputs (anthe-monitors--outputs probe))
         (internal (anthe-monitors--internal outputs))
         (profile (anthe-monitors--autorandr)))
    (unless profile
      (dolist (output outputs)
        (cond ((and (not (plist-get output :connected)) (plist-get output :geometry))
               (anthe-monitors--xrandr "--output" (plist-get output :name) "--off"))
              ((and (plist-get output :connected) (not (plist-get output :geometry))
                    (not (eq output internal)))
               (anthe-monitors--extend internal output)))))
    (setq anthe-monitors--connected
          (mapcar (lambda (o) (plist-get o :name))
                  (seq-filter (lambda (o) (plist-get o :connected)) (anthe-monitors--outputs))))
    (anthe-monitors--update-workspaces)
    (message "Monitors: %s%s" (string-join anthe-monitors--connected ", ")
             (if profile (format " (autorandr %s)" profile) " (SPC k m m to mirror)"))))

(defun anthe-monitors--check ()
  "Set up the monitors if some were plugged in or out."
  (setq anthe-monitors--timer nil)
  (let ((connected (mapcar (lambda (o) (plist-get o :name))
                           (seq-filter (lambda (o) (plist-get o :connected))
                                       (anthe-monitors--outputs)))))
    (unless (equal connected anthe-monitors--connected)
      (anthe-monitors-apply))))

(defun anthe-monitors--schedule ()
  "Check the monitors in a moment, once the RandR events have settled.
EXWM refreshes its layout on each of them, plugging a monitor included."
  (when (timerp anthe-monitors--timer)
    (cancel-timer anthe-monitors--timer))
  (setq anthe-monitors--timer (run-at-time 1 nil #'anthe-monitors--check)))

(defun anthe-monitors-toggle-mirror ()
  "Mirror the laptop screen on the external monitors, or extend it onto them."
  (interactive)
  (let* ((outputs (anthe-monitors--outputs))
         (internal (anthe-monitors--internal outputs))
         (externals (anthe-monitors--externals outputs)))
    (unless (and internal (plist-get internal :geometry) externals)
      (user-error "Monitors: no external monitor next to the laptop screen"))
    (if (seq-some (lambda (o) (anthe-monitors--mirrored-p o internal)) externals)
        (progn
          ;; Back to the resolution of the laptop, and to the autorandr
          ;; profile of the monitors, if they have one
          (anthe-monitors--xrandr "--output" (plist-get internal :name) "--auto" "--scale" "1x1")
          (unless (anthe-monitors--autorandr)
            (dolist (output externals)
              (anthe-monitors--extend internal output)))
          (message "Monitors: extended"))
      (anthe-monitors--mirror internal externals)
      (message "Monitors: mirrored"))
    (anthe-monitors--update-workspaces)))

(defun anthe-monitors-swap ()
  "Swap the current workspace with the one shown on the other monitor.
To present on the external monitor at its own resolution, the windows being
laid out again rather than scaled as in a mirror.  The workspaces go back
when monitors are plugged in or out, or with this command again."
  (interactive)
  (let* ((current exwm-workspace--current)
         (monitor (frame-parameter current 'exwm-randr-monitor))
         (other (seq-find (lambda (frame)
                            (and (exwm-workspace--active-p frame)
                                 (not (equal (frame-parameter frame 'exwm-randr-monitor) monitor))))
                          exwm-workspace--list)))
    (unless other
      (user-error "Monitors: no workspace on another monitor (mirrored?)"))
    (let ((plist (copy-sequence exwm-randr-workspace-monitor-plist)))
      (setq plist (plist-put plist (exwm-workspace--position current)
                             (frame-parameter other 'exwm-randr-monitor)))
      (setq plist (plist-put plist (exwm-workspace--position other) monitor))
      (setq exwm-randr-workspace-monitor-plist plist))
    (exwm-randr-refresh)
    (exwm-workspace-switch current)))

(defun anthe-monitors-set-primary ()
  "Choose the primary monitor.
It is the one shared by a browser that does not ask which screen to share,
such as qutebrowser in a Zoom call."
  (interactive)
  (let* ((outputs (seq-filter (lambda (o) (plist-get o :geometry)) (anthe-monitors--outputs)))
         (name (completing-read "Primary monitor: "
                                (mapcar (lambda (o) (plist-get o :name)) outputs)
                                nil t nil nil
                                (plist-get (seq-find (lambda (o) (not (plist-get o :primary))) outputs)
                                           :name))))
    (when (anthe-monitors--xrandr "--output" name "--primary")
      (message "Monitors: %s is primary" name))))

(defun anthe-monitors--init ()
  "Set up the monitors, and again whenever some are plugged in or out."
  (add-hook 'exwm-randr-refresh-hook #'anthe-monitors--schedule)
  (anthe-monitors-apply))

;; Not on `exwm-randr-screen-change-hook': the screen size does not change
;; when a monitor is plugged in, and it does when mirroring
(if exwm-randr--connection
    (anthe-monitors--init)
  ;; After the initialization of exwm-randr, also on this hook
  (add-hook 'exwm-init-hook #'anthe-monitors--init 90))

(map! :leader
      (:prefix ("k m" . "monitors")
       :desc "Mirror or extend" "m" #'anthe-monitors-toggle-mirror
       :desc "Swap workspaces between monitors" "s" #'anthe-monitors-swap
       :desc "Primary (shared) monitor" "p" #'anthe-monitors-set-primary
       :desc "Detect monitors" "d" #'anthe-monitors-apply))

(provide 'anthe-monitors)
;;; anthe-monitors.el ends here
