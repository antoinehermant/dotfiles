;;; anthe-comp.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Maintainer: anthe <anthe@inspiron>
;; Created: February 15, 2026
;; Modified: February 15, 2026
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/anthe/anthe-comp
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:


(use-package company
  :hook (emacs-startup . global-company-mode)
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
  (company-idle-delay 0.5)
  (company-show-numbers t))

(with-eval-after-load 'company
  (define-key company-active-map (kbd "<return>") nil)
  (define-key company-active-map (kbd "RET") nil))


;; disable corfu at start to avoid overlapping with company for example FIXME
(setq! global-corfu-mode 'nil)
(global-corfu-mode -1)
(yas-global-mode -1)



(use-package yasnippet
  :hook (python-mode . yas-minor-mode))

(use-package flycheck
  :hook (python-mode . flycheck-mode))

(provide 'anthe-comp)
;;; anthe-comp.el ends here
