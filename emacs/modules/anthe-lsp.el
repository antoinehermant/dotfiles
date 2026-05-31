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

(require 'lsp-mode)

(defun anthe-lsp-mode-setup ()
  (setq lsp-headerline-breadcrumb-segments '(path-up-to-project file symbols))
  (lsp-headerline-breadcrumb-mode))

(use-package! lsp-mode
  :commands (lsp lsp-deferred)
  :config
  (lsp-enable-which-key-integration t)
  (setq lsp-headerline-breadcrumb-segments '(path-up-to-project file symbols))
  (lsp-headerline-breadcrumb-mode 1)
  (setq lsp-headerline-breadcrumb-enable t))

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

(use-package! company
  :init
  (global-company-mode)
  :hook (lsp-mode . company-mode)
  :bind (:map company-active-map
              ("<tab>" . 'company-complete-selection)
              ("C-l" . 'company-complete-selection)
              ("C-j" . 'company-select-next)
              ("C-k" . 'company-select-previous)
              ("C-h" . 'company-abort))
  :custom
  (company-minimum-prefix-length 1)
  (company-tooltip-align-annotations t)
  (company-require-match 'never)
  (company-idle-delay 0)
  (company-tooltip-idle-delay 0)
  (company-show-numbers t))

(add-to-list '+lsp-company-backends 'company-files t)

(add-to-list 'load-path "~/.config/emacs/.local/other/cape/")
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
  (define-key company-active-map (kbd "<return>") nil)
  (define-key company-active-map (kbd "RET") nil))

(provide 'anthe-lsp)
;;; anthe-lsp.el ends here
