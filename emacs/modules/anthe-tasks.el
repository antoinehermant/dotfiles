;;; anthe-tasks.el --- Daily carry-over, Inbox, tags and the done log -*- lexical-binding: t; -*-
;;
;; Author: anthe <anthe@inspiron>
;; Created: November 22, 2026
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;; The task flow set up on 2026-11-22 (see the "Personal system development"
;; roam note):
;; - The open TODOs of the last daily note move to today's, under "Carried
;;   over", with :SINCE: (the day they were written) and :CARRIED: (how many
;;   times they moved). The last "Stopped" note is copied there too.
;; - `SPC k n s' writes the "Stopped" note of the hard stop in today's daily.
;; - `SPC m r i' (`SPC m i' in the agenda) sends a TODO to the Inbox.
;; - "#" in a heading offers the tags in use; the choice becomes a tag.
;; - `SPC m A' archives into ~/org/roam/Log.org, a date tree in the agenda;
;;   `SPC k o A' archives every DONE and KILL of the agenda files at once.
;; - The agenda `l' (`SPC o a a l') lists what was done, latest first;
;;   `s t' or `\' filters it by tag.
;;
;;; Code:

(require 'org)
(require 'org-id)
(require 'org-roam)

(defvar anthe-tasks-inbox-file (expand-file-name "~/org/roam/Inbox.org")
  "The file of the Inbox.")

(defvar anthe-tasks-inbox-heading "Inbox"
  "The top-level heading of the Inbox in `anthe-tasks-inbox-file'.")

(defvar anthe-tasks-log-file (expand-file-name "~/org/roam/Log.org")
  "Where DONE entries are archived, in a date tree.")

(defvar anthe-tasks-carry-heading "Carried over"
  "The heading of today's daily that receives yesterday's open TODOs.")

(defvar anthe-tasks-ignored-tags '("infomaniak" "outlook")
  "Tags not offered after #: the calendars' tags.")

;;; Daily carry-over

(defvar anthe-tasks--carried-on nil
  "The date of the last automatic carry-over, so it runs once a day.")

(defun anthe-tasks--daily-dir ()
  (expand-file-name org-roam-dailies-directory org-roam-directory))

(defun anthe-tasks--daily-file (&optional time)
  (expand-file-name (format-time-string "%Y-%m-%d.org" time) (anthe-tasks--daily-dir)))

(defun anthe-tasks--previous-daily (today-file)
  "The last daily note before TODAY-FILE, or nil."
  (let ((name (file-name-nondirectory today-file)))
    (car (last (seq-filter
                (lambda (f) (string< (file-name-nondirectory f) name))
                (directory-files (file-name-directory today-file) t
                                 "\\`[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}\\.org\\'"))))))

(defun anthe-tasks--ensure-daily (file)
  "Write FILE as a new daily note, as the dailies capture template does."
  (unless (file-exists-p file)
    (with-temp-file file
      (insert (format ":PROPERTIES:\n:ID:       %s\n:END:\n#+title: %s\n#+filetags: @daily\n\n"
                      (org-id-new) (file-name-base file))))))

(defun anthe-tasks--cut-open-subtrees ()
  "Cut the open TODO subtrees of the current buffer and return them.
The outermost ones only: a TODO inside another moves with it."
  (let (trees)
    (org-with-wide-buffer
     (goto-char (point-min))
     (while (re-search-forward org-heading-regexp nil t)
       (beginning-of-line)
       (if (and (org-get-todo-state) (not (org-entry-is-done-p)))
           (let ((end (save-excursion (org-end-of-subtree t t) (point))))
             (push (buffer-substring (point) end) trees)
             (delete-region (point) end))
         (forward-line 1)))
     ;; Leave no empty "Carried over" behind
     (goto-char (point-min))
     (when (re-search-forward (format "^\\* %s[ \t]*$" (regexp-quote anthe-tasks-carry-heading)) nil t)
       (let ((end (save-excursion (org-end-of-subtree t t) (point))))
         (when (string-blank-p (buffer-substring (point) end))
           (delete-region (line-beginning-position) end)))))
    (nreverse trees)))

(defun anthe-tasks--stopped-note (file)
  "The last \"Stopped\" note of FILE as a level-2 subtree, or nil."
  (with-current-buffer (find-file-noselect file)
    (org-with-wide-buffer
     (goto-char (point-max))
     (when (re-search-backward "^\\* Stopped\\b" nil t)
       (let ((text (buffer-substring (point) (save-excursion (org-end-of-subtree t t) (point)))))
         (with-temp-buffer
           (delay-mode-hooks (org-mode))
           (insert text)
           (unless (bolp) (insert "\n"))
           (goto-char (point-min))
           (org-demote-subtree)
           (re-search-forward "Stopped" (line-end-position))
           (insert " on " (file-name-base file))
           (buffer-string)))))))

(defun anthe-tasks--prepare-tree (tree since)
  "TREE at level 2, with :SINCE: (SINCE when not set yet) and :CARRIED: + 1."
  (with-temp-buffer
    (delay-mode-hooks (org-mode))
    (insert tree)
    (unless (bolp) (insert "\n"))
    (goto-char (point-min))
    (while (> (org-current-level) 2) (org-promote-subtree))
    (while (< (org-current-level) 2) (org-demote-subtree))
    (unless (org-entry-get nil "SINCE")
      (org-entry-put nil "SINCE" (format "[%s]" since)))
    (org-entry-put nil "CARRIED"
                   (number-to-string (1+ (string-to-number (or (org-entry-get nil "CARRIED") "0")))))
    (buffer-string)))

(defun anthe-tasks--carry-heading-end ()
  "End of the \"Carried over\" subtree of the current buffer, made if missing."
  (goto-char (point-min))
  (if (re-search-forward (format "^\\* %s[ \t]*$" (regexp-quote anthe-tasks-carry-heading)) nil t)
      (progn (org-end-of-subtree t t)
             (unless (bolp) (insert "\n")))
    ;; Before the first heading, below the file's header
    (if (re-search-forward "^\\*+ " nil t)
        (beginning-of-line)
      (goto-char (point-max))
      (unless (bolp) (insert "\n")))
    (insert "* " anthe-tasks-carry-heading "\n")
    (save-excursion (insert "\n"))))

(defun anthe-tasks-carry-over ()
  "Move the open TODOs of the last daily note to today's, under \"Carried over\".
The last \"Stopped\" note of that day is copied there too."
  (interactive)
  (setq anthe-tasks--carried-on (format-time-string "%F"))
  (let* ((today (anthe-tasks--daily-file))
         (prev (anthe-tasks--previous-daily today)))
    (when prev
      (let* ((prev-buffer (find-file-noselect prev))
             (day (file-name-base prev))
             (stopped (anthe-tasks--stopped-note prev))
             (stopped (and stopped
                           (not (and (file-exists-p today)
                                     (with-current-buffer (find-file-noselect today)
                                       (org-with-wide-buffer
                                        (goto-char (point-min))
                                        (search-forward (concat "Stopped on " day) nil t)))))
                           stopped))
             (trees (with-current-buffer prev-buffer (anthe-tasks--cut-open-subtrees))))
        (when (or trees stopped)
          (anthe-tasks--ensure-daily today)
          (with-current-buffer (find-file-noselect today)
            (org-with-wide-buffer
             (anthe-tasks--carry-heading-end)
             (when stopped (insert stopped))
             (dolist (tree trees)
               (insert (anthe-tasks--prepare-tree tree day))))
            (save-buffer))
          ;; Only once today's note holds them
          (with-current-buffer prev-buffer (save-buffer))
          (message "Carried over from %s: %d TODOs%s" day (length trees)
                   (if stopped " and the Stopped note" "")))))))

(defun anthe-tasks--carry-over-once ()
  "Carry over once a day, from 5:00, so a late night stays on its day."
  (when (and (not (equal anthe-tasks--carried-on (format-time-string "%F")))
             (>= (decoded-time-hour (decode-time)) 5))
    (anthe-tasks-carry-over)))

(defun anthe-tasks--carry-over-advice (&rest _)
  (anthe-tasks-carry-over))

(defun anthe-tasks--carry-over-once-advice (&rest _)
  (anthe-tasks--carry-over-once))

(defvar anthe-tasks--idle-timer nil)

;; Opening or capturing into today's daily always carries over first
(advice-add 'org-roam-dailies-goto-today :before #'anthe-tasks--carry-over-advice)
(advice-add 'org-roam-dailies-capture-today :before #'anthe-tasks--carry-over-advice)
;; The agenda and a minute of idleness do it once a day
(advice-add 'anthe-org-roam-refresh-agenda-list :before #'anthe-tasks--carry-over-once-advice)
(when anthe-tasks--idle-timer (cancel-timer anthe-tasks--idle-timer))
(setq anthe-tasks--idle-timer (run-with-idle-timer 60 t #'anthe-tasks--carry-over-once))

;;; The Stopped note

(add-to-list 'org-roam-dailies-capture-templates
             '("s" "Stopped" entry
               "* Stopped %<%H:%M>\n- Doing: %?\n- Next step: \n- Still open: \n- Waiting on me: \n- First thing tomorrow: \n"
               :target (file+head "%<%Y-%m-%d>.org"
                                  "#+title: %<%Y-%m-%d>\n#+filetags: @daily\n"))
             t)

(defun anthe-tasks-stopped-note ()
  "Write where I stopped in today's daily, then close the laptop."
  (interactive)
  (org-roam-dailies-capture-today nil "s"))

;;; Inbox

(defun anthe-tasks--inbox-rfloc ()
  (with-current-buffer (find-file-noselect anthe-tasks-inbox-file)
    (org-with-wide-buffer
     (goto-char (point-min))
     (unless (re-search-forward (format "^\\* %s\\b" (regexp-quote anthe-tasks-inbox-heading)) nil t)
       (user-error "No \"%s\" heading in %s" anthe-tasks-inbox-heading anthe-tasks-inbox-file))
     (list anthe-tasks-inbox-heading anthe-tasks-inbox-file nil (line-beginning-position)))))

(defun anthe-tasks-to-inbox ()
  "Move the entry at point, or at the agenda line, to the Inbox.
From a daily note, :SINCE: keeps the day it was written."
  (interactive)
  (if (derived-mode-p 'org-agenda-mode)
      (org-agenda-refile nil (anthe-tasks--inbox-rfloc))
    (when (and (anthe-daily--daily-note-p) (not (org-entry-get nil "SINCE")))
      (org-entry-put nil "SINCE" (format "[%s]" (file-name-base (buffer-file-name (buffer-base-buffer))))))
    (org-refile nil nil (anthe-tasks--inbox-rfloc)))
  (message "Moved to the Inbox"))

;;; Tags after #

(defvar anthe-tasks--tags-cache nil
  "(TIME . TAGS), the tags in use, read again after five minutes.")

(defun anthe-tasks--known-tags ()
  "The tags of the agenda files and of the roam notes."
  (if (and anthe-tasks--tags-cache
           (< (float-time (time-since (car anthe-tasks--tags-cache))) 300))
      (cdr anthe-tasks--tags-cache)
    (let ((tags (seq-difference
                 (delete-dups
                  (mapcar #'substring-no-properties
                          (append (mapcar #'car (org-global-tags-completion-table))
                                  (mapcar #'car (org-roam-db-query [:select :distinct tag :from tags])))))
                 anthe-tasks-ignored-tags)))
      (setq anthe-tasks--tags-cache (cons (current-time) (sort tags #'string<)))
      (cdr anthe-tasks--tags-cache))))

(defun anthe-tasks--hashtag-to-tag (tag)
  "Replace #TAG in the heading by the tag TAG."
  (save-excursion
    (when (re-search-backward (concat "[ \t]*#" (regexp-quote tag)) (line-beginning-position) t)
      (replace-match "")
      (org-set-tags (delete-dups (append (org-get-tags nil t) (list tag)))))))

(defun anthe-tasks-hashtag-capf ()
  "Complete a tag after # in a heading."
  (when (and (org-at-heading-p)
             (save-excursion
               (re-search-backward "\\(?:^\\|[ \t]\\)#\\([[:alnum:]_@]*\\)\\=" (line-beginning-position) t)))
    (list (match-beginning 1) (point) (anthe-tasks--known-tags)
          :exclusive 'no
          :company-prefix-length t
          :exit-function (lambda (tag status)
                           (when (memq status '(finished sole exact))
                             (anthe-tasks--hashtag-to-tag tag))))))

(defun anthe-tasks--hashtag-popup ()
  "Offer the tags as soon as # is typed in a heading."
  (when (and (eq last-command-event ?#)
             (org-at-heading-p)
             (memq (char-before (1- (point))) '(?\s ?\t)))
    (if (bound-and-true-p company-mode)
        (company-begin-backend 'company-capf)
      (completion-at-point))))

(defun anthe-tasks--hashtag-setup ()
  (add-hook 'completion-at-point-functions #'anthe-tasks-hashtag-capf -90 t)
  (add-hook 'post-self-insert-hook #'anthe-tasks--hashtag-popup nil t))

(add-hook 'org-mode-hook #'anthe-tasks--hashtag-setup)

;;; Archive to the Log

(setq org-archive-location (concat anthe-tasks-log-file "::datetree/")
      ;; The file's and parents' tags go with the entry, to filter by them
      org-archive-subtree-add-inherited-tags t)

(defun anthe-tasks-archive-done (&optional this-buffer)
  "Archive the DONE and KILL entries of the agenda files into the Log.
The daily notes and the Log keep theirs. With \\[universal-argument], only
the current buffer."
  (interactive "P")
  (let ((files (if this-buffer
                   (list (buffer-file-name (buffer-base-buffer)))
                 (seq-remove (lambda (f)
                               (or (file-in-directory-p f (anthe-tasks--daily-dir))
                                   (file-equal-p f anthe-tasks-log-file)))
                             (org-agenda-files))))
        (count 0))
    (dolist (file files)
      (with-current-buffer (find-file-noselect file)
        (org-map-entries
         (lambda ()
           (org-archive-subtree)
           (setq count (1+ count))
           (setq org-map-continue-from (point)))
         "/DONE|KILL" 'file)
        (save-buffer)))
    (with-current-buffer (find-file-noselect anthe-tasks-log-file) (save-buffer))
    (message "Archived %d entries to the Log" count)))

;;; Done log in the agenda

(defun anthe-tasks--closed-date ()
  "The day the entry at point was closed, for the agenda prefix."
  (let ((closed (org-entry-get nil "CLOSED")))
    (if closed (substring closed 1 11) (make-string 10 ?\s))))

(defun anthe-tasks--closed-of-line (line)
  (let ((marker (get-text-property 0 'org-hd-marker line)))
    (or (and marker (org-entry-get marker "CLOSED")) "")))

(defun anthe-tasks--cmp-closed (a b)
  (let ((ca (anthe-tasks--closed-of-line a))
        (cb (anthe-tasks--closed-of-line b)))
    (cond ((string< ca cb) -1)
          ((string< cb ca) 1))))

(with-eval-after-load 'org-agenda
  (add-to-list 'org-agenda-custom-commands
               '("l" "Done log (s t: by tag)"
                 ((tags "TODO=\"DONE\""
                        ((org-agenda-overriding-header "Done, latest first (s t or \\ filters by tag)")
                         (org-agenda-prefix-format '((tags . " %(anthe-tasks--closed-date)  %-12:c")))
                         (org-agenda-sorting-strategy '((tags user-defined-down)))
                         (org-agenda-cmp-user-defined #'anthe-tasks--cmp-closed)))))
               t))

;;; Skipping a habit

(defun anthe-tasks-skip ()
  "Move a repeating task (a habit) to its next time without marking it done:
nothing is logged, so the habit's graph keeps the day empty."
  (interactive)
  (let ((org-log-repeat nil)
        (org-log-done nil)
        (org-todo-log-states nil))
    (if (derived-mode-p 'org-agenda-mode)
        (org-agenda-todo "DONE")
      (org-todo "DONE")))
  (message "Skipped to the next time"))

;;; Keys

(map! :leader
      :desc "Stopped note" "k n s" #'anthe-tasks-stopped-note
      :desc "Archive all DONE to the Log" "k o A" #'anthe-tasks-archive-done)

(map! :after org
      :map org-mode-map
      :localleader
      :desc "To the Inbox" "r i" #'anthe-tasks-to-inbox
      :desc "Skip to the next time" "d n" #'anthe-tasks-skip)

(map! :after org-agenda
      :map org-agenda-mode-map
      :localleader
      :desc "To the Inbox" "i" #'anthe-tasks-to-inbox
      :desc "Archive to the Log" "A" #'org-agenda-archive-default
      :desc "Skip to the next time" "s" #'anthe-tasks-skip)

(provide 'anthe-tasks)
;;; anthe-tasks.el ends here
