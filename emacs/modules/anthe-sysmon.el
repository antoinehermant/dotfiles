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
update_ms = 1000
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

(defvar anthe-sysmon--last-cpu nil
  "The CPU time of btop and the time it was last seen to change.")

(defun anthe-sysmon--resume ()
  "Resume btop if it is paused."
  (when-let* ((process (get-buffer-process anthe-sysmon-buffer-name))
              ((process-get process 'anthe-sysmon-paused)))
    (process-put process 'anthe-sysmon-paused nil)
    ;; The watchdog counts again: a paused btop uses no CPU
    (setq anthe-sysmon--last-cpu nil)
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
             ;; Not `stop-process': btop handles its SIGTSTP by restarting its
             ;; collecting thread, which sometimes deadlocks on resume, leaving
             ;; the clock running and the graphs frozen.  SIGSTOP freezes it as is.
             (signal-process process 'SIGSTOP))))))

(add-hook 'window-state-change-hook #'anthe-sysmon--sync-pause)

;; A watchdog for a btop that stops updating while displayed: it resumes a
;; btop stopped without being paused here, and restarts one that no longer
;; collects anything (its collecting thread using no CPU for a while)
(defvar anthe-sysmon--watchdog-timer nil)

(defun anthe-sysmon--stat (file)
  "Return the fields of FILE, a /proc stat file, after the name, or nil."
  (with-temp-buffer
    (when (ignore-errors (insert-file-contents file) t)
      ;; The name, in parentheses, may hold spaces: the fields come after it
      (and (re-search-forward ") " nil t)
           (split-string (buffer-substring (point) (point-max)))))))

(defun anthe-sysmon--process-state (process)
  "Return the state letter of PROCESS in /proc, such as R, S or T (stopped)."
  (car (anthe-sysmon--stat (format "/proc/%d/stat" (process-id process)))))

(defun anthe-sysmon--collector-time (process)
  "Return the CPU time of the threads of PROCESS but the main one, in ticks.
The main thread of btop only draws the clock: the others collect the data."
  (let* ((pid (process-id process))
         (dir (format "/proc/%d/task/" pid)))
    (apply #'+ (mapcar (lambda (tid)
                         (let ((fields (anthe-sysmon--stat (concat dir tid "/stat"))))
                           ;; utime and stime, fields 14 and 15 counting the id and name
                           (+ (string-to-number (or (nth 11 fields) "0"))
                              (string-to-number (or (nth 12 fields) "0")))))
                       (remove (number-to-string pid)
                               (ignore-errors (directory-files dir nil "\\`[0-9]+\\'")))))))

(defun anthe-sysmon-restart ()
  "Start btop again, in the windows displaying sysmon."
  (interactive)
  (let ((windows (get-buffer-window-list anthe-sysmon-buffer-name nil t)))
    ;; A stuck btop may not exit on the hangup of `kill-buffer'
    (when-let* ((process (get-buffer-process anthe-sysmon-buffer-name)))
      (signal-process process 'SIGKILL))
    (kill-buffer anthe-sysmon-buffer-name)
    (setq anthe-sysmon--last-cpu nil)
    (let ((buffer (anthe-sysmon--buffer)))
      (dolist (window windows)
        (set-window-buffer window buffer)))))

(defun anthe-sysmon--watchdog ()
  "Resume btop if it stopped while displayed, and restart it if it is stuck."
  (when-let* ((buffer (get-buffer anthe-sysmon-buffer-name))
              (process (get-buffer-process buffer))
              ((get-buffer-window buffer t))
              ((not (process-get process 'anthe-sysmon-paused))))
    (if (equal (anthe-sysmon--process-state process) "T")
        (progn
          (message "Sysmon: btop was stopped while displayed, resuming it")
          (setq anthe-sysmon--last-cpu nil)
          (continue-process process))
      (let ((cpu (anthe-sysmon--collector-time process)))
        (cond ((not (eql cpu (car anthe-sysmon--last-cpu)))
               (setq anthe-sysmon--last-cpu (cons cpu (float-time))))
              ((> (- (float-time) (cdr anthe-sysmon--last-cpu)) 20)
               (message "Sysmon: btop stopped collecting, restarting it")
               (anthe-sysmon-restart)))))))

(unless (timerp anthe-sysmon--watchdog-timer)
  (setq anthe-sysmon--watchdog-timer (run-with-timer 10 10 #'anthe-sysmon--watchdog)))

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
