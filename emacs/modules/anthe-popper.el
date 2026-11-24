;;; anthe-popper.el --- Popups at the bottom, a tab each -*- lexical-binding: t; -*-
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Popper shows the vterms, the Python shells, *Messages*, help... as popups
;;  at the bottom of the frame.
;;
;;  The popups belong to the workspace they are made or shown in (Doom's,
;;  persp), not to a project: a vterm stays in its workspace when it changes
;;  directory.  Those of no workspace (*Messages*) are in all.
;;  The popup window has a tab line, the workspace's popups a tab each in a
;;  fixed order, an icon for their kind, the one shown highlighted as in the
;;  top bar; a click shows one.
;;
;;  M-` shows the popup, then the next tab, and so on; with a negative
;;  prefix the previous one.  It takes the tabs as they are, so a popup is
;;  never left out (popper's own cycle forgot those not yet closed once).
;;  SPC ` shows or hides the popup.
;;
;;; Code:

(add-to-list 'load-path "~/.config/emacs/.local/straight/repos/popper/")
(use-package! popper
  :bind (("M-`"   . popper-cycle)
         ("C-M-`" . popper-toggle-type))
  :init
  (setq popper-reference-buffers
        '("^\\*Messages\\*"
          "^Output\\*"
          "^\\*Async Shell Command\\*"
          "^\\*vterm"
          "^\\*Python"
          "^\\*compilation"
          "*doom eval*"
          help-mode
          compilation-mode
          "\\*eshell*\\*$" eshell-mode
          "\\*vterm*\\*$" vterm-mode))
  (popper-mode +1))

(map! :leader
      :desc "popper" "`" #'popper-toggle)

;;; The workspace's popups

(defun anthe/popper-group ()
  "The popups' group: the current workspace."
  (if (bound-and-true-p persp-mode) (+workspace-current-name) "main"))

(setq popper-group-function #'anthe/popper-group)

(defun anthe/popper-attach-h ()
  "A popup buffer made (a vterm, a Python shell...) joins the current workspace."
  (when (and (bound-and-true-p persp-mode)
             (popper-popup-p (current-buffer))
             (not (persp-contain-buffer-p (current-buffer))))
    (persp-add-buffer (current-buffer) (get-current-persp) nil)))

(add-hook 'after-change-major-mode-hook #'anthe/popper-attach-h)

(defun anthe/popper-buffers ()
  "The popups of the current workspace, and those of none (*Messages*), in
a fixed order: by name, numbers as numbers (vterm<2> before vterm<10>)."
  (sort (seq-filter (lambda (buffer)
                      (and (popper-popup-p buffer)
                           (not (eq (buffer-local-value 'popper-popup-status buffer) 'raised))
                           (or (not (bound-and-true-p persp-mode))
                               (persp-contain-buffer-p buffer)
                               (null (persp--buffer-in-persps buffer)))))
                    (buffer-list))
        (lambda (a b) (string-version-lessp (buffer-name a) (buffer-name b)))))

(defun anthe/popper-window ()
  "The popup window open in this frame, if any."
  (seq-find (lambda (window)
              (memq (buffer-local-value 'popper-popup-status (window-buffer window))
                    '(popup user-popup)))
            (window-list nil 'no-mini)))

(defun anthe/popper-cycle (&optional count)
  "Show the popup, or the COUNTth next tab in it (backwards if negative)."
  (interactive "p")
  (let* ((buffers (anthe/popper-buffers))
         (window (anthe/popper-window)))
    (cond
     ((null buffers) (message "No popup in this workspace"))
     ((null window)
      ;; The one used last
      (pop-to-buffer (seq-find (lambda (buffer) (memq buffer buffers)) (buffer-list))))
     (t
      (let* ((index (or (cl-position (window-buffer window) buffers) 0))
             (next (nth (mod (+ index (or count 1)) (length buffers)) buffers)))
        (set-window-buffer window next)
        (select-window window))))))

(define-key global-map [remap popper-cycle] #'anthe/popper-cycle)

;;; The tabs

(defun anthe/popper-tab-name (buffer &optional _buffers)
  "BUFFER's tab: its kind's icon and its name, without the stars, its number
after a space (vterminal<2>: vterm 2)."
  (let ((name (string-trim (thread-last (buffer-name buffer)
                             (string-replace "vterminal" "vterm")
                             (replace-regexp-in-string "<\\([0-9]+\\)>" " \\1"))
                           "[ *]+" "[ *]+")))
    (concat " "
            (or (and (display-graphic-p)
                     (with-current-buffer buffer
                       (ignore-errors (nerd-icons-icon-for-mode major-mode))))
                "")
            " " name " ")))

(defun anthe/popper-tabs-h (&rest _)
  "A tab line on the popups shown, and the popups in the current workspace."
  (dolist (window (window-list nil 'no-mini))
    (let ((buffer (window-buffer window)))
      (when (memq (buffer-local-value 'popper-popup-status buffer) '(popup user-popup))
        (when (and (bound-and-true-p persp-mode) (not (persp-contain-buffer-p buffer)))
          (persp-add-buffer buffer (get-current-persp) nil))
        (with-current-buffer buffer
          (unless tab-line-mode
            (setq-local tab-line-tabs-function #'anthe/popper-buffers
                        tab-line-tab-name-function #'anthe/popper-tab-name
                        tab-line-close-button-show nil
                        tab-line-new-button-show nil
                        tab-line-switch-cycling t)
            (tab-line-mode 1)))))))

(advice-add 'popper--update-popups :after #'anthe/popper-tabs-h)

;; Raised to a window of its own, no more tabs
(advice-add 'popper-raise-popup :after
            (lambda (&optional buffer)
              (with-current-buffer (or buffer (current-buffer))
                (tab-line-mode -1)))
            '((name . anthe/popper-no-tabs)))

(defun anthe/popper-colours (&rest _)
  "The tabs as the top bar's workspaces."
  (when (facep 'tab-line)
    (let ((background (face-background 'mode-line nil t)))
      (set-face-attribute 'tab-line nil :background background
                          :foreground (face-foreground 'mode-line nil t)
                          :box nil :inherit 'unspecified :height 1.0)
      (set-face-attribute 'tab-line-tab-inactive nil :background background
                          :foreground (face-foreground (if (facep 'anthe-bar-workspace)
                                                           'anthe-bar-workspace
                                                         'shadow)
                                                       nil t)
                          :box nil :inherit 'unspecified)
      ;; The tab shown, the window selected or not
      (dolist (face '(tab-line-tab tab-line-tab-current))
        (set-face-attribute face nil :box nil :weight 'bold
                            :inherit (if (facep 'anthe-bar-current-workspace)
                                         'anthe-bar-current-workspace
                                       'highlight)))
      (set-face-attribute 'tab-line-tab-special nil :slant 'normal)
      (set-face-attribute 'tab-line-highlight nil :box nil :inherit 'highlight))))

(with-eval-after-load 'tab-line
  (anthe/popper-colours)
  (add-hook 'doom-load-theme-hook #'anthe/popper-colours))

(provide 'anthe-popper)
;;; anthe-popper.el ends here
