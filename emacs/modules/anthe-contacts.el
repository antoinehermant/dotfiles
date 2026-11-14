;;; anthe-contacts.el --- Address book with khard and vdirsyncer -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Created: November 13, 2026
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  The contacts are vCard files in ~/documents/contacts, synced by
;;  vdirsyncer with Radicale on the Pi (also synced by the phone with
;;  DAVx5) and with Infomaniak. khard reads and writes them, khardel
;;  edits them in Emacs as a YAML form (`C-c C-c' saves).
;;
;;  - The address book joins mu4e's address completion.
;;  - `anthe/contacts-add-from-mail' saves people known from mail.
;;  - Every save, and a timer, syncs the address book.
;;
;;; Code:

(defvar anthe/contacts-sync-pairs '("radicale_contacts" "infomaniak_contacts")
  "The vdirsyncer pairs of the address book.")

(defvar anthe/contacts-directory
  "~/documents/contacts/66d789c6-a165-408a-a658-5ed3d7170583/"
  "The local address book, one vCard file per contact.")

(defvar anthe/contacts-sync-interval (* 30 60)
  "Seconds between two syncs of the address book.")

(defvar anthe/contacts--process nil)
(defvar anthe/contacts--emails nil
  "Cache of the address book: a list of (EMAIL . NAME).")

(defun anthe/contacts--ensure-khardel ()
  "Load khardel, installing it from GitHub on first use.
`doom sync' can't fetch MELPA's recipes (MELPA renamed its branch), so the
recipe is given in full."
  (unless (require 'khardel nil t)
    (straight-use-package '(khardel :host github :repo "DamienCassou/khardel"))
    (require 'khardel)))

;;; Reading the address book

(defun anthe/contacts--list-emails ()
  "Return the address book as a list of (EMAIL . NAME), cached."
  (or anthe/contacts--emails
      (setq anthe/contacts--emails
            (with-temp-buffer
              (when (zerop (call-process "khard" nil t nil "email"
                                         "--parsable" "--remove-first-line"))
                (let (emails)
                  (dolist (line (split-string (buffer-string) "\n" t) emails)
                    (pcase (split-string line "\t")
                      (`(,email ,name . ,_)
                       (push (cons (downcase email) name) emails))))))))))

(defun anthe/contacts--flush ()
  "Forget the cached address book, here and in khardel."
  (setq anthe/contacts--emails nil)
  (when (fboundp 'khardel-flush-caches)
    (khardel-flush-caches)))

;;; mu4e address completion

(defun anthe/contacts--format (email name)
  "Format EMAIL and NAME as mu4e does for its completion."
  (if (and name (not (string-empty-p name)))
      (format "%s <%s>" (mu4e--rfc822-quote-phrase name) email)
    email))

(defun anthe/contacts--add-to-mu4e (&rest _)
  "Add the address book to the addresses mu4e completes."
  (when (hash-table-p (bound-and-true-p mu4e--contacts-set))
    (pcase-dolist (`(,email . ,name) (anthe/contacts--list-emails))
      (puthash (anthe/contacts--format email name) t mu4e--contacts-set))))

(with-eval-after-load 'mu4e
  (advice-add 'mu4e--update-contacts :after #'anthe/contacts--add-to-mu4e))

;;; Sync

(defun anthe/contacts-sync (&optional quiet)
  "Sync the address book with the Pi and Infomaniak, in the background.
With QUIET, only report failures."
  (interactive)
  (unless (process-live-p anthe/contacts--process)
    (let ((buffer (get-buffer-create " *anthe-contacts-sync*")))
      (with-current-buffer buffer (erase-buffer))
      (setq anthe/contacts--process
            (make-process
             :name "anthe-contacts-sync"
             :buffer buffer
             :noquery t
             :command `("vdirsyncer" "sync" ,@anthe/contacts-sync-pairs)
             :sentinel
             (lambda (process _event)
               (unless (process-live-p process)
                 (anthe/contacts--flush)
                 (anthe/contacts--add-to-mu4e)
                 (if (zerop (process-exit-status process))
                     (unless quiet (message "Contacts synced"))
                   (message "Contacts sync failed, see the buffer %s"
                            (buffer-name buffer))))))))))

(defvar anthe/contacts--timer
  (run-at-time 60 anthe/contacts-sync-interval #'anthe/contacts-sync t))

;;; Editing

(defun anthe/contacts-open ()
  "Choose a contact and edit it (`C-c C-c' saves)."
  (interactive)
  (anthe/contacts--ensure-khardel)
  (call-interactively #'khardel-edit-contact))

(defun anthe/contacts-new ()
  "Create a contact (`C-c C-c' saves)."
  (interactive)
  (anthe/contacts--ensure-khardel)
  (khardel-new-contact))

(defun anthe/contacts--new-prefilled (name email type)
  "Create a contact with NAME, and EMAIL as a TYPE address, in the form."
  (anthe/contacts-new)
  (let* ((name (string-trim (or name "")))
         ;; "Last, First" as some mail clients write it
         (name (if (string-match "\\`\\([^,]+\\), *\\(.+\\)\\'" name)
                   (concat (match-string 2 name) " " (match-string 1 name))
                 name))
         (words (split-string name))
         (first (string-join (butlast words) " "))
         (last (car (last words))))
    (save-excursion
      (dolist (field `(("Formatted name" . ,name)
                       ("First name" . ,(if (cdr words) first (or last "")))
                       ("Last name" . ,(if (cdr words) last ""))))
        (goto-char (point-min))
        (when (re-search-forward (format "^%s *: *$" (car field)) nil t)
          (insert (cdr field)))))
    (anthe/contacts--add-email-here email type)))

;;; Groups (vCard categories)

(defun anthe/contacts--groups ()
  "Return the groups used in the address book, sorted."
  (let (groups)
    (dolist (line (ignore-errors
                    (process-lines "grep" "-rhi" "^CATEGORIES"
                                   (expand-file-name anthe/contacts-directory))))
      (dolist (group (split-string (replace-regexp-in-string "\\`[^:]*:" "" line)
                                   "," t "[ \t\r]+"))
        (cl-pushnew group groups :test #'string=)))
    (sort groups #'string<)))

(defun anthe/contacts--read-groups ()
  "Ask for groups, among the existing ones or new ones. RET alone: none."
  (completing-read-multiple "Groups (comma between them, RET for none): "
                            (anthe/contacts--groups)))

(defun anthe/contacts--add-groups-here (groups)
  "Add GROUPS to the Categories field of the contact form in this buffer."
  (when groups
    (goto-char (point-min))
    (when (re-search-forward "^Categories *:\\(.*\\)$" nil t)
      (let* ((start (match-beginning 0))
             (value (string-trim (match-string 1)))
             (end (progn (forward-line 1)
                         (while (looking-at " *- ") (forward-line 1))
                         (point)))
             (existing (if (string-empty-p value)
                           (save-excursion
                             (goto-char start)
                             (forward-line 1)
                             (let (items)
                               (while (looking-at " *- *\\(.*?\\) *$")
                                 (push (match-string 1) items)
                                 (forward-line 1))
                               (nreverse items)))
                         (list value)))
             (all (seq-uniq (append existing groups))))
        (delete-region start end)
        (goto-char start)
        (insert (if (cdr all)
                    (concat "Categories :\n"
                            (mapconcat (lambda (group) (concat "    - " group "\n")) all))
                  (format "Categories : %s\n" (car all))))))))

(defun anthe/contacts--groups-capf ()
  "Complete the groups in the Categories field of a contact form."
  (let ((in-field
         (save-excursion
           (beginning-of-line)
           (or (looking-at "Categories *: *")
               (and (looking-at " *- *")
                    (progn
                      (while (and (zerop (forward-line -1)) (looking-at " *- ")))
                      (looking-at "Categories *:")))))))
    (when in-field
      (let ((start (save-excursion
                     (skip-chars-backward "^:-" (line-beginning-position))
                     (skip-chars-forward " \t")
                     (point))))
        (when (>= (point) start)
          (list start (point) (anthe/contacts--groups) :exclusive 'no))))))

(defun anthe/contacts--setup-form ()
  "Complete the groups in a khardel contact form."
  (add-hook 'completion-at-point-functions #'anthe/contacts--groups-capf nil t))

(defun anthe/contacts--mail-candidates ()
  "Addresses known from mail that are not in the address book yet.
Those of the message at point come first."
  (let* ((known (anthe/contacts--list-emails))
         (message (and (fboundp 'mu4e-message-at-point)
                       (derived-mode-p 'mu4e-headers-mode 'mu4e-view-mode)
                       (mu4e-message-at-point t)))
         (here (and message
                    (mapcan (lambda (field) (copy-sequence (plist-get message field)))
                            '(:from :to :cc :bcc :reply-to))))
         candidates)
    (dolist (contact here)
      (let ((email (downcase (plist-get contact :email))))
        (unless (assoc email known)
          (push (propertize (anthe/contacts--format email (plist-get contact :name))
                            'anthe-group "This message")
                candidates))))
    (when (hash-table-p (bound-and-true-p mu4e--contacts-set))
      (maphash (lambda (contact _)
                 (let ((email (cadr (mail-extract-address-components contact))))
                   (unless (or (null email) (assoc (downcase email) known))
                     (push (propertize contact 'anthe-group "Known from mail")
                           candidates))))
               mu4e--contacts-set))
    (delete-dups (nreverse candidates))))

(defun anthe/contacts--read-grouped (prompt candidates)
  "Read one of CANDIDATES with PROMPT, keeping their order.
Candidates are grouped by their `anthe-group' text property."
  (completing-read
   prompt
   (lambda (string predicate action)
     (if (eq action 'metadata)
         `(metadata
           (display-sort-function . identity)
           (group-function
            . ,(lambda (candidate transform)
                 (if transform candidate
                   (get-text-property 0 'anthe-group candidate)))))
       (complete-with-action action candidates string predicate)))
   nil t))

(defvar anthe/contacts-email-types '("home" "work" "other")
  "The labels offered for a new email address.")

(defun anthe/contacts--read-email-type (email)
  "Ask which label EMAIL gets."
  (completing-read (format "%s is a [home/work/other] address: " email)
                   anthe/contacts-email-types nil t nil nil
                   (car anthe/contacts-email-types)))

(defun anthe/contacts--add-email-here (email type)
  "Add EMAIL as a TYPE address to the contact form in this buffer.
An empty TYPE entry gets it. An entry that already has an address becomes
a list. Without a TYPE entry, one is added."
  (goto-char (point-min))
  (if (not (re-search-forward "^Email *:.*$" nil t))
      (message "No Email section in this form")
    (let ((section-end (save-excursion
                         (if (re-search-forward "^$" nil t) (point-marker)
                           (point-max-marker))))
          (entry (format "^\\( +\\)%s *:\\(.*\\)$" (regexp-quote type)))
          (case-fold-search t))
      (if (not (save-excursion (re-search-forward entry section-end t)))
          (progn (end-of-line)
                 (insert (format "\n    %s : %s" type email)))
        (re-search-forward entry section-end)
        (let* ((value-start (match-beginning 2))
               (indent (match-string 1))
               (value (string-trim (match-string 2))))
          (cond
           ;; A list of addresses follows: add one at its end
           ((and (string-empty-p value)
                 (save-excursion (forward-line 1) (looking-at " *- ")))
            (forward-line 1)
            (while (looking-at " *- ") (forward-line 1))
            (insert indent "  - " email "\n"))
           ;; Empty entry
           ((string-empty-p value)
            (delete-horizontal-space)
            (insert " " email))
           ;; One address already: turn it into a list
           (t
            (delete-region value-start (line-end-position))
            (insert (format "\n%s  - %s\n%s  - %s"
                            indent value indent email)))))))
    (message "Check the form, then C-c C-c saves the contact")))

(defun anthe/contacts-add-from-mail ()
  "Save someone you exchanged mail with in the address book.
In mu4e, the people of the message at point are listed first. The address
goes to a new contact or is added to an existing one, the contacts whose
name shares a word with the person's name listed first."
  (interactive)
  (anthe/contacts--ensure-khardel)
  (let* ((choice (anthe/contacts--read-grouped
                  "Add to contacts: " (anthe/contacts--mail-candidates)))
         (parts (mail-extract-address-components choice))
         (name (car parts))
         (email (cadr parts))
         (contacts (khardel--list-contacts))
         (words (seq-filter (lambda (word) (> (length word) 2))
                            (split-string (downcase (or name "")) "[^[:alnum:]]+" t)))
         (new (propertize "New contact" 'anthe-group "New"))
         likely others)
    (dolist (contact-name (sort (hash-table-keys contacts) #'string<))
      (if (seq-some (lambda (word) (member word (split-string (downcase contact-name)
                                                              "[^[:alnum:]]+" t)))
                    words)
          (push (propertize contact-name 'anthe-group "Same name") likely)
        (push (propertize contact-name 'anthe-group "Other contacts") others)))
    (let ((target (anthe/contacts--read-grouped
                   (format "Add %s to: " email)
                   (append (list new) (nreverse likely) (nreverse others)))))
      (let ((type (anthe/contacts--read-email-type email))
            (groups (anthe/contacts--read-groups)))
        (if (equal target "New contact")
            (anthe/contacts--new-prefilled name email type)
          (khardel-edit-contact (gethash target contacts))
          (anthe/contacts--add-email-here email type))
        (anthe/contacts--add-groups-here groups)
        (goto-char (point-min))))))

(defun anthe/contacts-delete (contact)
  "Delete CONTACT, on the Pi and Infomaniak too at the next sync.
To merge two contacts: copy what you need from one into the other, then
delete it."
  (interactive (progn (anthe/contacts--ensure-khardel)
                      (list (khardel-choose-contact))))
  (when (yes-or-no-p (format "Delete the contact %s? " (cdr contact)))
    (if (zerop (call-process "khard" nil nil nil "remove" "--force"
                             (format "uid:%s" (car contact))))
        (progn (message "Deleted %s" (cdr contact))
               (anthe/contacts-sync t))
      (message "khard couldn't delete %s" (cdr contact)))))

(with-eval-after-load 'khardel
  (add-hook 'khardel-edit-mode-hook #'anthe/contacts--setup-form)
  ;; Doom sets the company backends after the mode hooks: capf first, so
  ;; the groups come before dabbrev and ispell
  (set-company-backend! 'khardel-edit-mode 'company-capf)
  ;; Push a saved contact to the Pi and Infomaniak right away
  (add-hook 'khardel-edit-finished-hook #'anthe/contacts-sync))

(map! :leader
      :desc "Find or edit contact" "k p p" #'anthe/contacts-open
      :desc "New contact" "k p n" #'anthe/contacts-new
      :desc "Add contact from mail" "k p a" #'anthe/contacts-add-from-mail
      :desc "Delete contact" "k p d" #'anthe/contacts-delete
      :desc "Sync contacts" "k p s" #'anthe/contacts-sync)

(provide 'anthe-contacts)
;;; anthe-contacts.el ends here
