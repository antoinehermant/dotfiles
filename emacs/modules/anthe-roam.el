;;; anthe-roam.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Maintainer: anthe <anthe@inspiron>
;; Created: February 15, 2026
;; Modified: February 15, 2026
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/anthe/anthe-roam
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(add-to-list 'load-path "~/.config/emacs/.local/straight/repos/org-roam/")
(add-to-list 'load-path "~/.config/emacs/.local/straight/repos/emacsql")
(add-to-list 'load-path "~/.config/emacs/.local/straight/repos/citar-org-roam/")
(use-package org-roam
  :custom
  (org-roam-directory (file-truename "~/org/roam/"))
  :config
  (org-roam-db-autosync-enable))

(use-package citar-org-roam
  :after (citar org-roam)
  :config (citar-org-roam-mode))


(add-to-list 'load-path "~/.config/emacs/.local/consult-org-roam/")
(use-package consult-org-roam
   :after org-roam
   :init
   (require 'consult-org-roam)
   ;; Activate the minor mode
   (consult-org-roam-mode 1)
   :custom
   ;; Use `ripgrep' for searching with `consult-org-roam-search'
   (consult-org-roam-grep-func #'consult-ripgrep)
   ;; Configure a custom narrow key for `consult-buffer'
   (consult-org-roam-buffer-narrow-key ?r)
   ;; Display org-roam buffers right after non-org-roam buffers
   ;; in consult-buffer (and not down at the bottom)
   (consult-org-roam-buffer-after-buffers t)
   :config
   ;; Eventually suppress previewing for certain functions
   (consult-customize
    consult-org-roam-forward-links
    :preview-key "M-.")
   :bind
   ;; Define some convenient keybindings as an addition
   ;; ("C-c n e" . consult-org-roam-file-find)
   ;; ("C-c n b" . consult-org-roam-backlinks)
   ;; ("C-c n B" . consult-org-roam-backlinks-recursive)
   ;; ("C-c n l" . consult-org-roam-forward-links)
   ;; ("C-c n r" . consult-org-roam-search)
   )

;; Org roam keybinding
(map! :leader
      :desc "Sync database" "n r S" #'org-roam-db-sync
      :desc "consult org roam" "n r s" #'consult-org-roam-search)


(provide 'anthe-roam)
;;; anthe-roam.el ends here
