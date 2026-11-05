;;; anthe-sysmon.el --- Read-only btop system monitor -*- lexical-binding: t; -*-
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Toggle a read-only btop running in vterm, displayed like any other buffer.
;;
;;  The buffer name and the derived major mode keep it out of popper, which
;;  matches `vterm-mode' exactly and "*vterm*" by name.
;;
;;; Code:

(require 'vterm)

(defvar anthe-sysmon-buffer-name "*sysmon*"
  "Name of the system monitor buffer.")

;; btop rewrites its config, so this is written out again at each start.  The
;; TTY theme uses the 16 terminal colors, which vterm takes from the Emacs theme.
(defvar anthe-sysmon-btop-config
  "color_theme = \"TTY\"
theme_background = False
truecolor = False
shown_boxes = \"cpu mem net proc\"
update_ms = 2000
"
  "Content of the config file for the btop instance run by sysmon.")

(defvar anthe-sysmon-read-only-map
  (let ((map (make-sparse-keymap)))
    (suppress-keymap map t)
    (define-key map "q" #'anthe-sysmon-quit)
    ;; The buffer is in Emacs state, where Doom only binds the alternate leader
    (define-key map (kbd "SPC") #'doom/leader)
    map)
  "Keymap of the sysmon buffer.
It does not inherit from `vterm-mode-map', so no key ever reaches btop.")

(defun anthe-sysmon--sentinel (process event)
  "Pass EVENT to `vterm--sentinel' only when PROCESS has really exited.
`vterm--sentinel' kills the buffer on any event, including a stop."
  (when (memq (process-status process) '(exit signal))
    (vterm--sentinel process event)))

(defun anthe-sysmon--resume ()
  "Resume btop if it is paused."
  (when-let* ((process (get-buffer-process anthe-sysmon-buffer-name))
              ((process-get process 'anthe-sysmon-paused)))
    (process-put process 'anthe-sysmon-paused nil)
    (continue-process process)))

(define-derived-mode anthe-sysmon-mode vterm-mode "Sysmon"
  "Major mode for the read-only btop buffer."
  (use-local-map anthe-sysmon-read-only-map)
  (set-process-sentinel vterm--process #'anthe-sysmon--sentinel)
  (set-process-query-on-exit-flag vterm--process nil)
  ;; A stopped process would not act on the hangup sent by `kill-buffer'.
  (add-hook 'kill-buffer-hook #'anthe-sysmon--resume nil t)
  ;; When the buffer is in several workspaces, persp-mode would refuse to kill it
  ;; and only remove it from the current one, leaving btop running.
  (setq-local kill-buffer-query-functions nil)
  (setq-local left-fringe-width 0
              right-fringe-width 0))

(with-eval-after-load 'evil
  (evil-set-initial-state 'anthe-sysmon-mode 'emacs))

(defun anthe-sysmon--buffer ()
  "Return the sysmon buffer, starting btop if needed."
  (or (get-buffer anthe-sysmon-buffer-name)
      (let ((config (expand-file-name "sysmon-btop.conf" doom-cache-dir)))
        (unless (executable-find "btop")
          (user-error "Sysmon: btop is not installed"))
        (write-region anthe-sysmon-btop-config nil config nil 'silent)
        (with-current-buffer (get-buffer-create anthe-sysmon-buffer-name)
          (setq default-directory "~/")
          (let ((vterm-shell (concat "btop -c " (shell-quote-argument config))))
            (anthe-sysmon-mode))
          (current-buffer)))))

(defun anthe-sysmon--sync-pause ()
  "Pause btop while its buffer is not displayed, and resume it when it is."
  (when-let* ((buffer (get-buffer anthe-sysmon-buffer-name))
              (process (get-buffer-process buffer)))
    (let ((visible (get-buffer-window buffer t))
          (paused (process-get process 'anthe-sysmon-paused)))
      (cond ((and visible paused)
             (anthe-sysmon--resume))
            ((not (or visible paused))
             (process-put process 'anthe-sysmon-paused t)
             (stop-process process))))))

(add-hook 'window-state-change-hook #'anthe-sysmon--sync-pause)

(defun anthe-sysmon-show ()
  "Display sysmon in the selected window, or select the window displaying it."
  (interactive)
  (let ((buffer (anthe-sysmon--buffer)))
    (if-let* ((window (get-buffer-window buffer)))
        (select-window window)
      (switch-to-buffer buffer))))

(defun anthe-sysmon-hide ()
  "Bury sysmon, showing the previous buffer of the selected window."
  (interactive)
  (with-current-buffer (window-buffer)
    (bury-buffer)))

(defun anthe-sysmon-quit ()
  "Kill the sysmon buffer and btop with it."
  (interactive)
  (kill-buffer anthe-sysmon-buffer-name))

;;;###autoload
(defun anthe-sysmon-toggle ()
  "Show sysmon, or hide it if the selected window displays it."
  (interactive)
  (if (equal (buffer-name (window-buffer)) anthe-sysmon-buffer-name)
      (anthe-sysmon-hide)
    (anthe-sysmon-show)))

(map! :leader
      :desc "System monitor" "k o m" #'anthe-sysmon-toggle)

(provide 'anthe-sysmon)
;;; anthe-sysmon.el ends here
