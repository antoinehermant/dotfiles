;;; anthe-evil.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Maintainer: anthe <anthe@inspiron>
;; Created: February 15, 2026
;; Modified: February 15, 2026
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/anthe/anthe-evil
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(define-key evil-normal-state-map (kbd "C-d")
  (lambda () (interactive) (evil-scroll-down 0.5) (evil-scroll-line-to-center nil)))
(define-key evil-normal-state-map (kbd "C-u")
  (lambda () (interactive) (evil-scroll-up 0.5) (evil-scroll-line-to-center nil)))

(map! :leader
        :desc "Evil v split and follow" "w v" #'+evil/window-vsplit-and-follow
        :desc "Evil h split and follow" "w s" #'+evil/window-split-and-follow)
;; (define-key evil-normal-state-map "j" 'evil-next-visual-line)
;; (define-key evil-normal-state-map "k" 'evil-previous-visual-line)

(provide 'anthe-evil)
;;; anthe-evil.el ends here
