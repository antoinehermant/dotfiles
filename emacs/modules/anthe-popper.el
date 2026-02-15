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

(use-package popper
  :bind (("M-`"   . popper-cycle)
         ("C-M-`" . popper-toggle-type)
         ("C-<down>" . 'shrink-window)
         ("C-<up>" . 'enlarge-window))
  :init
  (setq popper-reference-buffers
        '("^\\*Messages\\*"
          "^Output\\*$"
          "^\\*Async Shell Command\\*"
          "^\\*vterm"
          "^\\*Python"
          "^*compilation"
          help-mode
          compilation-mode))   ; Add closing parenthesis here
  (popper-mode +1)
  (popper-echo-mode +1))                ; For echo area

(setq popper-window-height (floor (* (frame-height) 0.3)))

;; Define global variables to store state
(defvar vterm-popper-original-height nil
  "Stores the original height of the vterm popup window.")
(defvar vterm-popper-expanded nil
  "Boolean flag to track if the vterm popup is expanded.")
(defvar vterm-popper-original-height nil
  "Stores the original height of the vterm popup window.")
(defvar vterm-popper-expanded nil
  "Boolean flag to track if the vterm popup is expanded.")

(defun toggle-vterm-popper-size ()
  "Toggle vterm popup window size between default and 3/4 of the screen height."
  (interactive)
  (let* ((vterm-window (seq-find (lambda (window)
                                   (string-match-p "^\\*vterm" (buffer-name (window-buffer window))))
                                 (window-list)))
         (frame-height (frame-height))
         (expanded-height (floor (* frame-height 0.80))))
    (when vterm-window
      (if vterm-popper-expanded
          (progn
            (window-resize vterm-window
                           (- vterm-popper-original-height (window-height vterm-window)))
            (setq vterm-popper-expanded nil))
        (setq vterm-popper-original-height (window-height vterm-window))
        (window-resize vterm-window
                       (- expanded-height (window-height vterm-window)))
        (setq vterm-popper-expanded t)))))

;; Bind the function to a key
(global-set-key (kbd "C-c `") 'toggle-vterm-popper-size)

(map! :leader
      :desc "popper" "`" #'popper-toggle)

; (setq popper-reference-buffers
;;       (append popper-reference-buffers
;;               '("\\*eshell*\\*$" eshell-mode ;eshell as a popup
;;                 "\\*shell*\\*$"  shell-mode  ;shell as a popup
;;                 "\\*term*\\*$"   term-mode   ;term as a popup
;;                 "\\*vterm*\\*$"  vterm-mode  ;vterm as a popup
;;                 )))

(provide 'anthe-popper)
;;; anthe-popper.el ends here
