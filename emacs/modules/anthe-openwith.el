;;; anthe-openwith.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Maintainer: anthe <anthe@inspiron>
;; Created: February 16, 2026
;; Modified: February 16, 2026
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/anthe/anthe-openwith
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(add-to-list 'load-path "~/.config/emacs/.local/elpa/openwith-20120531.2136/")
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


(provide 'anthe-openwith)
;;; anthe-openwith.el ends here
