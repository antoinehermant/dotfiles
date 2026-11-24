;;; anthe-workspaces.el --- A list of Doom workspaces a monitor -*- lexical-binding: t; -*-
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Under EXWM, each monitor shows a frame (an EXWM workspace), and each
;;  frame its own Doom workspace.  Here each monitor also has its own list of
;;  workspaces: the laptop screen keeps main, the browser, chats, the system
;;  monitor, and the external monitor the projects, from its home workspace
;;  "external".  The bar and M-1...9, SPC TAB [ ], h and l go through the
;;  list of the monitor they are on.
;;
;;  A workspace belongs to a place, internal (the laptop screen) or external,
;;  its parameter `anthe-place'.  A new one belongs to the place it is made
;;  on, and a new project to the external monitor when there is one.
;;  Switching to a workspace of the other monitor, by name (SPC TAB .) or
;;  project (SPC p p), goes to that monitor.  SPC TAB m moves the current
;;  workspace to the other monitor.
;;
;;  Without the external monitor, its workspaces show on the laptop screen
;;  (its empty home excepted), and they go back to it when it is plugged in.
;;
;;; Code:

(require 'anthe-monitors)

(defvar anthe-workspaces-homes '((internal . "main") (external . "external"))
  "The home workspace of each place, made when the place shows.")

(defvar anthe-workspaces-project-place 'external
  "Where a new project's workspace goes.")

(defvar anthe-workspaces--new-place nil
  "When non-nil, the place of the workspaces made meanwhile.")

(defun anthe-workspaces--frame-place (frame)
  "The place FRAME shows, internal or external, nil if not shown."
  (when (and (frame-live-p frame) (exwm-workspace--active-p frame))
    (let ((monitor (frame-parameter frame 'exwm-randr-monitor)))
      (if (and monitor (not (string-match-p anthe-monitors-internal-regexp monitor)))
          'external
        'internal))))

(defun anthe-workspaces--places ()
  "The places shown, internal first."
  (let ((places (delete-dups (delq nil (mapcar #'anthe-workspaces--frame-place
                                               exwm-workspace--list)))))
    (if (memq 'internal places) (cons 'internal (delq 'internal places)) places)))

(defun anthe-workspaces--frame-of (place)
  "The frame showing PLACE, the current one first."
  (seq-find (lambda (frame) (eq (anthe-workspaces--frame-place frame) place))
            (cons (selected-frame) exwm-workspace--list)))

(defun anthe-workspaces--place (name)
  "The place of the workspace NAME."
  (let ((persp (persp-get-by-name name)))
    (or (and (perspective-p persp) (persp-parameter 'anthe-place persp))
        (car (rassoc name anthe-workspaces-homes))
        ;; Made before these lists: the projects were most of them
        anthe-workspaces-project-place)))

(defun anthe-workspaces--shown-place (place)
  "Where the workspaces of PLACE show: PLACE, or the first place shown."
  (let ((places (anthe-workspaces--places)))
    (if (memq place places) place (car places))))

(defun anthe-workspaces-names (&optional frame)
  "The names of the workspaces of the monitor showing FRAME, its home first.
All of them for a frame not shown."
  (let* ((all (cl-remove persp-nil-name persp-names-cache :count 1))
         (place (anthe-workspaces--frame-place (or frame (selected-frame)))))
    (if (not place)
        all
      (let ((names (seq-filter
                    (lambda (name)
                      (let ((own (anthe-workspaces--place name)))
                        (and (eq (anthe-workspaces--shown-place own) place)
                             ;; Away from their monitor, homes but main stay hidden
                             (or (eq own place)
                                 (not (equal name (alist-get own anthe-workspaces-homes)))
                                 (equal name +workspaces-main)))))
                    all))
            (home (alist-get place anthe-workspaces-homes)))
        (if (member home names) (cons home (delete home names)) names)))))

;;; Doom's commands, through the list of the monitor

(defun anthe-workspaces--own-list-a (fn &rest args)
  "Run FN with ARGS, `+workspace-list-names' giving the monitor's workspaces."
  (cl-letf (((symbol-function '+workspace-list-names) #'anthe-workspaces-names))
    (apply fn args)))

(defun anthe-workspaces--switch-to-a (fn index)
  "Count INDEX in the monitor's workspaces; a name is looked for in all."
  (if (or (numberp index) (and (stringp index) (string-match-p "\\`[0-9]+\\'" index)))
      (anthe-workspaces--own-list-a fn index)
    (funcall fn index)))

(defun anthe-workspaces--swap-a (&optional count)
  "Move the current workspace COUNT places left in its monitor's list."
  (interactive "p")
  (let* ((own (anthe-workspaces-names))
         (current (+workspace-current-name))
         (rest (remove current own))
         (index (min (max 0 (- (or (cl-position current own :test #'equal) 0) (or count 1)))
                     (length rest)))
         (order (append (take index rest) (list current) (nthcdr index rest))))
    (unless rest
      (user-error "Only one workspace"))
    ;; The monitor's workspaces take their new order in their own slots
    (setq persp-names-cache
          (mapcar (lambda (name) (if (member name own) (pop order) name))
                  persp-names-cache))
    (+workspace/display)))

(defun anthe-workspaces--swap-right-a (&optional count)
  "Move the current workspace COUNT places right in its monitor's list."
  (interactive "p")
  (anthe-workspaces--swap-a (- (or count 1))))

;;; Places

(defun anthe-workspaces--created-h (persp &rest _)
  "Give the new workspace PERSP the place it is made in."
  (when (and (perspective-p persp)
             (not (persp-parameter 'anthe-place persp)))
    (set-persp-parameter
     'anthe-place
     (or (car (rassoc (persp-name persp) anthe-workspaces-homes))
         anthe-workspaces--new-place
         (anthe-workspaces--frame-place (selected-frame))
         'internal)
     persp)))

(defun anthe-workspaces--project-a (fn &rest args)
  "Open a new project's workspace on `anthe-workspaces-project-place'.
Without that monitor, it shows here until it is plugged in."
  (let ((anthe-workspaces--new-place anthe-workspaces-project-place))
    (apply fn args)))

(defun anthe-workspaces--go-a (name &rest _)
  "Go to the monitor of the workspace NAME, unless it shows here."
  (when-let* (((+workspace-exists-p name))
              (place (anthe-workspaces--shown-place (anthe-workspaces--place name)))
              ((not (eq place (anthe-workspaces--frame-place (selected-frame)))))
              (frame (anthe-workspaces--frame-of place)))
    (exwm-workspace-switch frame)))

(defun anthe-workspaces--back (frame)
  "Show on FRAME a workspace of its own: its last, or its home."
  (let* ((own (anthe-workspaces-names frame))
         (last (frame-parameter frame 'anthe-workspaces-last))
         (home (alist-get (anthe-workspaces--frame-place frame) anthe-workspaces-homes)))
    (persp-frame-switch (cond ((member last own) last)
                              ((member home own) home)
                              (t (or (car own) +workspaces-main)))
                        frame)))

(defun anthe-workspaces--remember-h (&rest _)
  "Remember the workspace shown, to go back to it."
  (let ((name (+workspace-current-name)))
    (when (member name (anthe-workspaces-names))
      (set-frame-parameter nil 'anthe-workspaces-last name))))

(defun anthe-workspaces-move ()
  "Move the current workspace to the other monitor's list, and go with it."
  (interactive)
  (let* ((name (+workspace-current-name))
         (from (anthe-workspaces--frame-place (selected-frame)))
         (to (if (eq (anthe-workspaces--place name) 'external) 'internal 'external))
         (persp (+workspace-get name)))
    (when (rassoc name anthe-workspaces-homes)
      (user-error "%s stays on its monitor" name))
    (set-persp-parameter 'anthe-place to persp)
    (let ((frame (anthe-workspaces--frame-of to)))
      (if (or (not frame) (eq to from))
          (message "Workspace %s: on the %s monitor's list, shown here until it is plugged in"
                   name to)
        (let ((here (selected-frame)))
          (anthe-workspaces--back here)
          (persp-frame-switch name frame)
          (exwm-workspace-switch frame)
          (message "Workspace %s: moved to the %s monitor" name to))))))

(defun anthe-workspaces-settle ()
  "Make the homes of the places shown, and give each monitor its own.
A workspace shown on another monitor than its own, plugged in meanwhile,
goes back to its own."
  (when (bound-and-true-p persp-mode)
    (dolist (place (anthe-workspaces--places))
      (let ((home (alist-get place anthe-workspaces-homes)))
        (unless (+workspace-exists-p home)
          (save-window-excursion
            (let ((anthe-workspaces--new-place place))
              (+workspace-new home))))))
    (dolist (frame exwm-workspace--list)
      (when-let* ((place (anthe-workspaces--frame-place frame))
                  (name (safe-persp-name (get-frame-persp frame)))
                  ((not (member name (anthe-workspaces-names frame)))))
        (let ((own (anthe-workspaces--frame-of
                    (anthe-workspaces--shown-place (anthe-workspaces--place name)))))
          (anthe-workspaces--back frame)
          (when (and own (not (eq own frame)))
            (persp-frame-switch name own)))))
    (when (fboundp 'anthe-bar--look)
      (anthe-bar--look))))

(with-eval-after-load 'persp-mode
  (add-hook 'persp-created-functions #'anthe-workspaces--created-h)
  (add-hook 'persp-activated-functions #'anthe-workspaces--remember-h))

(dolist (fn '(+workspace/cycle +workspace/switch-to-final +workspace--tabline
              +workspace/close-window-or-workspace))
  (advice-add fn :around #'anthe-workspaces--own-list-a))
(advice-add '+workspace/switch-to :around #'anthe-workspaces--switch-to-a)
(advice-add '+workspace/swap-left :override #'anthe-workspaces--swap-a)
(advice-add '+workspace/swap-right :override #'anthe-workspaces--swap-right-a)
(advice-add '+workspaces-switch-to-project-h :around #'anthe-workspaces--project-a)
(advice-add '+workspace-switch :before #'anthe-workspaces--go-a)

;; After each change of the monitors
(advice-add 'anthe-monitors--update-workspaces :after #'anthe-workspaces-settle)
(when exwm-workspace--list
  (anthe-workspaces-settle))

(map! :leader
      :desc "Move workspace to other monitor" "TAB m" #'anthe-workspaces-move
      :desc "Left workspace" "TAB h" #'+workspace/switch-left
      :desc "Right workspace" "TAB l" #'+workspace/switch-right)

(provide 'anthe-workspaces)
;;; anthe-workspaces.el ends here
