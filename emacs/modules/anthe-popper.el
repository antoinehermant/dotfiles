;;; anthe-popper.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Maintainer: anthe <anthe@inspiron>
;; Created: February 15, 2026
;; Modified: February 15, 2026
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/anthe/anthe-popper
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(add-to-list 'load-path "~/.config/emacs/.local/straight/repos/popper/")
(use-package! popper
  :bind (("M-`"   . popper-cycle)
         ("C-M-`" . popper-toggle-type)
         ("C-<down>" . 'shrink-window)
         ("C-<up>" . 'enlarge-window))
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
          compilation-mode))   ; Add closing parenthesis here
  (popper-mode +1))
;; (popper-echo-mode +1))                ; For echo area

;; (setq popper-group-function #'popper-group-by-project) ; project.el projects
(setq popper-group-function #'popper-group-by-projectile) ; projectile projects
;; (setq popper-group-function #'popper-group-by-directory) ; group by project.el
;;                                         ; project root, with
;;                                         ; fall back to
;;                                         ; default-directory
;; (setq popper-group-function #'popper-group-by-perspective) ; group by perspective

(map! :leader
      :desc "popper" "`" #'popper-toggle)

(setq popper-reference-buffers
      (append popper-reference-buffers
              '("\\*eshell*\\*$" eshell-mode ;eshell as a popup
                ;; "\\*shell*\\*$"  shell-mode  ;shell as a popup
                ;; "\\*term*\\*$"   term-mode   ;term as a popup
                "\\*vterm*\\*$"  vterm-mode  ;vterm as a popup
                )))

(provide 'anthe-popper)
;;; anthe-popper.el ends here
