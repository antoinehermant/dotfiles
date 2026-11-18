;;; anthe-bar.el --- A top bar for EXWM -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  A status bar at the top of each EXWM workspace, like a desktop's: the
;;  Doom workspaces on the left, the current one highlighted (a click
;;  switches), the date and time in the middle (a click opens the calendar),
;;  and Bluetooth, the network and the battery on the right.
;;
;;  It is Emacs's own tab bar, shown on the EXWM workspaces only, not on
;;  floating windows.  While it shows, the time and the battery leave the
;;  mode line.  SPC t B hides or shows it.
;;
;;; Code:

(require 'tab-bar)
(require 'dbus)
(require 'battery)
(require 'nerd-icons)

(defvar anthe-bar-shown t
  "Whether the bar shows; `anthe-bar-toggle' switches it.")

(defvar anthe-bar-interval 5
  "Seconds between two looks at Bluetooth, the network and the battery.")

(defvar anthe-bar--status nil
  "The right side of the bar, a list of (TEXT . HELP), from the last look.")

(defvar anthe-bar--timer nil)

(defface anthe-bar-clock '((t :weight bold))
  "The date and time in the bar.")

;;; Left: the workspaces

(defun anthe-bar--workspaces ()
  "The Doom workspaces of this frame, the current one highlighted."
  (when (fboundp '+workspace-list-names)
    (let ((current (+workspace-current-name)))
      (seq-map-indexed
       (lambda (name i)
         ;; The current one's key differs: the tab bar is redrawn only when
         ;; its items change, compared without their faces
         `(,(intern (format (if (equal name current)
                                "anthe-bar-current-workspace-%d"
                              "anthe-bar-workspace-%d")
                            i))
           menu-item
           ,(propertize (format " %d %s " (1+ i) name)
                        'face (if (equal name current)
                                  '+workspace-tab-selected-face
                                '+workspace-tab-face))
           ,(lambda () (interactive) (+workspace/switch-to name))
           :help ,(format "Switch to %s" name)))
       (+workspace-list-names)))))

;;; Middle: the date and time

(defun anthe-bar--clock ()
  "The date and time, centred."
  (let* ((time (propertize (format-time-string "%a %-d %b  %H:%M")
                           'face 'anthe-bar-clock))
         (half (/ (string-pixel-width (propertize time 'face '(anthe-bar-clock tab-bar))) 2)))
    `((anthe-bar-centre menu-item
       ,(propertize " " 'display `(space :align-to (- center (,half))))
       ignore)
      (anthe-bar-clock menu-item ,time calendar
       :help ,(format-time-string "%A %-d %B %Y, week %V")))))

;;; Right: Bluetooth, the network, the battery

(defun anthe-bar--icon (name &optional face)
  (nerd-icons-mdicon name :face face :v-adjust 0.0))

(defun anthe-bar--bluetooth ()
  "Off, on, or connected: the headphones by name with their battery, the
keyboard and mouse only in the help."
  (let* ((objects (mapcar #'cadr (dbus-get-all-managed-objects :system "org.bluez" "/")))
         (adapter (seq-some (lambda (o) (cadr (assoc "org.bluez.Adapter1" o))) objects))
         (devices
          (delq nil
                (mapcar
                 (lambda (o)
                   (let ((device (cadr (assoc "org.bluez.Device1" o)))
                         (battery (cadr (assoc "org.bluez.Battery1" o))))
                     (when (cdr (assoc "Connected" device))
                       (cons (concat (cdr (assoc "Alias" device))
                                     (when battery
                                       (format " %d%%" (cdr (assoc "Percentage" battery)))))
                             (string-prefix-p "audio" (or (cdr (assoc "Icon" device)) ""))))))
                 objects)))
         (audio (mapcar #'car (seq-filter #'cdr devices))))
    (cond
     ((not adapter) nil)
     ((not (cdr (assoc "Powered" adapter)))
      (cons (anthe-bar--icon "nf-md-bluetooth_off" 'shadow) "Bluetooth off"))
     (devices
      (cons (concat (anthe-bar--icon "nf-md-bluetooth_connect")
                    (when audio (concat " " (string-join audio ", "))))
            (concat "Bluetooth: " (string-join (mapcar #'car devices) ", "))))
     (t (cons (anthe-bar--icon "nf-md-bluetooth") "Bluetooth on, nothing connected")))))

(defun anthe-bar--nm (path interface property)
  (dbus-get-property :system "org.freedesktop.NetworkManager" path
                     (concat "org.freedesktop.NetworkManager" interface) property))

(defun anthe-bar--network ()
  "The connection used, its Wi-Fi strength, and a VPN if one is on."
  (let* ((primary (anthe-bar--nm "/org/freedesktop/NetworkManager" "" "PrimaryConnection"))
         (connected (and primary (not (equal primary "/"))))
         (type (and connected (anthe-bar--nm primary ".Connection.Active" "Type")))
         (name (and connected (anthe-bar--nm primary ".Connection.Active" "Id")))
         (vpn (seq-some
               (lambda (path)
                 (or (anthe-bar--nm path ".Connection.Active" "Vpn")
                     (equal (anthe-bar--nm path ".Connection.Active" "Type") "wireguard")))
               (anthe-bar--nm "/org/freedesktop/NetworkManager" "" "ActiveConnections")))
         (link
          (cond
           ((not connected)
            (cons (anthe-bar--icon "nf-md-wifi_off" 'warning) "Offline"))
           ((equal type "802-11-wireless")
            (let* ((ap (anthe-bar--nm primary ".Connection.Active" "SpecificObject"))
                   (strength (or (ignore-errors (anthe-bar--nm ap ".AccessPoint" "Strength")) 100)))
              (cons (concat (anthe-bar--icon (format "nf-md-wifi_strength_%d"
                                                     (max 1 (min 4 (ceiling strength 25)))))
                            " " name)
                    (format "Wi-Fi %s, %d%%" name strength))))
           (t (cons (anthe-bar--icon "nf-md-ethernet") (format "Wired: %s" name))))))
    (if vpn
        (cons (concat (anthe-bar--icon "nf-md-vpn" 'success) " " (car link))
              (concat (cdr link) ", VPN on"))
      link)))

(defun anthe-bar--sentence (text)
  "TEXT, like \"fully-charged\", as \"Fully charged\"."
  (let ((text (string-replace "-" " " (or text ""))))
    (if (string-empty-p text) text
      (concat (upcase (substring text 0 1)) (substring text 1)))))

(defun anthe-bar--battery ()
  "The battery's charge, charging or not, and the time left."
  (let* ((status (funcall battery-status-function))
         (percent (string-to-number (or (alist-get ?p status) "")))
         (state (alist-get ?B status))
         (charging (member state '("charging" "fully-charged" "pending-charge")))
         (tens (* 10 (max 1 (min 10 (round percent 10)))))
         (icon (cond (charging (format "nf-md-battery_charging_%d" tens))
                     ((= tens 100) "nf-md-battery")
                     (t (format "nf-md-battery_%d" tens))))
         (face (cond (charging nil)
                     ((<= percent 10) 'error)
                     ((<= percent 20) 'warning)))
         (time (alist-get ?t status)))
    (when (alist-get ?p status)
      (cons (concat (anthe-bar--icon icon face) " "
                    (propertize (format "%d%%" percent) 'face face))
            (concat (anthe-bar--sentence state)
                    (unless (member time '(nil "" "0:00" "N/A"))
                      (format ", %s %s" time (if charging "to full" "left"))))))))

(defun anthe-bar--look ()
  "Look at Bluetooth, the network and the battery, and redraw the bar."
  (setq anthe-bar--status
        (delq nil (mapcar (lambda (look) (ignore-errors (funcall look)))
                          '(anthe-bar--bluetooth anthe-bar--network anthe-bar--battery))))
  (force-mode-line-update t))

(defun anthe-bar--right ()
  "The status, against the right edge.  Its width is measured a little
over (icons and faces vary), else the tab bar wraps it on a second line."
  (let* ((items (seq-map-indexed
                 (lambda (item i)
                   `(,(intern (format "anthe-bar-status-%d" i)) menu-item
                     ,(concat "  " (car item)) ignore :help ,(cdr item)))
                 anthe-bar--status))
         (text (mapconcat (lambda (item) (nth 2 item)) items ""))
         (width (string-pixel-width (propertize text 'face 'tab-bar))))
    (cons `(anthe-bar-right menu-item
            ,(propertize " " 'display
                         `(space :align-to (- right (,(+ width (* 2 (frame-char-width)))))))
            ignore)
          items)))

(setq tab-bar-format '(anthe-bar--workspaces anthe-bar--clock anthe-bar--right))

;;; The colours: the mode line's, the themes' tab bar being for tabs

(defun anthe-bar--colours (&rest _)
  (set-face-attribute 'tab-bar nil
                      :background (face-background 'mode-line nil t)
                      :foreground (face-foreground 'mode-line nil t)
                      :box nil :inherit 'unspecified))

(anthe-bar--colours)
(add-hook 'doom-load-theme-hook #'anthe-bar--colours)

;;; Showing and hiding

(defun anthe-bar--frames ()
  (if (bound-and-true-p exwm-workspace--list) exwm-workspace--list (list (selected-frame))))

(defun anthe-bar--apply ()
  "Show or hide the bar on every workspace, as `anthe-bar-shown' says."
  (dolist (frame (anthe-bar--frames))
    (set-frame-parameter frame 'tab-bar-lines-keep-state t)
    (set-frame-parameter frame 'tab-bar-lines (if anthe-bar-shown 1 0)))
  (when anthe-bar--timer (cancel-timer anthe-bar--timer))
  (setq anthe-bar--timer
        (and anthe-bar-shown (run-at-time nil anthe-bar-interval #'anthe-bar--look)))
  ;; The time and the battery are in the bar or in the mode line
  (display-time-mode (if anthe-bar-shown -1 1))
  (display-battery-mode (if anthe-bar-shown -1 1)))

(defun anthe-bar-toggle ()
  "Hide or show the top bar."
  (interactive)
  (setq anthe-bar-shown (not anthe-bar-shown))
  (anthe-bar--apply))

(defun anthe-bar--redraw (&rest _)
  (force-mode-line-update t))

(add-hook 'persp-activated-functions #'anthe-bar--redraw)
(add-hook 'persp-renamed-functions #'anthe-bar--redraw)
(add-hook 'exwm-workspace-list-change-hook #'anthe-bar--apply)
(if (bound-and-true-p exwm-workspace--list)
    (anthe-bar--apply)
  (add-hook 'exwm-init-hook #'anthe-bar--apply))

(map! :leader :desc "Top bar" "t B" #'anthe-bar-toggle)

(provide 'anthe-bar)
;;; anthe-bar.el ends here
