;;; anthe-mu4e.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Maintainer: anthe <anthe@inspiron>
;; Created: February 15, 2026
;; Modified: February 15, 2026
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/anthe/anthe-mu4e
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

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

(map! :leader
      :desc "Open mu4e" "o m" #'mu4e)

(provide 'anthe-mu4e)
;;; anthe-mu4e.el ends here
