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
(require 'qutebrowser)
(require 'qutebrowser-consult)
(require 'qutebrowser-evil)
(require 'qutebrowser-doom-modeline)

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
