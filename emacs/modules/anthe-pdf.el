;;; anthe-pdf.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Maintainer: anthe <anthe@inspiron>
;; Created: February 15, 2026
;; Modified: February 15, 2026
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/anthe/anthe-pdf
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:


(use-package pdf-tools
  :defer t
  ;; :commands (pdf-view-mode pdf-tools-install)
  :mode ("\\.pdf\\'" . pdf-view-mode)
  :config
  (pdf-tools-install)
  (setq-default pdf-view-display-size 'fit-height)
  :hook (pdf-view-mode . pdf-view-midnight-minor-mode))

(custom-set-faces!
 '(pdf-isearch-match :background "#ffcb6b" :foreground "#303030"))

(provide 'anthe-pdf)
;;; anthe-pdf.el ends here
