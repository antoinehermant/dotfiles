;;; anthe-python.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Maintainer: anthe <anthe@inspiron>
;; Created: February 15, 2026
;; Modified: February 15, 2026
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/anthe/anthe-python
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(use-package! elpy)
(use-package! jupyter)
(use-package! python-mode)
(use-package! virtualenv)
(use-package! pipenv)

(require 'python)

(use-package python
  :custom
  (python-indent-offset 4)
  (python-shell-interpreter "python3"))

(defun python-shell-send-region-or-current-line ()
  "Send the current region or line to the Python shell and execute."
  (interactive)
  (let* ((region-active (region-active-p))
         (start (if (region-active-p)
                   (region-beginning)
                 (line-beginning-position)))
        (end (if (region-active-p)
                 (region-end)
               (line-end-position))))
    (python-shell-send-region start end)
    ;; (deactivate-mark)  ; Quit visual mode
    (unless region-active
      (forward-line 1))
    (back-to-indentation)))

(use-package pyvenv
  :config
  (pyvenv-mode 1))

(use-package! jupyter)
(setq jupyter-repl-echo-eval-p t)

(add-hook 'python-mode-hook 'code-cells-mode-maybe)

(add-hook 'python-mode-hook 'flymake-mode)

(defun my-run-cell-and-forward-cell ()
  "Run current cell in shell buffer, move to next cell and center."
  (interactive)
  (code-cells-eval)
  (code-cells-forward-cell)
  (evil-scroll-line-to-center nil))

(defun my-python-mode-setup ()
  "Setup keybindings for Python mode."
  (map! :map python-mode-map
        :leader
        :desc "Run region or line in Python shell" "r j" #'python-shell-send-region-or-current-line
        :desc "Run current cell in Python shell" "r [" #'my-run-cell-and-forward-cell
        :desc "Activate pyvenv" "r a" #'pyvenv-activate
        :desc "Run python" "r p" #'run-python
        :desc "Run python" "r r" #'python-shell-restart
        :desc "Forward to next cell" "]" #'code-cells-forward-cell
        :desc "Backward to previous cell" "[" #'code-cells-backward-cell
        :desc "Jupyter run REPL" "r J" #'jupyter-run-repl))

(add-hook 'python-mode-hook #'my-python-mode-setup)

(add-to-list 'auto-mode-alist '("\\.py\\'" . python-mode))

;; Keybindings
(map! :leader
      :desc "Forward to next cell" "]" #'code-cells-forward-cell
      :desc "Backward to previous cell" "[" #'code-cells-backward-cell
      :desc "Activate pyvenv" "r a" #'pyvenv-activate
      :desc "Run python" "r p" #'run-python
      :desc "Jupyter run REPL" "r J" #'jupyter-run-repl)

(provide 'anthe-python)
;;; anthe-python.el ends here
