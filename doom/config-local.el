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



(provide 'config-machine)

(display-battery-mode)
(display-time-mode)

(dired-async-mode)
;; (use-package conda)
;; (setq conda-anaconda-home "/home/anthe/software/miniconda3")
;; (conda-mode-line-setup)

(setq pyvenv-default-virtual-env-name  "/home/anthe/software/miniconda3/envs/")

(add-to-list 'load-path "~/.config/emacs/.local/")
(require 'app-launcher)
;; --------------------------- Org Mode ---------------------
;
(require 'org)
(defun diary-last-day-of-month (date)
"Return `t` if DATE is the last day of the month."
  (let* ((day (calendar-extract-day date))
         (month (calendar-extract-month date))
         (year (calendar-extract-year date))
         (last-day-of-month
            (calendar-last-day-of-month month year)))
    (= day last-day-of-month)))

(setq org-present-startup-folded t)


(defun my/set-org-agenda-files ()
  (setq org-agenda-files (append (directory-files-recursively "~/org/agenda/" "\\.org$"))))

(use-package org
  :config
  (setq org-directory "~/org/")
  (setq org-agenda-files (append (directory-files-recursively "~/org/agenda/" "\\.org$")))
  ;; (setq org-agenda-files  ("~/org/agenda/" "~/org/phd/"))
  (setq org-agenda-start-with-log-mode t)
  ;; (setq org-todo-keywords
  ;;   '((sequence "TODO(t)" "NEXT(n)" "|" "DONE(d!)")
  ;;     (sequence "BACKLOG(b)" "PLAN(p)" "READY(r)" "ACTIVE(a)" "REVIEW(v)" "WAIT(w@/!)" "HOLD(h)" "|" "COMPLETED(c)" "CANC(k@)")))
 (add-hook 'org-agenda-mode-hook 'my/set-org-agenda-files)

 (require 'org-habit)
 (add-to-list 'org-modules 'org-habit)
 (setq org-habit-graph-column 60)

  (setq org-log-done 'time)
  (setq org-ellipsis " ▾"
      org-hide-emphasis-markers t)

  ;; Set faces for heading levels
  (dolist (face '((org-level-1 . 1.2)
                  (org-level-2 . 1.1)
                  (org-level-3 . 1.05)
                  (org-level-4 . 1.0)
                  (org-level-5 . 1.1)
                  (org-level-6 . 1.1)
                  (org-level-7 . 1.1)
                  (org-level-8 . 1.1)))
    (set-face-attribute (car face) nil :weight 'bold :height (cdr face)))

  (setq org-agenda-custom-commands
   '(("d" "Dashboard"
     ((agenda "Agenda"
              ((org-agenda-start-day "0d")
               (org-agenda-span 7)
               ;; (org-agenda-skip-function
               ;; '(org-agenda-skip-entry-if 'regexp ":habit:"))
               ))
      ;; (tags-todo "+habit" ;; FIXME: I could'nt make move habits to a specfic section because it shows it as regular task, not habit with the tracker
      ;;   ((org-agenda-overriding-header "Habits")))
    (tags-todo "phd/TODO"
               ((org-agenda-overriding-header "PhD Tasks")
                (org-agenda-todo-ignore-deadlines 'far)))
      (tags-todo "+perso-habit" ((org-agenda-overriding-header "Personal Tasks")))
      (tags-todo "+emacs" ((org-agenda-overriding-header "Emacs Project")))))

    ;; ("n" "Next Tasks"
    ;;  ((todo "NEXT"
    ;;     ((org-agenda-overriding-header "Next Tasks")))))

    ("W" "Work Tasks" tags-todo "+work-email")

  ;; ("w" "Work Agenda"
  ;;               ((agenda "PhD Agenda"
  ;;                         ((org-agenda-start-day "0d")
  ;;                       (org-agenda-span 7)
  ;;                       ;;    (org-agenda-skip-function
  ;;                       ;; '(org-agenda-skip-entry-if 'regexp ":perso:\\|:habit:"))))
  ;;                       ))
  ;;      (tags-todo "phd/TODO" ((org-agenda-overriding-header "Active Projects")))
  ;;       (todo "PROJ"
  ;;               ((org-agenda-span 7)
  ;;                (org-agenda-overriding-header "Project Tasks")))
  ;;      (org-agenda-tag-filter-preset '("+phd"))))

        ("w" "PhD Agenda"
        ((tags-todo "+dailies+SCHEDULED<=\"<today>+1\"")
        (agenda "" ((org-agenda-start-day "0d")
                    (org-agenda-span 7)
                (org-agenda-sorting-strategy
                (quote ((agenda time-up priority-down tag-up))))))
        (tags-todo "phd/TODO" ((org-agenda-overriding-header "Active Projects")))
        (tags-todo "phd/PROJ"
                ((org-agenda-span 7)
                 (org-agenda-overriding-header "Project Tasks"))))
        ((org-agenda-tag-filter-preset '("+phd"))))

    ;; Low-effort next actions
    ("e" tags-todo "+TODO=\"NEXT\"+Effort<15&+Effort>0"
     ((org-agenda-overriding-header "Low Effort Tasks")
      (org-agenda-max-todos 20)
      (org-agenda-files org-agenda-files))))))

;; (use-package org-super-agenda)
;; FIXME: testing org super agenda

(setq org-capture-templates
  `(("t" "Tasks / Projects")
    ("tt" "Inbox" entry (file+olp"~/org/agenda/tasks.org" "Inbox")
         "* TODO %?\n  %U\n  %i" :empty-lines 1)
    ("tw" "Work / PhD" entry (file+olp"~/org/agenda/tasks.org" "PhD")
         "* TODO %?\n  %U\n  %i" :empty-lines 1)
    ("tp" "Perso" entry (file+olp"~/org/agenda/tasks.org" "Perso")
         "* TODO %?\n  %U\n  %i" :empty-lines 1)
    ("te" "Emacs" entry (file+olp"~/org/agenda/tasks.org" "Emacs")
         "* TODO %?\n  %U\n  %a\n  %i" :empty-lines 1)
    ("e" "Events" entry (file+olp "~/org/agenda/events.org" "Calendar")
       "* %?\n %i" :empty-line 1)))



(map! :leader
      :desc "Open mu4e" "o m" #'mu4e
      :desc "Agenda Dashbord" "k d" #'(lambda (&optional arg) (interactive "P")(org-agenda arg "d"))
      :desc "Agenda Dashbord" "k w" #'(lambda (&optional arg) (interactive "P")(org-agenda arg "w")))
;; ------------------------------ Org Roam ------------------------------

(use-package org-roam
  :custom
  (org-roam-directory (file-truename "~/roam/"))
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

;; ---------------------------- Org Journal -------------------------
(setq org-journal-date-format "%a, %d.%m.%Y"
      org-journal-file-format "%d.%m.%Y.org")

;; (add-to-list 'load-path  "/home/anthe/.config/emacs/.local/elpa/w3m-20250503.2349/")

(load "~/.config/emacs/.local/dired-x.el")

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

(add-to-list 'load-path "/usr/share/emacs/site-lisp/elpa-src/mu4e-1.12.6/")
(use-package mu4e
  ;; :load-path "~/.config/emacs/.local/mu4e-1.12.6/"
  :defer 10 ; Wait until 20 seconds after startup
  :config

  (mu4e t)
  ;; This is set to 't' to avoid mail syncing issues when using mbsync
  (setq mu4e-change-filenames-when-moving t)
  ;; (setq mu4e-marks-folders-sequentially t)

  ;; Refresh mail using isync every 5 minutes
  (setq mu4e-update-interval (* 5 60))
  (setq mu4e-get-mail-command "mbsync -a")
  (setq mu4e-root-maildir "~/documents/mail/") ;; does not exist anymore?
  (setq mu4e-headers-date-format "%Y/%m/%d")
  ;; (setq mu4e-headers-limit 500)

  ;; (setq +mu4e-gmail-accounts '(("ah74230@gmail.com" . "/Gmail")))
  ;;                              ;; ("antoine.hermant74@gmailcom" . "/Gmail2")))

  ;; (set-email-account! "ah74230@gmail.com"
  ;;       '((mu4e-sent-folder       . "/Gmail/[Gmail]/Sent Mail")
  ;;       (mu4e-trash-folder      . "/Gmail/[Gmail]/Bin")
  ;;       (mu4e-refile-folder     . "/Gmail/[Gmail]/All mail")
  ;;       ;; (smtpmail-smtp-user     . "henrik@lissner.net")
  ;;       ;; (user-mail-address      . "henrik@lissner.net")    ;; only needed for mu < 1.4
  ;;       ;; (mu4e-compose-signature . "---\nHenrik Lissner")
  ;;       )
  ;;       t)

  ;; (set-email-account! "antoine.hermant74@gmail.com"
  ;;       '((mu4e-sent-folder       . "/Gmail2/[Gmail].Sent Mail")
  ;;       (mu4e-trash-folder      . "/Gmail2/[Gmail].Bin")
  ;;       (mu4e-refile-folder     . "/Gmail2/[Gmail].All mail")
  ;;       ;; (smtpmail-smtp-user     . "henrik@lissner.net")
  ;;       ;; (user-mail-address      . "henrik@lissner.net")    ;; only needed for mu < 1.4
  ;;       ;; (mu4e-compose-signature . "---\nHenrik Lissner")
  ;;       )
  ;;       t)
  (setq mu4e-contexts
      (list
         (make-mu4e-context
          :name "Gmail"
          :match-func
            (lambda (msg)
              (when msg
                (string-prefix-p "/Gmail" (mu4e-message-field msg :maildir))))
          :vars '((user-mail-address . "ah74230@gmail.com")
                  (user-full-name    . "Antoine Hermant")
                  (mu4e-drafts-folder  . "/Gmail/[Gmail]/Drafts")
                  (mu4e-sent-folder  . "/Gmail/[Gmail]/Sent Mail")
                  (mu4e-refile-folder  . "/Gmail/[Gmail]/All Mail")
                  (mu4e-trash-folder  . "/Gmail/[Gmail]/Bin")))

         (make-mu4e-context
          :name "Work"
          :match-func
            (lambda (msg)
              (when msg
                (string-prefix-p "/Work" (mu4e-message-field msg :maildir))))
          :vars '((user-mail-address . "antoine.hermant74@gmail.com")
                  (user-full-name    . "Antoine Hermant")
                  (mu4e-drafts-folder  . "/Work/[Gmail]/Drafts")
                  (mu4e-sent-folder  . "/Work/[Gmail]/Sent Mail")
                  (mu4e-refile-folder  . "/Work/[Gmail]/All Mail")
                  (mu4e-trash-folder  . "/Work/[Gmail]/Bin")))

         (make-mu4e-context
          :name "Infomaniak"
          :match-func
            (lambda (msg)
              (when msg
                (string-prefix-p "/Infomaniak" (mu4e-message-field msg :maildir))))
            :vars '((user-mail-address . "antoine.hermant@etik.com")
                  (user-full-name    . "Antoine Hermant")
                  (mu4e-drafts-folder  . "/Infomaniak/Drafts")
                  (mu4e-sent-folder  . "/Infomaniak/Sent")
                  (mu4e-refile-folder  . "/Infomaniak/Inbox")
                  (mu4e-trash-folder  . "/Infomaniak/Trash")))))

  (setq mu4e-bookmarks
        `((:name "Unread messages" :query "flag:unread AND NOT flag:trashed AND NOT tag:\\Trash AND NOT maildir:/Gmail/[Gmail]/Bin AND NOT maildir:/Work/[Gmail]/Bin AND NOT maildir:/Infomaniak/Trash" :key 117)
        (:name "Today's messages" :query "date:today..now AND NOT flag:trashed AND NOT tag:\\Trash AND NOT maildir:/Gmail/[Gmail]/Bin AND NOT maildir:/Work/[Gmail]/Bin AND NOT maildir:/Infomaniak/Trash" :key 116)
        (:name "Last 7 days" :query "date:7d..now" :hide-unread t :key 119)
        (:name "Messages with images" :query "mime:image/*" :key 112)
        (:name "Finances" :query "from:miimosa AND NOT flag:trashed AND NOT tag:\\Trash OR from:linxea AND NOT tag:\\Trash AND NOT flag:trashed OR from:iroko AND NOT flag:trashed OR from:contact@louveinvest.com AND NOT flag:trashed AND NOT tag:\\Trash" :key ?f)
        (:name "Research News" :query "from:cryolist-request AND NOT flag:trashed OR from:scholar AND NOT flag:trashed OR from:researchgate AND NOT flag:trashed" :key ?r)))

  ;; (setq mu4e-maildir-shortcuts
  ;;       '(("/Gmail/Inbox"             . ?i)
  ;;         ("/Gmail/[Gmail]/Sent Mail" . ?s)
  ;;         ("/Gmail/[Gmail]/Bin"     . ?b)
  ;;         ("/Gmail/[Gmail]/Drafts"    . ?d)
  ;;         ("/Gmail/[Gmail]/All Mail"  . ?a)))
  )

;; ----------------------- automation --------------------------------

(defun my-switch-laptop-charger ()
  (interactive)
  (let ((output (shell-command-to-string "/home/anthe/.dotfiles/scripts/switch_devices.py laptop_charger")))
    (message "%s" output)))

(defun my-switch-sound-system ()
  (interactive)
  (let ((output (shell-command-to-string "/home/anthe/.dotfiles/scripts/switch_devices.py sound_system")))
    (message "%s" output)))

(defun my-switch-drive-1 ()
  (interactive)
  (let ((output (shell-command-to-string "/home/anthe/.dotfiles/scripts/switch_devices.py drive_1")))
    (message "%s" output)))

(defun my-switch-desk-lamp ()
  (interactive)
  (let ((output (shell-command-to-string "/home/anthe/.dotfiles/scripts/switch_lights.py desk_lamp")))
    (message "%s" output)))

(defun my-sync-pi-nas ()
  (interactive)
  (let ((output (async-shell-command "/home/anthe/.dotfiles/scripts/sync_nas.sh")))
    (message "%s" output)))

(map! :leader
      :desc "Backup files to my NAS" "k b" #'my-sync-pi-nas
      :desc "Switch desk lamp" "k t l" #'my-switch-desk-lamp
      :desc "Switch sound system" "k t s" #'my-switch-sound-system
      :desc "Switch drive" "k t d" #'my-switch-drive-1
      :desc "Switch laptop charger" "k t c" #'my-switch-laptop-charger)

;; FIXME: I do not know why, but when I start up emacs now, it is not in main by default but I get 'Not in valid worksapce (nil)'
;; (+workspace/switch-to-0) ;; FIXME: this does not work anyways
;;; config-machine ends here
