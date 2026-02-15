;;; anthe-lsp.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Maintainer: anthe <anthe@inspiron>
;; Created: February 15, 2026
;; Modified: February 15, 2026
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/anthe/anthe-lsp
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:



;; (use-package lsp-mode
;;   :ensure t
;;   :hook ((python-mode . lsp-deferred)
;;          (lsp-mode . lsp-enable-which-key-integration))
;;   :commands lsp)
;; Dape configs
;;


(use-package eglot
  :config
  (add-to-list 'eglot-server-programs '(python-mode . ("pyright-langserver" "--stdio"))))
(add-hook 'python-mode-hook 'eglot-ensure)

(provide 'anthe-lsp)
;;; anthe-lsp.el ends here
