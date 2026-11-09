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
                  (mu4e-refile-folder  . "/Gmail/[Gmail]/All Mail")
                  (mu4e-trash-folder  . "/Gmail/[Gmail]/Bin")
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
                  (mu4e-refile-folder  . "/Work/[Gmail]/All Mail")
                  (mu4e-trash-folder  . "/Work/[Gmail]/Bin")
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
                  (mu4e-refile-folder  . "/Infomaniak/INBOX")
                  (mu4e-trash-folder  . "/Infomaniak/Trash")
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
                  (mu4e-refile-folder  . "/AntADatabase/INBOX")
                  (mu4e-trash-folder  . "/AntADatabase/Trash")
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
                  (mu4e-refile-folder  . "/UniBe/Archive")
                  (mu4e-trash-folder  . "/UniBe/Deleted Items")
                  (smtpmail-smtp-server . "smtp.office365.com")
                  (smtpmail-smtp-service . 587)
                  (smtpmail-stream-type . starttls)
                  (smtpmail-smtp-user . "antoine.hermant@unibe.ch")
                  ;; Exchange files what it sends in Sent Items itself
                  (mu4e-sent-messages-behavior . delete)))))

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

  (setq mu4e-bookmarks
        `((:name "Unread messages" :query "flag:unread AND NOT flag:trashed AND NOT tag:\\Trash AND NOT maildir:/Gmail/[Gmail]/Bin AND NOT maildir:/Work/[Gmail]/Bin AND NOT maildir:/Infomaniak/Trash AND NOT maildir:/AntADatabase/Trash AND NOT maildir:\"/UniBe/Deleted Items\"" :key 117)
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
        (push message new)))
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
