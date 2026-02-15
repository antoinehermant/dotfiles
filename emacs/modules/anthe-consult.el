;;; anthe-consult.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Maintainer: anthe <anthe@inspiron>
;; Created: February 15, 2026
;; Modified: February 15, 2026
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/anthe/anthe-consult
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(use-package consult
  :hook (completion-list-mode . consult-preview-at-point-mode)
  :init

  ;; Tweak the register preview for `consult-register-load',
  ;; `consult-register-store' and the built-in commands.  This improves the
  ;; register formatting, adds thin separator lines, register sorting and hides
  ;; the window mode line.
  (advice-add #'register-preview :override #'consult-register-window)
  (setq register-preview-delay 0.5)

  ;; Use Consult to select xref locations with preview
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)

  :config

  ;; Optionally configure preview. The default value
  ;; is 'any, such that any key triggers the preview.
  ;; (setq consult-preview-key 'any)
  ;; (setq consult-preview-key "M-.")
  ;; (setq consult-preview-key '("S-<down>" "S-<up>"))
  ;; For some commands and buffer sources it is useful to configure the
  ;; :preview-key on a per-command basis using the `consult-customize' macro.
  (consult-customize
   consult-theme :preview-key '(:debounce 0.2 any)
   consult-ripgrep consult-git-grep consult-grep consult-man
   consult-bookmark consult-recent-file consult-xref consult-find
   consult--source-bookmark consult--source-file-register
   consult--source-recent-file consult--source-project-recent-file
   ;; :preview-key "M-."
   :preview-key '(:debounce 0.4 any)))

(setq consult-ripgrep-args
        "rg --null --line-buffered --color=never --max-columns=1000 --path-separator / --smart-case --no-heading --with-filename --line-number --search-zip --hidden")

(setq consult-preview-excluded-files
      '("\\.nc\\'"
        "\\`/[^/|:]+:"
        "\\.gpg\\'"))

(add-to-list 'load-path "~/.config/emacs/.local/elpa/consult-projectile/")
(require 'consult-projectile)

;; (setq read-file-name-function #'consult-find-file-with-preview)

;; (defun consult-find-file-with-preview (prompt &optional dir default mustmatch initial pred)
;;   "Like `find-file', but with consult preview and live-editable full path."
;;   (interactive)
;;   (let ((default-directory (or dir default-directory)))
;;     (consult--read
;;      #'read-file-name-internal
;;      :state (consult--file-preview)
;;      :prompt prompt
;;      :initial (abbreviate-file-name default-directory)  ; Start with full path in the input field
;;      :require-match mustmatch
;;      :history 'file-name-history
;;      :category 'file
;;      :predicate pred)))

(map! :leader
        :desc "consult-ripgrep" "s p" #'consult-ripgrep
        :desc "consult-ripgrep" "/" #'consult-ripgrep
        :desc "consult-find" "r f" #'consult-find
      )

(provide 'anthe-consult)
;;; anthe-consult.el ends here
