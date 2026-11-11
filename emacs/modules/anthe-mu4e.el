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

;; (add-to-list 'load-path "/usr/share/emacs/site-lisp/elpa-src/mu4e-1.12.14/")
(use-package mu4e
  ;; :load-path "~/.config/emacs/.local/mu4e-1.12.6/"
  :defer 20 ; Wait until 20 seconds after startup
  :load-path "/usr/share/emacs/site-lisp/elpa-src/mu4e-1.12.14/"
  :config

  (mu4e t)
  ;; This is set to 't' to avoid mail syncing issues when using mbsync
  (setq mu4e-change-filenames-when-moving t)
  (setq mu4e-confirm-quit nil)
  ;; (setq mu4e-marks-folders-sequentially t)

  ;; The inboxes come as soon as mail arrives (`anthe/mail-idle-start'),
  ;; the other folders with a full sync every 15 minutes.  Both take the
  ;; same lock so that two mbsync never work on the same mailbox
  (setq mu4e-update-interval (* 15 60))
  (setq mu4e-get-mail-command "flock ~/.cache/mail-sync.lock mbsync -a")
  (anthe/mail-idle-start)
  (setq mu4e-root-maildir "~/documents/mail/") ;; does not exist anymore?
  (setq mu4e-headers-date-format "%Y/%m/%d")
  (setq mu4e-index-update-error-warning 'nil)
  ;; Update in silence (errors still show), and only reindex the folders
  ;; that changed, which is what mbsync touches
  (setq mu4e-hide-index-messages t
        mu4e-index-lazy-check t)

  ;; HTML mail in the theme's colours: theirs are made for a white page,
  ;; and come as white blocks in a dark theme.  gb shows them as sent
  (setq shr-use-colors nil)

  ;; Icons in the flags column of the message list.  New messages are also
  ;; unread, so only the unread envelope is shown for them
  (require 'nerd-icons)
  (setq mu4e-use-fancy-chars t
        mu4e-headers-visible-flags '(unread seen draft flagged passed replied trashed
                                     attach encrypted signed list personal)
        mu4e-headers-unread-mark    (cons "u" (nerd-icons-mdicon "nf-md-email" :face 'nerd-icons-blue))
        mu4e-headers-seen-mark      (cons "S" (nerd-icons-mdicon "nf-md-email_open_outline" :face 'shadow))
        mu4e-headers-new-mark       (cons "N" (nerd-icons-mdicon "nf-md-email_alert" :face 'nerd-icons-blue))
        mu4e-headers-draft-mark     (cons "D" (nerd-icons-mdicon "nf-md-pencil" :face 'nerd-icons-yellow))
        mu4e-headers-flagged-mark   (cons "F" (nerd-icons-mdicon "nf-md-flag" :face 'nerd-icons-orange))
        mu4e-headers-passed-mark    (cons "P" (nerd-icons-mdicon "nf-md-share"))
        mu4e-headers-replied-mark   (cons "R" (nerd-icons-mdicon "nf-md-reply"))
        mu4e-headers-trashed-mark   (cons "T" (nerd-icons-mdicon "nf-md-delete" :face 'nerd-icons-red))
        mu4e-headers-attach-mark    (cons "a" (nerd-icons-mdicon "nf-md-paperclip"))
        mu4e-headers-encrypted-mark (cons "x" (nerd-icons-mdicon "nf-md-lock" :face 'nerd-icons-green))
        mu4e-headers-signed-mark    (cons "s" (nerd-icons-mdicon "nf-md-certificate" :face 'nerd-icons-green))
        mu4e-headers-list-mark      (cons "l" (nerd-icons-mdicon "nf-md-format_list_bulleted" :face 'shadow))
        mu4e-headers-personal-mark  (cons "p" (nerd-icons-mdicon "nf-md-account" :face 'shadow))
        mu4e-headers-calendar-mark  (cons "c" (nerd-icons-mdicon "nf-md-calendar")))
  ;; The fancy characters are emoji in the modeline, use envelopes there too
  (setq mu4e-modeline-new-items    (cons "N:" (concat (nerd-icons-mdicon "nf-md-email") " "))
        mu4e-modeline-unread-items (cons "U:" (concat (nerd-icons-mdicon "nf-md-email") " "))
        mu4e-modeline-all-read     (cons "R:" (concat (nerd-icons-mdicon "nf-md-email_open_outline") " "))
        mu4e-modeline-all-clear    (cons "C:" (concat (nerd-icons-mdicon "nf-md-email_open_outline") " ")))
  ;; A column with the folder of each message, an icon and colour for each
  ;; kind: inbox, archive, sent, drafts, trash, spam, or another folder
  (add-to-list 'mu4e-header-info-custom
               '(:anthe-folder :name "Folder" :shortname "Folder"
                 :help "Folder of the message, by kind"
                 :function anthe/mu4e--folder-field))
  ;; and the account it is in, for the searches across accounts
  (add-to-list 'mu4e-header-info-custom
               '(:anthe-account :name "Mailbox" :shortname "Mailbox"
                 :help "Account of the message"
                 :function anthe/mu4e--account-field))
  (setq mu4e-headers-fields '((:human-date . 13) (:flags . 7) (:anthe-account . 8)
                              (:anthe-folder . 11) (:from . 18) (:subject))
        ;; The icons are wider than the one column counted for each, so the
        ;; columns are aligned on their display position, not on characters
        mu4e-headers-precise-alignment t)

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
  ;; New messages go out from the account being visited (see
  ;; `anthe/mu4e--switch-to-searched-context'), replies from the account
  ;; they answer, and only otherwise is the account asked for
  (setq mu4e-compose-context-policy 'ask-if-none)
  ;; Until a context is entered, else Emacs makes it up from the user and
  ;; host names, and mu4e says it is not one of mine
  (setq user-mail-address "antoine.hermant@etik.com")
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
                  ;; No signature: the vars of a context stay set after switching to another
                  (message-signature . nil)
                  (mu4e-drafts-folder  . "/Gmail/[Gmail]/Drafts")
                  (mu4e-sent-folder  . "/Gmail/[Gmail]/Sent Mail")
                  (smtpmail-smtp-server . "smtp.gmail.com")
                  (smtpmail-smtp-service . 587)
                  (smtpmail-stream-type . starttls)
                  (smtpmail-smtp-user . "ah74230@gmail.com")
                  ;; Gmail already files what it sends in Sent Mail
                  (mu4e-sent-messages-behavior . delete)))

         (make-mu4e-context
          :name "Work"
          :match-func
          (lambda (msg)
            (when msg
              (string-prefix-p "/Work" (mu4e-message-field msg :maildir))))
          :vars '((user-mail-address . "antoine.hermant74@gmail.com")
                  (user-full-name    . "Antoine Hermant")
                  ;; No signature: the vars of a context stay set after switching to another
                  (message-signature . nil)
                  (mu4e-drafts-folder  . "/Work/[Gmail]/Drafts")
                  (mu4e-sent-folder  . "/Work/[Gmail]/Sent Mail")
                  (smtpmail-smtp-server . "smtp.gmail.com")
                  (smtpmail-smtp-service . 587)
                  (smtpmail-stream-type . starttls)
                  (smtpmail-smtp-user . "antoine.hermant74@gmail.com")
                  ;; Gmail already files what it sends in Sent Mail
                  (mu4e-sent-messages-behavior . delete)))

         (make-mu4e-context
          :name "Infomaniak"
          :match-func
          (lambda (msg)
            (when msg
              (string-prefix-p "/Infomaniak" (mu4e-message-field msg :maildir))))
          :vars '((user-mail-address . "antoine.hermant@etik.com")
                  (user-full-name    . "Antoine Hermant")
                  ;; No signature: the vars of a context stay set after switching to another
                  (message-signature . nil)
                  (mu4e-drafts-folder  . "/Infomaniak/Drafts")
                  (mu4e-sent-folder  . "/Infomaniak/Sent")
                  (smtpmail-smtp-server . "mail.infomaniak.com")
                  (smtpmail-smtp-service . 465)
                  (smtpmail-stream-type . ssl)
                  (smtpmail-smtp-user . "antoine.hermant@etik.com")
                  (mu4e-sent-messages-behavior . sent)))

         (make-mu4e-context
          :name "AntADatabase"
          :match-func
          (lambda (msg)
            (when msg
              (string-prefix-p "/AntADatabase" (mu4e-message-field msg :maildir))))
          ;; Signed with the name of the project: the sender name (From) and the signature are
          ;; set here, as mu4e sends by SMTP itself (not with those of Infomaniak Mail)
          :vars '((user-mail-address . "contact@antadatabase.com")
                  (user-full-name    . "AntADatabase")
                  (message-signature . "Antoine Hermant\nAntADatabase, https://antadatabase.com")
                  (mu4e-drafts-folder  . "/AntADatabase/Drafts")
                  (mu4e-sent-folder  . "/AntADatabase/Sent")
                  (smtpmail-smtp-server . "mail.infomaniak.com")
                  (smtpmail-smtp-service . 465)
                  (smtpmail-stream-type . ssl)
                  (smtpmail-smtp-user . "contact@antadatabase.com")
                  (mu4e-sent-messages-behavior . sent)))

         (make-mu4e-context
          :name "UniBe"
          :match-func
          (lambda (msg)
            (when msg
              (string-prefix-p "/UniBe" (mu4e-message-field msg :maildir))))
          ;; The signature of Outlook, in plain text
          :vars '((user-mail-address . "antoine.hermant@unibe.ch")
                  (user-full-name    . "Antoine Hermant")
                  (message-signature . "Antoine Hermant
PhD Student | Climate and Environmental Physics (KUP)
Physics Department, University of Bern
Sidlerstrasse 5, CH-3012 Bern
📧 antoine.hermant@unibe.ch | 👾 https://github.com/antoinehermant")
                  (mu4e-drafts-folder  . "/UniBe/Drafts")
                  (mu4e-sent-folder  . "/UniBe/Sent Items")
                  (smtpmail-smtp-server . "smtp.office365.com")
                  (smtpmail-smtp-service . 587)
                  (smtpmail-stream-type . starttls)
                  (smtpmail-smtp-user . "antoine.hermant@unibe.ch")
                  ;; Exchange files what it sends in Sent Items itself
                  (mu4e-sent-messages-behavior . delete)))))

  ;; Archives and trash follow the account of each message, not the
  ;; context, as lists mix the accounts (see `anthe/mu4e-account-folders')
  (setq mu4e-refile-folder (lambda (msg) (anthe/mu4e--account-folder msg 'archive))
        mu4e-trash-folder (lambda (msg) (anthe/mu4e--account-folder msg 'trash)))
  ;; d only moves to the trash: with the trashed flag, mbsync (Expunge Both)
  ;; would delete the message for good at the next sync, trash included.  The
  ;; servers empty their trash after 30 days, and mbsync follows.
  (setq mu4e-trash-without-flag t)
  ;; Archiving from a Gmail inbox only takes it out of the inbox, as Gmail
  ;; already keeps it in All Mail: a move there would make a copy
  (setf (alist-get 'refile mu4e-marks)
        (list :char '("r" . "▶")
              :prompt "refile"
              :dyn-target (lambda (_target msg) (mu4e-get-refile-folder msg))
              :action (lambda (docid msg target)
                        (if (anthe/mu4e--gmail-inbox-p msg)
                            (mu4e--server-remove docid)
                          (mu4e--server-move docid (mu4e--mark-check-target target) "-N")))))

  ;; Send through the SMTP server of the current context, the passwords
  ;; are read from ~/.authinfo, but for Microsoft 365 (UniBe) which only
  ;; takes OAuth2 tokens
  (setq send-mail-function #'smtpmail-send-it
        message-send-mail-function #'smtpmail-send-it
        message-kill-buffer-on-exit t)
  (add-hook 'auth-source-backend-parser-functions #'anthe/mu4e--ms365-backend)
  (advice-add 'smtpmail-try-auth-methods :around #'anthe/mu4e--ms365-auth)

  ;; The signature goes on new messages, not on replies, and messages
  ;; with an HTML signature are sent with an HTML version too
  (advice-add 'mu4e-compose-reply-to :around #'anthe/mu4e--reply-unsigned)
  (add-hook 'message-send-hook #'anthe/mu4e--add-html-signature)

  ;; Attach the marked files of dired with C-c RET C-a, to a message
  ;; being composed or a new one; C-x m composes with mu4e too
  (setq mail-user-agent 'mu4e-user-agent)
  (add-hook 'dired-mode-hook #'turn-on-gnus-dired-mode)

  ;; Let company ask mu4e for contacts before falling back to words of
  ;; the buffer, and keep dictionary words out of the body
  (set-company-backend! 'mu4e-compose-mode 'company-capf)
  (add-hook 'mu4e-compose-mode-hook #'anthe/mu4e--compose-completion)

  ;; The inboxes hold what is still to sort: archive (r), delete (d) or
  ;; flag (+) and archive what waits for an action, found in To do
  (setq mu4e-bookmarks
        `((:name "Inboxes" :query "maildir:/Gmail/INBOX OR maildir:/Work/INBOX OR maildir:/Infomaniak/INBOX OR maildir:/AntADatabase/INBOX OR maildir:/UniBe/INBOX" :key ?i)
          ;; Archiving moves to a folder, it sets no flag: these are the
          ;; archive folders of all the accounts.  / narrows it to a search
          (:name "Archives"
           :query ,(mapconcat (lambda (account)
                                (format "maildir:\"%s\"" (plist-get (cdr account) :archive)))
                              anthe/mu4e-account-folders " OR ")
           :key ?a)
          (:name "To do" :query "flag:flagged AND NOT flag:trashed" :key ?T)
          (:name "Unread messages" :query "flag:unread AND NOT flag:trashed AND NOT tag:\\Trash AND NOT maildir:/Gmail/[Gmail]/Bin AND NOT maildir:/Work/[Gmail]/Bin AND NOT maildir:/Infomaniak/Trash AND NOT maildir:/AntADatabase/Trash AND NOT maildir:\"/UniBe/Deleted Items\"" :key 117)
          (:name "Today's messages" :query "date:today..now AND NOT flag:trashed AND NOT tag:\\Trash AND NOT maildir:/Gmail/[Gmail]/Bin AND NOT maildir:/Work/[Gmail]/Bin AND NOT maildir:/Infomaniak/Trash AND NOT maildir:/AntADatabase/Trash AND NOT maildir:\"/UniBe/Deleted Items\"" :key 116)
          (:name "Drafts" :query "flag:draft AND NOT flag:trashed" :key ?d)
          (:name "Last 7 days" :query "date:7d..now" :hide-unread t :key 119)
          (:name "Messages with images" :query "mime:image/*" :key 112)
          (:name "Finances" :query "from:miimosa AND NOT flag:trashed AND NOT tag:\\Trash OR from:linxea AND NOT tag:\\Trash AND NOT flag:trashed OR from:iroko AND NOT flag:trashed OR from:contact@louveinvest.com AND NOT flag:trashed AND NOT tag:\\Trash" :key ?f)
          (:name "Research News" :query "from:cryolist-request AND NOT flag:trashed OR from:scholar AND NOT flag:trashed OR from:researchgate AND NOT flag:trashed" :key ?r)
          (:name "Cryolist" :query "from:cryolist-request" :key ?c)))

  ;; (setq mu4e-maildir-shortcuts
  ;;       '(("/Gmail/Inbox"             . ?i)
  ;;         ("/Gmail/[Gmail]/Sent Mail" . ?s)
  ;;         ("/Gmail/[Gmail]/Bin"     . ?b)
  ;;         ("/Gmail/[Gmail]/Drafts"    . ?d)
  ;;         ("/Gmail/[Gmail]/All Mail"  . ?a)))
  )

(defun anthe/mu4e--ms365-search (&rest spec)
  "Answer auth-source SPEC for Microsoft 365 with a token of ms365-token.
The token is asked for when used, so a cached answer never goes stale."
  (when (member "smtp.office365.com" (ensure-list (plist-get spec :host)))
    (list (list :host "smtp.office365.com"
                :user (plist-get spec :user)
                :secret (lambda () (car (process-lines "ms365-token")))))))

(defun anthe/mu4e--ms365-backend (entry)
  "Parse the auth-source ENTRY `ms365-token' into a backend."
  (when (eq entry 'ms365-token)
    (auth-source-backend :source "ms365-token" :type 'ms365-token
                         :search-function #'anthe/mu4e--ms365-search)))

(defun anthe/mu4e--ms365-auth (fn process extensions host &rest args)
  "Log in to Microsoft 365 with an OAuth2 token rather than a password.
FN is `smtpmail-try-auth-methods', called with PROCESS, EXTENSIONS, HOST
and ARGS."
  (if (equal host "smtp.office365.com")
      (let ((smtpmail-auth-supported '(xoauth2))
            (auth-sources '(ms365-token)))
        (apply fn process extensions host args))
    (apply fn process extensions host args)))

(defun anthe/mu4e--compose-completion ()
  "Keep dictionary words out of the completions of the message body."
  (remove-hook 'completion-at-point-functions #'ispell-completion-at-point t))

(defun anthe/mu4e--counts ()
  "Return an alist of each maildir and its (UNREAD . TOTAL) messages.
Messages marked as trashed don't count, as in the bookmarks."
  (let (counts)
    (dolist (line (process-lines-ignore-status
                   mu4e-mu-binary "find" "" "--fields" "m g"))
      ;; The maildir may hold spaces, the flags (as in "NS") never do
      (when (string-match "\\`\\(.+\\) \\([A-Za-z]*\\)\\'" line)
        (let ((maildir (match-string 1 line))
              (flags (match-string 2 line)))
          (unless (string-search "T" flags)
            (let ((count (or (assoc maildir counts)
                             (car (push (list maildir 0 0) counts)))))
              (when (or (string-search "N" flags) (not (string-search "S" flags)))
                (cl-incf (nth 1 count)))
              (cl-incf (nth 2 count)))))))
    (mapcar (lambda (count) (cons (car count) (cons (nth 1 count) (nth 2 count))))
            counts)))

(defun anthe/mu4e--account-counts (account counts)
  "Return the (UNREAD . TOTAL) messages of ACCOUNT in COUNTS.
All Mail holds copies of the other folders, and trash and spam don't count."
  (let ((prefix (format "/%s/" account)) (unread 0) (total 0))
    (pcase-dolist (`(,maildir . (,u . ,n)) counts)
      (let ((folder (file-name-nondirectory maildir)))
        (when (and (string-prefix-p prefix maildir)
                   (not (equal folder "All Mail"))
                   (< (anthe/mu4e--folder-rank folder) 2))
          (cl-incf unread u)
          (cl-incf total n))))
    (cons unread total)))

(defun anthe/mu4e--context-address (name)
  "Return the address of the mu4e context called NAME, if there is one."
  (when-let* ((context (seq-find (lambda (c) (equal (mu4e-context-name c) name))
                                 mu4e-contexts)))
    (alist-get 'user-mail-address (mu4e-context-vars context))))

(defun anthe/mu4e--accounts (maildirs)
  "Return the accounts of MAILDIRS, those with a context first, in their order."
  (let ((accounts (delete-dups
                   (delq nil (mapcar (lambda (maildir)
                                       (when (string-match "\\`/\\([^/]+\\)/" maildir)
                                         (match-string 1 maildir)))
                                     maildirs))))
        (contexts (mapcar #'mu4e-context-name mu4e-contexts)))
    (append (seq-filter (lambda (name) (member name accounts)) contexts)
            (seq-remove (lambda (name) (member name contexts)) accounts))))

(defun anthe/mu4e--folder-rank (folder)
  "Return where FOLDER goes: INBOX first, spam and trash last."
  (cond ((equal folder "INBOX") 0)
        ((member folder '("Spam" "Trash" "Bin" "Deleted Items" "Junk Email")) 2)
        (t 1)))

(defun anthe/mu4e--read (prompt candidates annotations)
  "Read one of CANDIDATES with PROMPT, in their order.
ANNOTATIONS is an alist of each candidate and the text shown after it."
  (let* ((width (apply #'max (mapcar #'string-width candidates)))
         (annotate (lambda (candidate)
                     (when-let* ((text (alist-get candidate annotations nil nil #'equal)))
                       (concat (propertize " " 'display `(space :align-to ,(+ width 4)))
                               text)))))
    (completing-read prompt
                     (lambda (string pred action)
                       (if (eq action 'metadata)
                           `(metadata (display-sort-function . identity)
                             (annotation-function . ,annotate))
                         (complete-with-action action candidates string pred)))
                     nil t)))

(defun anthe/mu4e--unread-text (count)
  "Return the text for COUNT unread messages, or nil if there are none."
  (when (> count 0)
    (propertize (format "%d unread" count) 'face 'mu4e-unread-face)))

(defun anthe/mu4e-jump-to-maildir ()
  "Show a maildir, choosing its account first and then the folder."
  (interactive)
  (let* ((maildirs (mu4e-get-maildirs))
         (counts (anthe/mu4e--counts))
         (accounts (anthe/mu4e--accounts maildirs))
         (account
          (anthe/mu4e--read
           "Account: " accounts
           (mapcar (lambda (name)
                     (cons name
                           (string-join
                            (delq nil (list (anthe/mu4e--context-address name)
                                            (anthe/mu4e--unread-text
                                             (car (anthe/mu4e--account-counts name counts)))))
                            "   ")))
                   accounts)))
         (prefix (format "/%s/" account))
         ;; Gmail keeps its folders under [Gmail]/, which says nothing
         (folders (mapcar (lambda (maildir)
                            (cons (string-remove-prefix
                                   "[Gmail]/" (string-remove-prefix prefix maildir))
                                  maildir))
                          (seq-filter (lambda (maildir) (string-prefix-p prefix maildir))
                                      maildirs)))
         (folders (sort folders
                        (lambda (a b)
                          (let ((rank-a (anthe/mu4e--folder-rank (car a)))
                                (rank-b (anthe/mu4e--folder-rank (car b))))
                            (if (= rank-a rank-b)
                                (string< (downcase (car a)) (downcase (car b)))
                              (< rank-a rank-b))))))
         (folder
          (anthe/mu4e--read
           (format "%s folder: " account) (mapcar #'car folders)
           (mapcar (lambda (folder)
                     (cons (car folder)
                           (anthe/mu4e--unread-text
                            (car (alist-get (cdr folder) counts '(0) nil #'equal)))))
                   folders))))
    (mu4e-search-maildir (alist-get folder folders nil nil #'equal))))

;; Signatures
(defvar anthe/mu4e-html-signatures
  '(("antoine.hermant@unibe.ch" .
     "<div style=\"font-family: 'Aptos Mono', monospace; font-size: 11pt; color: #000;\">
<div style=\"color: #666;\"># -----------------------------------------------------</div>
<div>Antoine Hermant</div>
<div>PhD Student | Climate and Environmental Physics (KUP)</div>
<div>Physics Department, University of Bern</div>
<div>Sidlerstrasse 5, CH-3012 Bern</div>
<div>📧 <a href=\"mailto:antoine.hermant@unibe.ch\">antoine.hermant@unibe.ch</a> | 👾 <a href=\"https://github.com/antoinehermant\">GitHub</a></div>
</div>"))
  "The HTML signature of each address, as made in Outlook, with its links.
It replaces the plain one in the HTML version of the messages.")

(defun anthe/mu4e--reply-unsigned (fn &rest args)
  "Call FN with ARGS, `mu4e-compose-reply-to', without the signature."
  ;; The context switch of the reply sets this binding, not the global value
  (let ((message-signature nil))
    (apply fn args)))

(defun anthe/mu4e--html-escape (text)
  "Return TEXT with the special characters of HTML escaped."
  (replace-regexp-in-string
   "[&<>\"]" (lambda (c) (pcase c ("&" "&amp;") ("<" "&lt;") (">" "&gt;") (_ "&quot;")))
   text t t))

(defun anthe/mu4e--add-html-signature ()
  "Add an HTML version to a message signed by an address with an HTML signature.
The text keeps its lines, and the signature its links.  Attachments are
kept after both versions; messages with other MML tags are left alone."
  (when-let* ((from (cadr (mail-extract-address-components
                           (or (message-field-value "From") ""))))
              (signature (alist-get from anthe/mu4e-html-signatures nil nil #'string=)))
    (save-excursion
      (message-goto-body)
      (let* ((start (point))
             (attachments nil)
             (body (replace-regexp-in-string
                    "<#\\(part\\|mml\\)[^>]*>\\(?:.\\|\n\\)*?<#/\\1>\n?"
                    (lambda (part) (push part attachments) "")
                    (buffer-substring-no-properties start (point-max)) t t)))
        (when (and (not (string-search "<#" body))
                   (string-match message-signature-separator body))
          (let ((text (string-trim-right (substring body 0 (match-beginning 0)))))
            (delete-region start (point-max))
            (insert (if attachments "<#multipart type=mixed>\n" "")
                    "<#multipart type=alternative>\n"
                    body
                    "<#part type=text/html>\n<html><body>\n"
                    "<div style=\"font-family: Aptos, Calibri, Helvetica, sans-serif;"
                    " font-size: 12pt; color: #000;\">\n"
                    (replace-regexp-in-string "\n" "<br>\n" (anthe/mu4e--html-escape text))
                    "\n</div>\n<br>\n" signature "\n</body></html>\n"
                    "<#/multipart>\n"
                    (apply #'concat (nreverse attachments))
                    (if attachments "<#/multipart>\n" ""))))))))

(defvar anthe/mu4e-account-folders
  '(("Gmail" :archive "/Gmail/[Gmail]/All Mail" :trash "/Gmail/[Gmail]/Bin")
    ("Work" :archive "/Work/[Gmail]/All Mail" :trash "/Work/[Gmail]/Bin")
    ("Infomaniak" :archive "/Infomaniak/Archives" :trash "/Infomaniak/Trash")
    ("AntADatabase" :archive "/AntADatabase/Archives" :trash "/AntADatabase/Trash")
    ("UniBe" :archive "/UniBe/Archive" :trash "/UniBe/Deleted Items"))
  "The archive and trash folders of each account, the first part of its maildirs.")

(defun anthe/mu4e--account (msg)
  "Return the account of MSG, the first part of its maildir."
  (cadr (split-string (mu4e-message-field msg :maildir) "/")))

(defun anthe/mu4e--account-folder (msg kind)
  "Return the folder of KIND (archive or trash) of the account of MSG."
  (or (plist-get (cdr (assoc (anthe/mu4e--account msg) anthe/mu4e-account-folders))
                 (intern (format ":%s" kind)))
      (user-error "No %s folder for %s" kind (mu4e-message-field msg :maildir))))

(defvar anthe/mu4e-folder-kinds
  '((inbox   "nf-md-inbox"         nerd-icons-blue   "Inbox")
    (archive "nf-md-archive"       nerd-icons-green  "Archive")
    (sent    "nf-md-send"          nerd-icons-cyan   "Sent")
    (drafts  "nf-md-pencil"        nerd-icons-yellow "Drafts")
    (trash   "nf-md-delete"        nerd-icons-red    "Trash")
    (spam    "nf-md-alert_octagon" nerd-icons-orange "Spam")
    (other   "nf-md-folder"        nerd-icons-purple nil))
  "The icon, face and label of each kind of folder, nil for the folder's own name.")

(defun anthe/mu4e--folder-kind (maildir)
  "Return the kind of MAILDIR, a key of `anthe/mu4e-folder-kinds'."
  (let ((folders (cdr (assoc (cadr (split-string maildir "/")) anthe/mu4e-account-folders)))
        (name (file-name-nondirectory maildir)))
    (cond ((equal name "INBOX") 'inbox)
          ((equal maildir (plist-get folders :archive)) 'archive)
          ((equal maildir (plist-get folders :trash)) 'trash)
          ((member name '("Sent" "Sent Items" "Sent Mail")) 'sent)
          ((equal name "Drafts") 'drafts)
          ((member name '("Spam" "Junk" "Junk Email" "quarantine")) 'spam)
          (t 'other))))

(defun anthe/mu4e--folder-field (msg)
  "Return the folder column of MSG in the message list."
  (let* ((maildir (or (mu4e-message-field msg :maildir) ""))
         (kind (assq (anthe/mu4e--folder-kind maildir) anthe/mu4e-folder-kinds))
         (face (nth 2 kind)))
    (propertize (concat (nerd-icons-mdicon (nth 1 kind) :face face) " "
                        (propertize (or (nth 3 kind) (file-name-nondirectory maildir))
                                    'face face))
                'help-echo maildir)))

(defun anthe/mu4e--account-field (msg)
  "Return the mailbox column of MSG in the message list."
  (propertize (or (anthe/mu4e--account msg) "") 'face 'shadow))

(defun anthe/mu4e--gmail-inbox-p (msg)
  "Return non-nil if MSG is in the inbox of a Gmail account."
  (and (string-suffix-p "/INBOX" (mu4e-message-field msg :maildir))
       (string-search "/[Gmail]/" (anthe/mu4e--account-folder msg 'archive))))

;; mail-idle keeps an IMAP IDLE connection open on each inbox and syncs it
;; when mail arrives, then mu4e reindexes
(defvar anthe/mail-idle--process nil)
(defvar anthe/mail-idle--index-timer nil)

(defvar anthe/mu4e--skipped (make-hash-table :test #'equal)
  "Message-ids not to notify, such as Gmail promotions (see GMAIL_SKIP).")

(defun anthe/mail-idle--filter (process output)
  "Reindex after each inbox sync reported in OUTPUT of PROCESS.
Also take note of the messages to skip in notifications."
  (with-current-buffer (process-buffer process)
    (goto-char (point-max))
    (insert output))
  ;; A long line may come in several pieces: keep the last one for later
  (let ((lines (split-string (concat (process-get process 'partial) output) "\n"))
        synced)
    (process-put process 'partial (car (last lines)))
    (dolist (line (butlast lines))
      (pcase (split-string line " " t)
        (`("skip" ,_account . ,msgids)
         (dolist (msgid msgids) (puthash msgid t anthe/mu4e--skipped)))
        (`("synced" . ,_) (setq synced t))))
    (when synced
      ;; Several inboxes may sync in a row: index once after them
      (when (timerp anthe/mail-idle--index-timer)
        (cancel-timer anthe/mail-idle--index-timer))
      (setq anthe/mail-idle--index-timer
            (run-at-time 2 nil (lambda () (when (mu4e-running-p) (mu4e-update-index))))))))

(defun anthe/mail-idle--sentinel (process _event)
  "Start mail-idle again a minute after PROCESS stopped, unless on purpose."
  (unless (or (process-live-p process) (process-get process 'stopped))
    (run-at-time 60 nil #'anthe/mail-idle-start)))

(defun anthe/mail-idle-start ()
  "Start syncing the inboxes as soon as mail arrives."
  (interactive)
  (unless (process-live-p anthe/mail-idle--process)
    (setq anthe/mail-idle--process
          (make-process :name "mail-idle"
                        :buffer (get-buffer-create " *mail-idle*")
                        :command (list (expand-file-name "~/.local/bin/mail-idle"))
                        :connection-type 'pipe
                        :noquery t
                        :filter #'anthe/mail-idle--filter
                        :sentinel #'anthe/mail-idle--sentinel))))

(defun anthe/mail-idle-stop ()
  "Stop syncing the inboxes when mail arrives."
  (interactive)
  (when (process-live-p anthe/mail-idle--process)
    (process-put anthe/mail-idle--process 'stopped t)
    (delete-process anthe/mail-idle--process)))

;; A notification for each new message of an inbox, after each index.
;; Clicking it opens the message
(defvar anthe/mu4e--notified nil
  "Message-ids already notified, or nil before the first index.")

(defun anthe/mu4e--new-inbox-messages ()
  "Return the (MSGID ACCOUNT FROM SUBJECT) of the unread inbox messages."
  (let (found)
    (dolist (line (process-lines-ignore-status
                   mu4e-mu-binary "find" "flag:unread AND date:3d..now"
                   "--fields" "i\tm\tf\ts"))
      (pcase (split-string line "\t")
        (`(,msgid ,maildir ,from ,subject)
         (let ((account (and (string-match "\\`/\\([^/]+\\)/inbox\\'" maildir)
                             (match-string 1 maildir)))
               (sender (mail-header-parse-address from t)))
           ;; Not what I sent to myself, nor promotions
           (when (and account
                      (not (mu4e-personal-or-alternative-address-p (car sender)))
                      (not (gethash msgid anthe/mu4e--skipped)))
             (push (list msgid account (or (cdr sender) from) subject) found))))))
    (nreverse found)))

(defvar anthe/mu4e-work-accounts '("UniBe")
  "The accounts not notified outside working hours.")

(defvar anthe/mu4e-work-quiet-hours t
  "Non-nil to not notify the work accounts outside working hours.
See `anthe/mu4e-work-quiet-p' and `anthe/mu4e-toggle-work-quiet-hours'.")

(defun anthe/mu4e-work-quiet-p ()
  "Return non-nil outside working hours: weekends, and 20:00 to 8:00."
  (let* ((time (decode-time))
         (hour (decoded-time-hour time)))
    (and anthe/mu4e-work-quiet-hours
         (or (memq (decoded-time-weekday time) '(0 6))
             (>= hour 20) (< hour 8)))))

(defun anthe/mu4e-toggle-work-quiet-hours ()
  "Toggle notifying the work accounts outside working hours."
  (interactive)
  (setq anthe/mu4e-work-quiet-hours (not anthe/mu4e-work-quiet-hours))
  (message "Work mail %s outside working hours"
           (if anthe/mu4e-work-quiet-hours "silent" "notified")))

(defun anthe/mu4e--notify-new-mail ()
  "Notify the inbox messages that came since the last index.
The first index only takes note of those already there."
  (let ((first (null anthe/mu4e--notified))
        new)
    (unless anthe/mu4e--notified
      (setq anthe/mu4e--notified (make-hash-table :test #'equal)))
    (dolist (message (anthe/mu4e--new-inbox-messages))
      (unless (gethash (car message) anthe/mu4e--notified)
        (puthash (car message) t anthe/mu4e--notified)
        ;; Taken note of in quiet hours too, so as not to come in the morning
        (unless (and (member (nth 1 message) anthe/mu4e-work-accounts)
                     (anthe/mu4e-work-quiet-p))
          (push message new))))
    (unless first
      (if (> (length new) 4)
          ;; A burst (after a suspend): a single notification
          (notifications-notify
           :title (format "%d new messages" (length new))
           :body (mapconcat (pcase-lambda (`(,_ ,account ,from ,_))
                              (anthe/mu4e--html-escape (format "%s: %s" account from)))
                            (seq-take (reverse new) 6) "\n")
           :app-name "mu4e" :app-icon "mail-unread"
           :actions '("default" "Open") :on-action (lambda (_id _key) (mu4e)))
        (pcase-dolist (`(,msgid ,account ,from ,subject) (reverse new))
          (notifications-notify
           :title (anthe/mu4e--html-escape (format "%s · %s" from account))
           :body (anthe/mu4e--html-escape subject)
           :app-name "mu4e" :app-icon "mail-unread"
           :actions '("default" "Open")
           :on-action (lambda (_id _key) (mu4e-view-message-with-message-id msgid))))))))

(with-eval-after-load 'mu4e
  (require 'notifications)
  (add-hook 'mu4e-index-updated-hook #'anthe/mu4e--notify-new-mail))

;; g and a key go to the inbox of an account, from every mu4e view
(defvar anthe/mu4e-account-keys
  '(("m" . "Gmail") ("w" . "Work") ("i" . "Infomaniak") ("a" . "AntADatabase") ("u" . "UniBe"))
  "The key after g going to the inbox of each account.")

(defun anthe/mu4e-go-to-inbox (account)
  "Show the inbox of ACCOUNT, or all its mail if it has none."
  (if-let* ((inbox (seq-find (lambda (maildir)
                               (string-match-p (format "\\`/%s/inbox\\'" (regexp-quote account))
                                               maildir))
                             (mu4e-get-maildirs))))
      (mu4e-search-maildir inbox)
    (mu4e-search (format "maildir:/%s*" account))))

(with-eval-after-load 'mu4e
  (pcase-dolist (`(,key . ,account) anthe/mu4e-account-keys)
    (let ((go (lambda () (interactive) (anthe/mu4e-go-to-inbox account))))
      (dolist (map (list mu4e-main-mode-map mu4e-headers-mode-map mu4e-view-mode-map))
        (evil-define-key* 'normal map (kbd (concat "g" key)) go)))))

;; gb opens the message in qutebrowser, for what shr renders badly
(defun anthe/mu4e-view-in-browser ()
  "Open the HTML of the message at point in qutebrowser."
  (interactive)
  (let ((browse-url-browser-function (lambda (url &rest _) (qutebrowser-open-url url))))
    (mu4e-action-view-in-browser (mu4e-message-at-point))))

(with-eval-after-load 'mu4e
  (dolist (map (list mu4e-headers-mode-map mu4e-view-mode-map))
    (evil-define-key* 'normal map (kbd "gb") #'anthe/mu4e-view-in-browser)))

;; All the mu4e buffers are real to Doom (its mu4e module only makes the main
;; view real): closing a buffer shown over them, such as the browser for a
;; link, brings them back, where Doom's frame filter skipped them
(defun anthe/mu4e-buffer-p (buffer)
  "Whether BUFFER is a buffer of mu4e."
  (or (string-prefix-p "mu4e-" (symbol-name (buffer-local-value 'major-mode buffer)))
      (eq (buffer-local-value 'major-mode buffer) 'anthe/mu4e-conversation-mode)))

(add-hook 'doom-real-buffer-functions #'anthe/mu4e-buffer-p)

;; Being real, they join each workspace showing them, and persp-mode does not
;; kill a buffer still in another workspace, only takes it out of this one.
;; mu4e kills them to close them (q in a message), and a message buffer left
;; alive breaks its navigation: always let them be killed.  Not the compose
;; buffers, which ask before losing a draft.
(defun anthe/mu4e--always-killable-h ()
  "Let the current buffer be killed even when in other workspaces."
  (setq-local kill-buffer-query-functions nil))

(dolist (hook '(mu4e-main-mode-hook mu4e-headers-mode-hook mu4e-view-mode-hook
                anthe/mu4e-conversation-mode-hook))
  (add-hook hook #'anthe/mu4e--always-killable-h))

;; Doom adds a buffer to the workspace when switching to it, but mu4e shows
;; the message with `display-buffer': out of the workspace, it was skipped
;; when closing the browser, which showed the message list in its place
(defun anthe/mu4e--add-to-workspace-h ()
  "Add the current buffer to the current workspace."
  (when (bound-and-true-p persp-mode)
    (persp-add-buffer (current-buffer) (get-current-persp) nil nil)))

(dolist (hook '(mu4e-main-mode-hook mu4e-headers-mode-hook mu4e-view-mode-hook
                anthe/mu4e-conversation-mode-hook))
  (add-hook hook #'anthe/mu4e--add-to-workspace-h))

;; q only closes the main view: mu4e goes on syncing and notifying, with its
;; icon in the modeline.  Q quits mu4e, and mail-idle with it, where Q was
;; `mu4e-search-query' (the saved searches of b and the folders of J at once)
(defun anthe/mu4e-quit ()
  "Quit mu4e completely, and stop syncing the inboxes when mail arrives."
  (interactive)
  (when (y-or-n-p "Quit mu4e (no more syncing nor notifications)? ")
    (anthe/mail-idle-stop)
    (mu4e-quit)))

(with-eval-after-load 'mu4e
  (evil-define-key* 'normal mu4e-main-mode-map
    "q" #'quit-window
    "Q" #'anthe/mu4e-quit)
  ;; mu4e may start again after Q: so does mail-idle
  (add-hook 'mu4e-main-mode-hook #'anthe/mail-idle-start))

;; W replies to all in a message too, as in the message list (R replies)
(with-eval-after-load 'mu4e
  (evil-define-key* 'normal mu4e-view-mode-map (kbd "W") #'mu4e-compose-wide-reply))

;;; Threads

;; A thread shows as its latest message received, as in Outlook: not my own
;; replies, nor its messages from other folders, unless it has only those.  It
;; has the number of messages in place of the thread lines, and TAB unfolds it.
;; mu4e's own folding keeps the first message instead.
(defvar-local anthe/mu4e--unfolded nil
  "The ids of the threads unfolded in this message list.")

(defface anthe/mu4e-unfolded-face
  '((t :foreground "#FFEB95"))
  "Face of the messages of an unfolded thread, the dark orange of the theme.")

(defun anthe/mu4e--thread-id (msg)
  "Return the id of the thread of MSG, nil when the list has no threads."
  (when-let* ((path (plist-get (mu4e-message-field msg :meta) :path)))
    (car (split-string path ":"))))

(defun anthe/mu4e--threads ()
  "Return the threads of the list, each a list of (POSITION . MSG) in order."
  (let (threads current id)
    (save-excursion
      (goto-char (point-min))
      (while (not (eobp))
        (when-let* ((msg (get-text-property (point) 'msg)))
          (let ((this (anthe/mu4e--thread-id msg)))
            (unless (and this (equal this id))
              (when current (push (nreverse current) threads))
              (setq current nil id this))
            (push (cons (point) msg) current)))
        (forward-line)))
    (when current (push (nreverse current) threads))
    (nreverse threads)))

(defun anthe/mu4e--latest (thread)
  "Return the element of THREAD with the latest message."
  (seq-reduce (lambda (latest line)
                (if (time-less-p (mu4e-message-field (cdr latest) :date)
                                 (mu4e-message-field (cdr line) :date))
                    line
                  latest))
              (cdr thread) (car thread)))

(defun anthe/mu4e--received-p (msg)
  "Whether MSG matches the search and is not from me."
  (not (or (plist-get (mu4e-message-field msg :meta) :related)
           (seq-some (lambda (contact)
                       (mu4e-personal-or-alternative-address-p (mu4e-contact-email contact)))
                     (mu4e-message-field msg :from)))))

(defun anthe/mu4e--shown (thread)
  "Return the element of THREAD showing it: its latest message received."
  (anthe/mu4e--latest (or (seq-filter (lambda (line) (anthe/mu4e--received-p (cdr line)))
                                      thread)
                          thread)))

(defun anthe/mu4e--sort-threads ()
  "Sort the threads by the date of the message showing them.
mu sorts them by their latest message, which may be one of my replies."
  (when (and mu4e-search-threads (eq mu4e-search-sort-field :date))
    (let* ((threads (anthe/mu4e--threads))
           (date (lambda (thread) (mu4e-message-field (cdr (anthe/mu4e--shown thread)) :date)))
           (sorted (sort (copy-sequence threads)
                         (lambda (a b)
                           (if (eq mu4e-search-sort-direction 'ascending)
                               (time-less-p (funcall date a) (funcall date b))
                             (time-less-p (funcall date b) (funcall date a))))))
           (line-end (lambda (pos) (save-excursion (goto-char pos) (line-beginning-position 2)))))
      (unless (equal sorted threads)
        (let ((inhibit-read-only t)
              (texts (mapcar (lambda (thread)
                               (cons thread (buffer-substring (caar thread)
                                                              (funcall line-end (car (car (last thread)))))))
                             threads)))
          (save-excursion
            (goto-char (car (caar threads)))
            (delete-region (car (caar threads)) (funcall line-end (car (car (last (car (last threads)))))))
            (dolist (thread sorted)
              (insert (cdr (assq thread texts))))))
        (goto-char (point-min))))))

(defun anthe/mu4e--after-search ()
  "Sort and fold the threads of the message list just found."
  (when-let* ((buffer (mu4e-get-headers-buffer)))
    (when (buffer-live-p buffer)
      (with-current-buffer buffer
        (anthe/mu4e--sort-threads))
      (anthe/mu4e-fold-refresh)
      (with-current-buffer buffer
        (when-let* ((docid (mu4e~headers-docid-at-point)))
          (mu4e~headers-highlight docid))))))

(defun anthe/mu4e--fold-overlay (beg end &rest properties)
  "Make an overlay of the fold from BEG to END with PROPERTIES."
  (let ((overlay (make-overlay beg end)))
    (overlay-put overlay 'anthe-fold t)
    (while properties
      (overlay-put overlay (pop properties) (pop properties)))
    overlay))

(defun anthe/mu4e--thread-prefix (beg end)
  "Return the bounds of the thread lines drawn between BEG and END, if any."
  (let ((prefix-p (lambda (pos)
                    (memq 'mu4e-thread-fold-face (ensure-list (get-text-property pos 'face)))))
        (pos beg))
    (while (and (< pos end) (not (funcall prefix-p pos)))
      (setq pos (next-single-property-change pos 'face nil end)))
    (when (< pos end)
      (let ((start pos))
        (while (and (< pos end) (funcall prefix-p pos))
          (setq pos (next-single-property-change pos 'face nil end)))
        (cons start pos)))))

(defun anthe/mu4e--fold-thread (thread)
  "Hide the lines of THREAD but the one showing it, and show their number."
  (let* ((latest (car (anthe/mu4e--shown thread)))
         (line-end (lambda (pos) (save-excursion (goto-char pos) (line-beginning-position 2))))
         (latest-end (funcall line-end latest))
         (count (propertize (format "[%d] " (length thread)) 'face 'mu4e-thread-fold-face)))
    (when (< (caar thread) latest)
      (anthe/mu4e--fold-overlay (caar thread) latest 'invisible t))
    (when (< latest-end (funcall line-end (car (car (last thread)))))
      (anthe/mu4e--fold-overlay latest-end (funcall line-end (car (car (last thread))))
                                'invisible t))
    (if-let* ((prefix (anthe/mu4e--thread-prefix latest (1- latest-end))))
        (anthe/mu4e--fold-overlay (car prefix) (cdr prefix) 'display count)
      (anthe/mu4e--fold-overlay (1- latest-end) (1- latest-end) 'before-string count))
    ;; Bold while any message of the thread is unread
    (when (seq-some (lambda (line) (memq 'unread (mu4e-message-field (cdr line) :flags)))
                    thread)
      (anthe/mu4e--fold-overlay latest (1- latest-end) 'face 'mu4e-unread-face))))

(defun anthe/mu4e--line-hidden-p ()
  "Whether the line at point is folded away."
  (invisible-p (line-end-position)))

(defun anthe/mu4e--goto-visible ()
  "Move from a folded line to the line showing its thread."
  (when (anthe/mu4e--line-hidden-p)
    (let ((id (anthe/mu4e--thread-id (mu4e-message-at-point t))))
      (while (and (not (bobp))
                  (equal id (save-excursion
                              (forward-line -1)
                              (anthe/mu4e--thread-id (mu4e-message-at-point t)))))
        (forward-line -1))
      (while (and (anthe/mu4e--line-hidden-p) (not (eobp)))
        (forward-line))
      (move-to-column 2)
      (dolist (window (get-buffer-window-list nil nil t))
        (set-window-point window (point))))))

(defun anthe/mu4e-fold-refresh ()
  "Fold the threads of the message list but the ones unfolded."
  (when-let* ((buffer (mu4e-get-headers-buffer)))
    (when (buffer-live-p buffer)
      (with-current-buffer buffer
        (remove-overlays (point-min) (point-max) 'anthe-fold t)
        (when mu4e-search-threads
          (dolist (thread (anthe/mu4e--threads))
            (when (cdr thread)
              (if (member (anthe/mu4e--thread-id (cdar thread)) anthe/mu4e--unfolded)
                  (anthe/mu4e--fold-overlay
                   (caar thread)
                   (save-excursion (goto-char (car (car (last thread))))
                                   (line-end-position))
                   'face 'anthe/mu4e-unfolded-face)
                (anthe/mu4e--fold-thread thread)))))
        (anthe/mu4e--goto-visible)))))

(defun anthe/mu4e-thread-toggle ()
  "Unfold the thread at point, or fold it back."
  (interactive)
  (when-let* ((id (anthe/mu4e--thread-id (mu4e-message-at-point))))
    (setq anthe/mu4e--unfolded (if (member id anthe/mu4e--unfolded)
                                   (delete id anthe/mu4e--unfolded)
                                 (cons id anthe/mu4e--unfolded)))
    (anthe/mu4e-fold-refresh)))

(defun anthe/mu4e-thread-toggle-all ()
  "Unfold all the threads, or fold them all back if some are unfolded."
  (interactive)
  (setq anthe/mu4e--unfolded
        (unless anthe/mu4e--unfolded
          (delq nil (mapcar (lambda (thread) (anthe/mu4e--thread-id (cdar thread)))
                            (anthe/mu4e--threads)))))
  (anthe/mu4e-fold-refresh))

(with-eval-after-load 'mu4e
  (add-hook 'mu4e-headers-found-hook #'anthe/mu4e--after-search)
  ;; Updated lines are drawn again, and removed ones change the threads
  (advice-add 'mu4e~headers-update-handler :after
              (lambda (&rest _) (anthe/mu4e-fold-refresh)) '((name . anthe-fold)))
  (advice-add 'mu4e~headers-remove-handler :after
              (lambda (&rest _) (anthe/mu4e-fold-refresh)) '((name . anthe-fold))))

;; Moving by thread: to the line showing the next or previous thread
(defun anthe/mu4e--thread-position (backwards)
  "Return the first visible line of the next thread, or previous if BACKWARDS."
  (let ((id (anthe/mu4e--thread-id (mu4e-message-at-point)))
        (step (if backwards -1 1))
        found)
    (save-excursion
      (while (and (not found) (zerop (forward-line step)) (not (eobp)))
        (when-let* ((msg (get-text-property (point) 'msg)))
          (unless (or (anthe/mu4e--line-hidden-p)
                      (and id (equal id (anthe/mu4e--thread-id msg))))
            (setq found (point)))))
      ;; Backwards, that is the last line of the thread: go to its first one
      (when (and found backwards)
        (let ((other (anthe/mu4e--thread-id (get-text-property found 'msg))))
          (while (and other (zerop (forward-line -1))
                      (equal other (anthe/mu4e--thread-id (mu4e-message-at-point t))))
            (unless (anthe/mu4e--line-hidden-p)
              (setq found (point)))))))
    found))

(defun anthe/mu4e--goto-message (position)
  "Go to the line at POSITION of the message list, highlighting it."
  (goto-char position)
  (move-to-column 2)
  (mu4e~headers-highlight (mu4e~headers-docid-at-point)))

(defun anthe/mu4e-headers-next-thread (&optional backwards)
  "Go to the next thread, or the previous one if BACKWARDS."
  (interactive)
  (if-let* ((position (anthe/mu4e--thread-position backwards)))
      (progn
        (anthe/mu4e--goto-message position)
        (when (window-live-p mu4e~headers-view-win)
          (mu4e-headers-view-message)))
    (message "No %s thread" (if backwards "previous" "next"))))

(defun anthe/mu4e-headers-prev-thread ()
  "Go to the previous thread."
  (interactive)
  (anthe/mu4e-headers-next-thread t))

(defun anthe/mu4e-view-next-thread (&optional backwards)
  "Show the latest message of the next thread, or the previous one if BACKWARDS."
  (interactive)
  (let (position)
    (mu4e--view-in-headers-context
     (when (setq position (anthe/mu4e--thread-position backwards))
       (anthe/mu4e--goto-message position)))
    (if (not position)
        (message "No %s thread" (if backwards "previous" "next"))
      (mu4e-select-other-view)
      (mu4e-headers-view-message))))

(defun anthe/mu4e-view-prev-thread ()
  "Show the previous thread."
  (interactive)
  (anthe/mu4e-view-next-thread t))

;; Within a thread, by date whatever the folding: ]t newer, [t older
(defun anthe/mu4e--thread-messages (docid)
  "Return the messages of the thread of DOCID in the message list, oldest first."
  (with-current-buffer (mu4e-get-headers-buffer)
    (save-excursion
      (unless (mu4e~headers-goto-docid docid)
        (user-error "The message is not in the message list"))
      (let ((id (or (anthe/mu4e--thread-id (mu4e-message-at-point))
                    (user-error "The message list has no threads")))
            messages)
        (mu4e-headers-for-each
         (lambda (msg)
           (when (equal id (anthe/mu4e--thread-id msg))
             (push msg messages))))
        (sort messages (lambda (a b) (time-less-p (mu4e-message-field a :date)
                                                  (mu4e-message-field b :date))))))))

(defun anthe/mu4e-view-thread-newer (&optional older)
  "Show the next message of the thread by date, or the previous one if OLDER."
  (interactive)
  (let* ((docid (mu4e-message-field (mu4e-message-at-point) :docid))
         (messages (anthe/mu4e--thread-messages docid))
         (index (seq-position messages docid
                              (lambda (msg id) (eql (mu4e-message-field msg :docid) id))))
         (target (and index (nth (+ index (if older -1 1)) messages))))
    (if (or (not target) (and older (zerop index)))
        (message "This is the %s message of the thread" (if older "oldest" "latest"))
      (with-current-buffer (mu4e-get-headers-buffer)
        (mu4e~headers-goto-docid (mu4e-message-field target :docid))
        (mu4e-headers-view-message)))))

(defun anthe/mu4e-view-thread-older ()
  "Show the previous message of the thread by date."
  (interactive)
  (anthe/mu4e-view-thread-newer t))

;; M marks the thread with a mark to choose, but not its messages from other
;; folders (such as the replies in Sent), which only show for context
(defun anthe/mu4e-mark-thread ()
  "Mark the messages of the thread at point that match the search."
  (interactive)
  (let ((id (or (anthe/mu4e--thread-id (mu4e-message-at-point))
                (user-error "The message list has no threads")))
        (markpair (mu4e--mark-get-markpair "Mark the thread with: " t)))
    (mu4e-headers-for-each
     (lambda (msg)
       (when (and (equal id (anthe/mu4e--thread-id msg))
                  (not (plist-get (mu4e-message-field msg :meta) :related)))
         (mu4e-mark-at-point (car markpair) (cdr markpair)))))))

;;; Conversation: a thread in one buffer, latest message first

(defvar-local anthe/mu4e--conversation-sections nil
  "The overlays of the message bodies, latest first.")

(defun anthe/mu4e--find-part (handle type)
  "Return the first part of MIME type TYPE in HANDLE."
  (cond ((stringp (car handle))
         (seq-some (lambda (part) (anthe/mu4e--find-part part type)) (cdr handle)))
        ((bufferp (car handle))
         (and (equal (mm-handle-media-type handle) type) handle))))

(defun anthe/mu4e--strip-quoted ()
  "Delete the quoted messages from the text in the buffer, if it leaves some."
  (let ((text (buffer-string)))
    (goto-char (point-min))
    ;; The first line introducing a quoted message, in the usual clients
    (when (re-search-forward
           (rx bol (* blank)
               (or (seq (or "On " "Le " "Am ") (+ nonl) (? "\n" (* nonl))
                        (or "wrote:" "écrit :" "écrit:" "schrieb:"))
                   ;; Outlook: the header of the reply, on one line each or not
                   (seq (? "*") (or "From:" "De :" "De:" "Von:") (? "*") (* nonl) "\n"
                        (** 0 4 (* nonl) "\n")
                        (? "*") (or "Sent:" "Date:" "Envoyé :" "Envoyé:" "Gesendet:"))
                   (seq (>= 3 "-") (* blank) "Original Message")
                   (seq (>= 10 (any "-_─━")) (* blank) eol)))
           nil t)
      (delete-region (match-beginning 0) (point-max)))
    (flush-lines "^[ \t]*>" (point-min) (point-max))
    (goto-char (point-max))
    (skip-chars-backward " \t\n")
    (delete-region (point) (point-max))
    (when (= (buffer-size) 0)
      (insert text))))

(defun anthe/mu4e--message-text (msg)
  "Return the text of MSG without the quoted messages."
  (let ((path (mu4e-message-field msg :path)))
    (if (not (and path (file-readable-p path)))
        (propertize "(The message file is gone: it was moved since the search)"
                    'face 'shadow)
      (with-temp-buffer
        (set-buffer-multibyte nil)
        (insert-file-contents-literally path)
        (let* ((handle (mm-dissect-buffer t t))
               (part (or (anthe/mu4e--find-part handle "text/plain")
                         (anthe/mu4e--find-part handle "text/html"))))
          (unwind-protect
              (with-temp-buffer
                (when part
                  (insert (decode-coding-string
                           (mm-get-part part)
                           (or (mm-charset-to-coding-system
                                (mail-content-type-get (mm-handle-type part) 'charset) nil t)
                               'utf-8)))
                  (when (equal (mm-handle-media-type part) "text/html")
                    (let ((shr-width 80) (shr-use-fonts nil))
                      (shr-render-region (point-min) (point-max)))))
                (goto-char (point-min))
                (while (search-forward "\r" nil t)
                  (replace-match ""))
                (anthe/mu4e--strip-quoted)
                (buffer-string))
            (mm-destroy-parts handle)))))))

(defun anthe/mu4e--contacts (contacts)
  "Return the names, or else addresses, of CONTACTS."
  (mapconcat (lambda (contact) (or (mu4e-contact-name contact) (mu4e-contact-email contact)))
             contacts ", "))

(defun anthe/mu4e--conversation-toggle (overlay &optional open)
  "Collapse the message of OVERLAY, or expand it if collapsed or OPEN is non-nil."
  (let ((collapse (and (not open) (not (overlay-get overlay 'invisible)))))
    (overlay-put overlay 'invisible collapse)
    (overlay-put (overlay-get overlay 'heading) 'after-string
                 (when collapse (overlay-get overlay 'snippet)))))

(defun anthe/mu4e--conversation-section ()
  "Return the body overlay of the message at point."
  (seq-find (lambda (overlay) (<= (overlay-start (overlay-get overlay 'heading)) (point)))
            (reverse anthe/mu4e--conversation-sections)))

(defun anthe/mu4e-conversation-toggle ()
  "Collapse or expand the message at point."
  (interactive)
  (when-let* ((overlay (anthe/mu4e--conversation-section)))
    (goto-char (overlay-start (overlay-get overlay 'heading)))
    (anthe/mu4e--conversation-toggle overlay)))

(defun anthe/mu4e-conversation-toggle-all ()
  "Expand all the messages, or collapse them all if all are expanded."
  (interactive)
  (let ((open (seq-some (lambda (overlay) (overlay-get overlay 'invisible))
                        anthe/mu4e--conversation-sections)))
    (dolist (overlay anthe/mu4e--conversation-sections)
      (anthe/mu4e--conversation-toggle overlay open))))

(defun anthe/mu4e-conversation-next (&optional backwards)
  "Go to the next message, or the previous one if BACKWARDS."
  (interactive)
  (let* ((headings (mapcar (lambda (overlay) (overlay-start (overlay-get overlay 'heading)))
                           anthe/mu4e--conversation-sections))
         (target (if backwards
                     (seq-find (lambda (pos) (< pos (line-beginning-position))) (reverse headings))
                   (seq-find (lambda (pos) (> pos (point))) headings))))
    (if target
        (goto-char target)
      (message "No %s message" (if backwards "previous" "next")))))

(defun anthe/mu4e-conversation-prev ()
  "Go to the previous message."
  (interactive)
  (anthe/mu4e-conversation-next t))

(defun anthe/mu4e-conversation-open ()
  "Show the message at point in mu4e, in the message list."
  (interactive)
  (when-let* ((overlay (anthe/mu4e--conversation-section))
              (docid (overlay-get overlay 'docid)))
    (quit-window)
    (pop-to-buffer (mu4e-get-headers-buffer))
    (mu4e~headers-goto-docid docid)
    (mu4e-headers-view-message)))

(define-derived-mode anthe/mu4e-conversation-mode special-mode "Conversation"
  "Major mode showing a mail thread, latest message first."
  (setq-local line-spacing 0.1))

(with-eval-after-load 'evil
  (evil-set-initial-state 'anthe/mu4e-conversation-mode 'normal)
  (evil-define-key* 'normal anthe/mu4e-conversation-mode-map
    (kbd "TAB") #'anthe/mu4e-conversation-toggle
    (kbd "<tab>") #'anthe/mu4e-conversation-toggle
    (kbd "<backtab>") #'anthe/mu4e-conversation-toggle-all
    (kbd "RET") #'anthe/mu4e-conversation-open
    (kbd "C-j") #'anthe/mu4e-conversation-next
    (kbd "C-k") #'anthe/mu4e-conversation-prev
    "q" #'quit-window))

(defun anthe/mu4e-conversation ()
  "Show the thread of the message at point in one buffer, latest message first.
The latest and the unread messages are expanded, without what they quote."
  (interactive)
  (let* ((docid (mu4e-message-field (mu4e-message-at-point) :docid))
         (messages (reverse (anthe/mu4e--thread-messages docid)))
         (buffer (get-buffer-create "*mu4e-conversation*")))
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (erase-buffer)
        (delete-all-overlays)
        (anthe/mu4e-conversation-mode)
        (insert (propertize (or (mu4e-message-field (car (last messages)) :subject) "")
                            'face 'mu4e-header-title-face)
                (propertize (format "  %d messages\n\n" (length messages)) 'face 'shadow))
        (dolist (msg messages)
          (let* ((unread (memq 'unread (mu4e-message-field msg :flags)))
                 (heading-start (point))
                 heading body-start text)
            (insert (propertize (anthe/mu4e--contacts (mu4e-message-field msg :from))
                                'face (if unread 'mu4e-unread-face 'mu4e-contact-face))
                    "  "
                    (propertize (format-time-string "%a %d %b %Y %H:%M"
                                                    (mu4e-message-field msg :date))
                                'face 'shadow))
            (setq heading (make-overlay heading-start (point)))
            (insert "\n")
            (setq body-start (point)
                  text (anthe/mu4e--message-text msg))
            (insert (propertize (concat "To: " (anthe/mu4e--contacts
                                                (append (mu4e-message-field msg :to)
                                                        (mu4e-message-field msg :cc))))
                                'face 'shadow)
                    "\n\n" text "\n")
            (let ((overlay (make-overlay body-start (point))))
              (overlay-put overlay 'heading heading)
              (overlay-put overlay 'docid (mu4e-message-field msg :docid))
              (overlay-put overlay 'snippet
                           (propertize (concat "  " (truncate-string-to-width
                                                     (string-clean-whitespace text) 70 nil nil "…"))
                                       'face 'shadow))
              (push overlay anthe/mu4e--conversation-sections)
              (unless (or unread (eq msg (car messages)))
                (anthe/mu4e--conversation-toggle overlay)))
            (insert "\n")))
        (setq anthe/mu4e--conversation-sections (nreverse anthe/mu4e--conversation-sections))
        (goto-char (point-min))
        (anthe/mu4e-conversation-next)))
    (pop-to-buffer-same-window buffer)))

(with-eval-after-load 'mu4e
  ;; In the thread mode of the list, where mu4e's folding is bound in normal
  ;; state too, and minor modes come before the major mode
  (evil-define-key* 'normal mu4e-thread-mode-map
    (kbd "TAB") #'anthe/mu4e-thread-toggle
    (kbd "<tab>") #'anthe/mu4e-thread-toggle
    (kbd "<C-tab>") #'anthe/mu4e-thread-toggle
    (kbd "<backtab>") #'anthe/mu4e-thread-toggle-all)
  (evil-define-key* 'normal mu4e-headers-mode-map
    "}" #'anthe/mu4e-headers-next-thread
    "{" #'anthe/mu4e-headers-prev-thread
    "M" #'anthe/mu4e-mark-thread
    "zc" #'anthe/mu4e-conversation)
  (evil-define-key* 'normal mu4e-view-mode-map
    (kbd "C-j") #'anthe/mu4e-view-next-thread
    (kbd "C-k") #'anthe/mu4e-view-prev-thread
    "]t" #'anthe/mu4e-view-thread-newer
    "[t" #'anthe/mu4e-view-thread-older
    "zc" #'anthe/mu4e-conversation))

;; Compose in the account being visited: a search within a single account
;; switches to its context, which new messages then use
(defun anthe/mu4e--switch-to-searched-context (query)
  "Switch to the context of the account QUERY searches, if only one."
  (let ((accounts (delete-dups
                   (let (found (start 0))
                     (while (string-match "maildir:\"?/\\([^/\"* ]+\\)" query start)
                       (push (match-string 1 query) found)
                       (setq start (match-end 0)))
                     found))))
    (when (and (= (length accounts) 1)
               (member (car accounts) (mapcar #'mu4e-context-name mu4e-contexts))
               (not (equal (car accounts)
                           (and (mu4e-context-current) (mu4e-context-name (mu4e-context-current))))))
      (mu4e-context-switch nil (car accounts)))))

(add-hook 'mu4e-search-hook #'anthe/mu4e--switch-to-searched-context)

;; The main view lists the accounts in place of the maildir shortcuts
(defun anthe/mu4e--main-accounts ()
  "Return the lines of the accounts, each showing its inbox when activated."
  (let* ((counts (anthe/mu4e--counts))
         (accounts (anthe/mu4e--accounts (mapcar #'car counts)))
         (width (apply #'max 0 (mapcar #'string-width accounts)))
         (addresses (mapcar (lambda (name) (or (anthe/mu4e--context-address name) ""))
                            accounts))
         (address-width (apply #'max 0 (mapcar #'string-width addresses))))
    (cl-loop
     for name in accounts
     for address in addresses
     for (unread . total) = (anthe/mu4e--account-counts name counts)
     for key = (car (rassoc name anthe/mu4e-account-keys))
     concat (mu4e--main-action
             (format "\t* %s %s%s  %s%s  %s/%d\n"
                     (if key
                         (format "[%s]" (propertize (concat "g" key) 'face 'mu4e-highlight-face))
                       "    ")
                     (propertize name 'face 'mu4e-header-key-face)
                     (make-string (- width (string-width name)) ?\s)
                     address
                     (make-string (- address-width (string-width address)) ?\s)
                     (if (> unread 0)
                         (propertize (number-to-string unread) 'face 'mu4e-unread-face)
                       "0")
                     total)
             (lambda () (interactive) (anthe/mu4e-go-to-inbox name))
             " "))))

(defun anthe/mu4e--main-show-accounts ()
  "Put the accounts in place of the (empty) maildirs of the main view."
  (when-let* ((buffer (get-buffer mu4e-main-buffer-name)))
    (with-current-buffer buffer
      (save-excursion
        (goto-char (point-min))
        (when (search-forward "  Maildirs\n\n" nil t)
          (let ((inhibit-read-only t)
                (start (match-beginning 0)))
            ;; The section ends at its blank line
            (re-search-forward "^\n" nil 'move)
            (delete-region start (1- (point)))
            (goto-char start)
            (insert (propertize "  Accounts\n\n" 'face 'mu4e-title-face)
                    (anthe/mu4e--main-accounts))))))))

(advice-add 'mu4e--main-redraw :after #'anthe/mu4e--main-show-accounts)

;; J in every mu4e view
(define-key global-map [remap mu4e-search-maildir] #'anthe/mu4e-jump-to-maildir)
(define-key global-map [remap mu4e~headers-jump-to-maildir] #'anthe/mu4e-jump-to-maildir)

(map! :leader
      :desc "Open mu4e" "o m" #'mu4e)

(provide 'anthe-mu4e)
;;; anthe-mu4e.el ends here
