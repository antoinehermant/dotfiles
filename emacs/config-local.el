;;; config-machine --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2025 anthe
;;
;; Author: anthe
;; Maintainer: anthe
;; Created: February 26, 2025
;; Modified: February 26, 2025
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/anthe/config-machine
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(add-to-list 'load-path "~/.config/emacs/.local/")
(require 'app-launcher)

(add-to-list 'load-path "~/.dotfiles/emacs/")
(require 'config-core)

(add-to-list 'load-path "~/.dotfiles/emacs/modules")
(require 'anthe-bib)
(require 'anthe-citar)
(require 'anthe-control)
(require 'anthe-comp)
(require 'anthe-consult)
(require 'anthe-dap)
(require 'anthe-desktop)
(require 'anthe-evil)
(require 'anthe-file-manager)
(require 'anthe-gptel)
(require 'anthe-latex)
(require 'anthe-lsp)
(require 'anthe-mu4e)
(require 'anthe-org)
(require 'anthe-pdf)
(require 'anthe-popper)
(require 'anthe-python)
(require 'anthe-roam)
(require 'anthe-transparency)
(require 'anthe-vterm)
(require 'anthe-workflow)

(use-package! org-present)
(use-package! org-inline-pdf)

(map! :leader
      :desc "App launcher" "\\" #'app-launcher-run-app)

(setq pyvenv-default-virtual-env-name  "/home/anthe/software/miniconda3/envs/")

(setq org-present-startup-folded t)


(defun ubelix-emacs ()
  (interactive)
  (let ((vterm-buffer (vterm "UBELIX-VTERM")))
    (with-current-buffer vterm-buffer
      (vterm-send-string "ssh ubelix3\n")
      (vterm-send-string "em\n")
      ;; (set-buffer-modified-p nil)
      ;; (bury-buffer) ;; Hide the buffer
      ;; )))
    )))

(provide 'config-local)
;;; config-local.el ends here
