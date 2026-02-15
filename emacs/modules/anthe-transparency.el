;;; anthe-transparency.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Maintainer: anthe <anthe@inspiron>
;; Created: February 15, 2026
;; Modified: February 15, 2026
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/anthe/anthe-transparency
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:


(defvar frame-transparency-toggle-state nil
  "State of frame transparency toggle.")

;; Defining a variable for transparency so it can depend on certain conditions such as which theme loaded or which system we are on
;; (defvar my-transparency-value 90
;;   "Defines a variable for transparency")

(defun toggle-frame-transparency ()
  "Toggle frame transparency between 100% and 95%."
  (interactive)
  (if frame-transparency-toggle-state
      (progn
        (set-frame-parameter nil 'alpha-background 100)
        (add-to-list 'default-frame-alist '(alpha-background . 100))
        (setq frame-transparency-toggle-state nil))
    (progn
      (set-frame-parameter nil 'alpha-background 85)
      (add-to-list 'default-frame-alist '(alpha-background . 85))
      (setq frame-transparency-toggle-state t)))
  (message "Frame transparency toggled to %s%%"
           (if frame-transparency-toggle-state 85 100)))


(set-frame-parameter nil 'alpha-background 85)

(defvar frame-transparency-toggle-state-100 nil
  "State of frame transparency toggle.")

(defun toggle-frame-transparency-100 ()
  "Toggle frame transparency between 100% and 95%."
  (interactive)
  (if frame-transparency-toggle-state-100
      (progn
        (set-frame-parameter nil 'alpha-background 100)
        (add-to-list 'default-frame-alist '(alpha-background . 100))
        (setq frame-transparency-toggle-state-100 nil))
    (progn
      (set-frame-parameter nil 'alpha-background 10)
      (add-to-list 'default-frame-alist '(alpha-background . 10))
      (setq frame-transparency-toggle-state-100 t)))
  (message "Frame transparency toggled to %s%%"
           (if frame-transparency-toggle-state-100 10 100)))

(map! :leader
      :desc "Toggle transparency" "t t" #'toggle-frame-transparency
      :desc "Toggle 100% transparency" "t T" #'toggle-frame-transparency-100
      )

(provide 'anthe-transparency)
;;; anthe-transparency.el ends here
