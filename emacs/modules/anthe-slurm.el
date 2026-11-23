;;; anthe-slurm.el --- Slurm from Emacs, on the HPC -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  The jobs of UBELIX from Emacs (config-hpc.el loads it):
;;  - `SPC k q b': submit the file visited (sbatch)
;;  - `SPC k q q', `SPC k q g': my queue, the group's (squeue), in a window
;;    reloaded every second while it shows (`r' toggles it), commands from
;;    ~/.squeue_commands.json ({"q": "squeue -u $USER", "g": ...})
;;
;;; Code:

(defun sbatch-buffer ()
  (interactive)
  (save-buffer)
  (let ((file (buffer-file-name)))
    (when file
      (message "%s" (shell-command-to-string (concat "sbatch " (shell-quote-argument file)))))))


(defvar-local slurm-queue-timer nil
  "Timer for auto-reloading slurm queue.")

(defvar slurm-queue-last-update 0
  "Timestamp of last update.")

(define-derived-mode slurm-queue-mode special-mode "SlurmQueue"
  "Major mode for displaying slurm queue."
  (setq buffer-undo-list t)
  (setq buffer-offer-save nil)
  (setq buffer-read-only t)
  (local-set-key (kbd "q") 'quit-window)
  (local-set-key (kbd "r") 'slurm-queue-toggle-reload)
  (evil-local-set-key 'normal (kbd "r") 'slurm-queue-toggle-reload)
  (add-hook 'kill-buffer-hook #'slurm-queue-stop-timer nil t)
  (setq slurm-queue-timer (run-at-time nil 1 'slurm-queue-tick)))

(defun slurm-queue-stop-timer ()
  "Stop the auto-reload timer of the current buffer."
  (when slurm-queue-timer
    (cancel-timer slurm-queue-timer)
    (setq slurm-queue-timer nil)))

(defun slurm-queue-tick ()
  "Reload the queue, or stop the timer if no window displays it anymore."
  (when-let ((buf (get-buffer "*slurm-squeue*")))
    (if (get-buffer-window buf t)
        (squeue-reload)
      (with-current-buffer buf
        (slurm-queue-stop-timer)))))

(defun slurm-queue-toggle-reload ()
  "Toggle auto-reload of slurm queue."
  (interactive)
  (if slurm-queue-timer
      (progn
        (slurm-queue-stop-timer)
        (message "Slurm queue auto-reload disabled"))
    (progn
      (setq slurm-queue-timer (run-at-time nil 1 'slurm-queue-tick))
      (message "Slurm queue auto-reload enabled (1s)"))))

(defun squeue-reload ()
  (interactive)
  (when (and (buffer-live-p (get-buffer "*slurm-squeue*"))
             (> (float-time) (+ slurm-queue-last-update 1))) ; 5s cooldown
    (setq slurm-queue-last-update (float-time))
    (with-current-buffer "*slurm-squeue*"
      (let ((inhibit-read-only t)
            (command (or my-squeue-command "squeue -u $USER")))
        (erase-buffer)
        (insert (shell-command-to-string command))
        (goto-char (point-min))))))


(defun squeue (command)
  (interactive)
  (let ((buf-name "*slurm-squeue*"))
    (if-let ((window (get-buffer-window buf-name)))
        ;; Window exists: close it and stop timer
        (progn
          (with-current-buffer buf-name
            (slurm-queue-stop-timer))
          (quit-window nil window))
      ;; Window doesn't exist: open it
      (let ((existing-buf (get-buffer buf-name)))
        (if existing-buf
            ;; Buffer exists but window closed: update it, display and restart timer
            (progn
              (with-current-buffer existing-buf
                (setq-local my-squeue-command command)
                (setq slurm-queue-last-update 0)
                (squeue-reload)
                (unless slurm-queue-timer
                  (setq slurm-queue-timer (run-at-time nil 1 'slurm-queue-tick))))
              (display-buffer existing-buf))
          ;; Buffer doesn't exist: create fresh
          (let ((new-buf (get-buffer-create buf-name)))
            (with-current-buffer new-buf
              (slurm-queue-mode)
              (setq-local my-squeue-command command)
              (squeue-reload))
            (display-buffer new-buf)))))))

(defvar my-squeue-commands nil
  "A list of squeue commands")

(defun load-squeue-commands (file)
  (interactive)
  (let ((json-data (with-temp-buffer
                     (insert-file-contents file)
                     (goto-char (point-min))
                     (json-read))))
    (setq my-squeue-commands json-data)))

(when (file-exists-p "~/.squeue_commands.json")
  (load-squeue-commands "~/.squeue_commands.json"))

(map! :leader
      (:prefix ("k q" . "slurm")
       :desc "Submit this file (sbatch)" "b" #'sbatch-buffer
       :desc "Display state of me squeue" "q" (lambda () (interactive) (squeue (alist-get 'q my-squeue-commands)))
       :desc "Display state of group queue" "g" (lambda () (interactive) (squeue (alist-get 'g my-squeue-commands)))))

(defun slurm-squeue-window-height (buffer)
  "Return window height for slurm-squeue buffer, capped at 1/3 of frame."
  (with-current-buffer buffer
    (min (1+ (count-lines (point-min) (point-max)))
         (floor (* (frame-height) 0.25)))))

(add-to-list 'display-buffer-alist
             '("\\*slurm-squeue\\*"
               (display-buffer-below-selected)
               (window-height . slurm-squeue-window-height)))

(with-eval-after-load 'popper
  (add-to-list 'popper-reference-buffers "\\*slurm-squeue\\*"))

(provide 'anthe-slurm)
;;; anthe-slurm.el ends here
