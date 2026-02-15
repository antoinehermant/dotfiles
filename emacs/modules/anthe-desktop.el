;;; anthe-desktop.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Maintainer: anthe <anthe@inspiron>
;; Created: February 15, 2026
;; Modified: February 15, 2026
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/anthe/anthe-desktop
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(use-package! disable-mouse
   :config
   ;; (global-disable-mouse-mode t)
   )
;; more elaborate than disable-mouse, like it handles evil better
(use-package! inhibit-mouse
  :config
  ;; (inhibit-mouse-mode)
  )

(use-package! openwith
  :config
  (setq openwith-associations
        `(,(list (openwith-make-extension-regexp '("nc"))
                 "ncview"
                 '(file))
          ,(list (openwith-make-extension-regexp '("mp4"))
                 "mpv"
                 '(file))
          ,(list (openwith-make-extension-regexp '("WAV"))
                 "vlc"
                 '(file))
          ,(list (openwith-make-extension-regexp '("ods"))
                 "libreoffice --calc"
                 '(file))))
  (openwith-mode t))

(defun my-open-current-buffer-externally ()
  "Open current buffer's file with appropriate application."
  (interactive)
  (when-let ((file (buffer-file-name)))
    (cond
     ((string-match "\\.pdf\\'" file)
      (start-process "" nil "evince" file))
     ((string-match "\\.png\\'" file)
      (start-process "" nil "eog" file))
     (t
      (start-process "" nil "xdg-open" file)))))

(map! :leader
      :desc "Open visited file externally" "o d" #'my-open-current-buffer-externally)


;; NOTE: forgot what this does
(setq inhibit-x-resources t)
(setq-default inhibit-redisplay t)
(add-hook 'window-setup-hook
          (lambda ()
            (setq-default inhibit-redisplay nil)
            (redisplay))
          100)

(add-hook 'server-switch-hook #'raise-frame)
(add-hook 'server-switch-hook (lambda () (select-frame-set-input-focus (selected-frame))))

(add-to-list 'load-path "~/.config/emacs/.local/elpa/vlc-20200328.1143/")
(defun open-mp3-in-vlc ()
  "Open MP3 file in VLC, starting VLC if necessary."
  (interactive)
  (let ((original-buffer (previous-buffer))
        (file (buffer-file-name)))
 ;; (unless (shell-command-to-string "pgrep vlc")
  (kill-buffer (current-buffer))
  (switch-to-buffer original-buffer)
  (vlc-start)
  (sleep-for 1)
  (vlc-add file)))

(add-to-list 'auto-mode-alist '("\\.mp3\\'" . open-mp3-in-vlc))

(provide 'anthe-desktop)
;;; anthe-desktop.el ends here
