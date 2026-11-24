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

;; lsp-mode loads with the first buffer that starts it (half a second)

(defun anthe-lsp-mode-setup ()
  (setq lsp-headerline-breadcrumb-segments '(path-up-to-project file symbols))
  (lsp-headerline-breadcrumb-mode))

(use-package! lsp-mode
  :commands (lsp lsp-deferred)
  :config
  ;; (lsp-enable-which-key-integration nil)
  (setq lsp-headerline-breadcrumb-segments '(path-up-to-project file symbols))
  (lsp-headerline-breadcrumb-mode 1)
  (setq lsp-headerline-breadcrumb-enable t))

(setq lsp-disabled-clients '(ruff ty))

;; (use-package eglot
;;   :config
;;   (add-hook 'python-mode-hook 'eglot-ensure)
;;     (setq eglot-autoshutdown t)
;;     (setq eglot-send-changes-idle-time 0)
;;     (setq eglot-stay-out-of '(python-mode)))

;; (with-eval-after-load 'python
;;   (set-eglot-client! '(python-mode python-ts-mode) '("ty" "server")))
;;   
;; ((python-mode . eglot-ensure))
;; (add-to-list 'eglot-server-programs '(python-mode . ("ruff-lsp")))
;; (add-to-list 'eglot-server-programs '(python-mode . ("ruff" "server")))
;; (add-to-list 'eglot-server-programs '(python-mode . ("pyright-langserver" "--stdio")))
;; (add-to-list 'eglot-server-programs '(python-mode . ("pylsp")))
;; (add-to-list 'eglot-server-programs '(python-mode . ("basedpyright" "--stdio")))
;; (add-hook 'python-mode-hook 'eglot-ensure)

;; (add-to-list 'warning-suppress-types '(emacs))

;; Company: anthe-company.el
(require 'anthe-company)

;; (add-to-list 'load-path "~/.config/emacs/.local/other/cape/")
(use-package cape
  ;; Bind prefix keymap providing all Cape commands under a mnemonic key.
  ;; Press C-c p ? to for help.
  ;; :bind ("C-c p" . cape-prefix-map) ;; Alternative key: M-<tab>, M-p, M-+
  ;; Alternatively bind Cape commands individually.
  :bind (
         ;; ("C-c p d" . cape-dabbrev)
         ;; ("C-c p h" . cape-history)
         ("C-c C-k" . cape-file))
  ;;        ...)
  :init
  ;; Add to the global default value of `completion-at-point-functions' which is
  ;; used by `completion-at-point'.  The order of the functions matters, the
  ;; first function returning a result wins.  Note that the list of buffer-local
  ;; completion functions takes precedence over the global list.
  ;; (add-hook 'completion-at-point-functions #'cape-dabbrev)
  ;; (add-hook 'completion-at-point-functions #'cape-file)
  ;; (add-hook 'completion-at-point-functions #'cape-elisp-block)
  ;; (add-hook 'completion-at-point-functions #'cape-history)
  ;; ...
  )

;; Désactive flycheck ou flymake si tu utilises le linting via eglot/ruff-lsp
;; (setq flycheck-disabled-checkers '(python-ruff python-flake8 python-pylint))
(with-eval-after-load 'company
  (add-hook 'inferior-python-mode-hook
            (lambda ()
              (setq-local company-backends '(company-capf company-jedi (company-files company-dabbrev))))))

(provide 'anthe-lsp)
;;; anthe-lsp.el ends here
