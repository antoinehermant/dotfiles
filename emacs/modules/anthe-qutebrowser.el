;;; anthe-qutebrowser.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Maintainer: anthe <anthe@inspiron>
;; Created: May 30, 2026
;; Modified: May 30, 2026
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/anthe/anthe-qutebrowser
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(add-to-list 'load-path "/home/anthe/.config/emacs/.local/other/qutebrowser.el/")

;; Define a simple function to send commands to qutebrowser via commandline
;; This doesn't depend on any qutebrowser.el internals
(defun anthe/qutebrowser-send-command (command)
  "Send COMMAND to qutebrowser via commandline."
  (interactive "MCommand: ")
  (start-process "qutebrowser-cmd" nil "qutebrowser" ":" command))

(require 'qutebrowser)
(require 'qutebrowser-consult)
(require 'qutebrowser-evil)
(require 'qutebrowser-doom-modeline)

;; Add key bindings to qutebrowser-exwm-mode-map
;; Use our simple command sender to avoid dependency issues
;; We use C-c z prefix to avoid conflicts with global bindings like text-scale-increase
;; (define-key qutebrowser-exwm-mode-map (kbd "C-c z i") 
;;             (lambda () (interactive) (anthe/qutebrowser-send-command "zoom-in") (message "Zoom in")))
;; (define-key qutebrowser-exwm-mode-map (kbd "C-c z o") 
;;             (lambda () (interactive) (anthe/qutebrowser-send-command "zoom-out") (message "Zoom out")))

;; To override the global C-= binding, we need to set it in the local keymap
;; We do this by advising the qutebrowser-exwm-mode function
;; (defun anthe/qutebrowser-exwm-mode-advice (orig-fun &rest args)
;;   "Advice to add local key bindings for zoom when qutebrowser-exwm-mode is enabled."
;;   (apply orig-fun args)
;;   (when qutebrowser-exwm-mode
;;     (local-set-key (kbd "C-=") 
;;                    (lambda () (interactive) (anthe/qutebrowser-send-command "zoom-in") (message "Zoom in")))
;;     (local-set-key (kbd "C-+") 
;;                    (lambda () (interactive) (anthe/qutebrowser-send-command "zoom-in") (message "Zoom in")))
;;     (local-set-key (kbd "C--") 
;;                    (lambda () (interactive) (anthe/qutebrowser-send-command "zoom-out") (message "Zoom out")))))

;; (advice-add 'qutebrowser-exwm-mode :after-while #'anthe/qutebrowser-exwm-mode-advice)

;; (defun qutebrowser-commandline-send (commands &optional start)
;;   "Send COMMANDS to Qutebrowser via commandline."
;;   (let ((running (qutebrowser-is-running-p)))
;;     (if (or start running)
;;         (progn
;;           (unless running
;;             (message "Starting new Qutebrowser instance."))
;;           (apply #'start-process "qutebrowser" nil
;;                  "/home/anthe/software/qutebrowser/.venv/bin/python3" "-m" "qutebrowser" commands))
;;       (message "Qutebrowser is not running, not going to send commands via commandline."))))

(defun anthe-switch-to-qutebrowser-buffers (&optional sources)
  (interactive)
  (let ((selected (consult--multi (or sources consult-buffer-sources)
                                  :require-match
                                  (confirm-nonexistent-file-or-buffer)
                                  :prompt "Switch to Qute: "
                                  :initial "qutebrowser^ "
                                  :history 'consult--buffer-history
                                  :sort nil)))
    ;; For non-matching candidates, fall back to buffer creation.
    (unless (plist-get (cdr selected) :match)
      (consult--buffer-action (car selected)))))

(global-qutebrowser-exwm-mode)
(global-qutebrowser-doom-modeline-mode)
(qutebrowser-theme-export-mode)

;; (map! :leader
;;       (:prefix ("k q" . "qutebrowser")
;;        :desc "Qutebrowser launcher" "l" #'qutebrowser-launcher
;;        :desc "Qutebrowser switch (tabs and bookmarks)" "s" #'anthe-switch-to-qutebrowser-buffers))

(map! :leader
      (:prefix ("k q" . "qutebrowser")
       :desc "Qutebrowser launcher" "o" #'qutebrowser-launcher
       :desc "Qutebrowser launcher" "O" #'qutebrowser-launcher-window        
       :desc "Qutebrowser switch (tabs and bookmarks)" "b" #'anthe-switch-to-qutebrowser-buffers))

(custom-set-faces!
  '(vertico-group-title :foreground "#51afef")
  '(completions-annotations :foreground "#d2a6ff" :slant italic)
  )

(provide 'anthe-qutebrowser)
;;; anthe-qutebrowser.el ends here
