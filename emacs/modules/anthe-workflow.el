;;; anthe-workflow.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Maintainer: anthe <anthe@inspiron>
;; Created: February 15, 2026
;; Modified: February 15, 2026
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/anthe/anthe-org
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.

;;; Commentary:
;;
;;  Description
;;
;;; Code:

(require 'org)
;; (defun diary-last-day-of-month (date)
;;   "Return `t` if DATE is the last day of the month."
;;   (let* ((day (calendar-extract-day date))
;;          (month (calendar-extract-month date))
;;          (year (calendar-extract-year date))
;;          (last-day-of-month
;;           (calendar-last-day-of-month month year)))
;;     (= day last-day-of-month)))

;; (defun my/set-org-agenda-files ()
;;   (setq org-agenda-files (append (directory-files-recursively "~/org/org/agenda/" "\\.org$"))))

(use-package org
  :config
  (setq org-directory "~/org/org/")
  ;; (setq org-agenda-files  ("~/org/agenda/" "~/org/phd/"))
  (setq org-agenda-start-with-log-mode t)
  ;; (setq org-todo-keywords
  ;;   '((sequence "TODO(t)" "NEXT(n)" "|" "DONE(d!)")
  ;;     (sequence "BACKLOG(b)" "PLAN(p)" "READY(r)" "ACTIVE(a)" "REVIEW(v)" "WAIT(w@/!)" "HOLD(h)" "|" "COMPLETED(c)" "CANC(k@)")))
  ;; (setq org-agenda-files (append (directory-files-recursively "~/org/org/agenda/" "\\.org$")))
  ;; (add-hook 'org-agenda-mode-hook 'my/set-org-agenda-files)


  ;; Stolen from system crafters to use org roam for org agenda files but only files with specific tag
  (defun anthe-org-roam-filter-by-tags (tag-list)
    (lambda (node)
      (seq-some (lambda (tag) (member tag (org-roam-node-tags node))) tag-list)))

  (defun anthe-org-roam-list-notes-by-tag (tag-list)
    (mapcar #'org-roam-node-file
            (seq-filter
             (anthe-org-roam-filter-by-tags tag-list)
             (org-roam-node-list))))

  (defun anthe-org-roam-refresh-agenda-list (&optional tags)
    (interactive)
    (let ((tags-list (or tags '("ice_core" "roadmap" "agenda" "todo" "phd" "project" "training"))))
      (setq org-agenda-files (anthe-org-roam-list-notes-by-tag tags-list))
      (add-to-list 'org-agenda-files (expand-file-name "~/org/calendar.org"))
      (add-to-list 'org-agenda-files (expand-file-name (format-time-string "%Y-%m-%d.org") "~/org/roam/daily/"))
      (add-to-list 'org-agenda-files (expand-file-name (format-time-string "%Y-%m-%d.org" (time-subtract (current-time) (days-to-time 1))) "~/org/roam/daily/"))))
  
  ;; Build the agenda list the first time for the session
  (anthe-org-roam-refresh-agenda-list)

  (add-hook 'org-agenda-mode-hook 'anthe-org-roam-refresh-agenda-list)

  (require 'org-habit)
  (add-to-list 'org-modules 'org-habit)
  (setq org-habit-graph-column 60)

  (evil-set-initial-state 'org-agenda-mode 'motion)

  (setq org-capture-templates
        `(("t" "Tasks / Projects")
          ("ti" "Inbox" entry (file+olp"~/org/roam/Tasks.org" "Inbox")
           "* TODO %?\n  %U\n  %i" :empty-lines 1)
          ("tw" "Work / PhD" entry (file+olp"~/org/roam/PhDRoadmap.org" "TODOLIST")
           "* TODO %?\n  %U\n  %i" :empty-lines 1)
          ("tp" "Perso" entry (file+olp"~/org/roam/Tasks.org" "Perso")
           "* TODO %?\n  %U\n  %i" :empty-lines 1)
          ("te" "Emacs" entry (file+olp"~/org/roam/Emacs.org" "TODOLIST")
           "* TODO %?\n  %U\n  %a\n  %i" :empty-lines 1)
          ;; ("e" "Events" entry (file+olp "~/org/roam/Events.org" "Calendar")
          ;;  "* %?\n %i" :empty-line 1)
          ))

  (setq org-agenda-skip-scheduled-if-done t)

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
                     (org-agenda-span (- 8  (string-to-number (format-time-string "%u"))))
                     (org-agenda-start-on-weekday nil)
                     ;; (org-agenda-start-day "0")
                     ;; (org-agenda-skip-function
                     ;; '(org-agenda-skip-entry-if 'regexp ":habit:"))
                     ))
            ;; (tags-todo "+habit" ;; FIXME: I could'nt make move habits to a specfic section because it shows it as regular task, not habit with the tracker
            ;;   ((org-agenda-overriding-header "Habits")))
            (tags-todo "@daily" ((org-agenda-overriding-header "Daily Notes")))
            (tags-todo "inbox" ((org-agenda-overriding-header "Inbox")))
            (tags-todo "phd/TODO"
                       ((org-agenda-overriding-header "PhD Tasks")
                        (org-agenda-todo-ignore-deadlines 'far)))
            (tags-todo "+perso-habit" ((org-agenda-overriding-header "Personal Tasks")))
            (tags-todo "+piano" ((org-agenda-overriding-header "Piano")))
            (tags-todo "+emacs" ((org-agenda-overriding-header "Emacs Project")))))

          ;; ("n" "Next Tasks"
          ;;  ((todo "NEXT"
          ;;     ((org-agenda-overriding-header "Next Tasks")))))

          ;; ("W" "Work Tasks" tags-todo "+work-emacs")

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
           (
            ;; (tags-todo "+dailies+SCHEDULED<=\"<today>+1\"")
            (anthe-org-roam-refresh-agenda-list '("phd" "calendar"))
            (agenda "" ((org-agenda-start-day "0d")
                        (org-agenda-span 7)
                        (org-agenda-sorting-strategy
                         (quote ((agenda time-up priority-down tag-up))))))
            (tags-todo "@daily" ((org-agenda-overriding-header "Daily Notes")))
            (tags-todo "LEVEL=999" ((org-agenda-overriding-header "Active Projects")))
            (tags-todo "phd+ice_core/TODO" ((org-agenda-overriding-header "  Ice Core")
                                            (org-agenda-compact-blocks t)))
            (tags-todo "phd+database/TODO" ((org-agenda-overriding-header "  AntADatabase")
                                            (org-agenda-compact-blocks t)))
            (tags-todo "phd/PROJ"
                       ((org-agenda-span 7)
                        (org-agenda-overriding-header "Project Tasks")))
            (tags-todo "phd/IDEA"
                       ((org-agenda-span 7)
                        (org-agenda-overriding-header "Idea Tasks")))
            (tags-todo "phd+admin"
                       ((org-agenda-span 7)
                        (org-agenda-overriding-header "Idea Tasks"))))
           ;; ((org-agenda-category-filter-preset '("+calendar" "+PhD")))
           )

          ;; Low-effort next actions
          ("e" tags-todo "+TODO=\"NEXT\"+Effort<15&+Effort>0"
           ((org-agenda-overriding-header "Low Effort Tasks")
            (org-agenda-max-todos 20)
            (org-agenda-files org-agenda-files)))))
  )

;; (add-to-list 'load-path "~/.config/emacs/.local/elpa/org-wild-notifier-20260127.533/")
(add-to-list 'load-path "~/.config/emacs/.local/elpa/alert-20260316.2025/")
(use-package org-wild-notifier)

(setq org-wild-notifier-alert-time '(0 10 30)) 
(setq org-wild-notifier-alert-times-property "NOTIF") 

(setq alert-default-style 'notifications)
(org-wild-notifier-mode)
(add-to-list 'org-default-properties "NOTIF")

;; (custom-set-faces!
;;   '(org-scheduled-today :foreground "ffb454", :slant bold)
;; )


;; (add-to-list 'load-path "~/.config/emacs/.local/straight/repos/org-journal/")
(use-package org-journal)
(setq org-journal-date-format "%a, %Y.%m.%d"
      org-journal-file-format "%Y.%m.%d.org")
(setq org-journal-dir "~/org/roam/journal")
(map! :leader
      :desc "Open current journal file" "n j o" #'org-journal-open-current-journal-file)

;; (add-to-list 'load-path "~/.config/emacs/.local/elpa/org-vcard-20250828.809/")
;; (add-to-list 'load-path "~/.config/emacs/.local/elpa/org-contacts-20260221.852/")
;; (require 'org-vcard)
;; (require 'org-contacts)
;; (org-vcard-import-directory "~/documents/contacts/66d789c6-a165-408a-a658-5ed3d7170583" "~/org/contacts.org")

;; (setq org-contacts-directory '"~/org/org/contacts/")
;; (setq org-contacts-files '("~/org/org/contacts/test.org"))

(use-package khalel
  :after org
  :config
  ;; Import events in org
  (khalel-add-capture-template)
  (setq khalel-capture-key "e")
  (setq khalel-import-org-file (expand-file-name "~/org/calendar.org"))
  (setq khalel-import-start-date "-365")
  (setq khalel-import-end-date "+365d")
  (setq khalel-import-org-file-confirm-overwrite nil)
  (setq khalel-default-calendar "infomaniak")
  (setq khalel-run-vdirsyncer-after-capture t)
  (setq khalel-import-org-file-header "#+TITLE: khalel imported calendar events\n\n#+COLUMNS: %ITEM %TIMESTAMP %LOCATION %CALENDAR\n\n")
  )

(defun anthe/import-birthday-events ()
  "Import birthdays via `khalel-import-events` in a specific birthday.org."
  (interactive)
  (let ((current-prefix-arg '(4))
        (khalel-default-calendar "birthdays")
        (khalel-import-org-file (concat org-directory "birthdays.org")))
    (call-interactively #'khalel-import-events)))

(defun khalel-run-vdirsyncer-silent ()
  "Run vdirsyncer silently in background and import events."
  (interactive)
  (let ((vdirsyncer (or khalel-vdirsyncer-command
                        (executable-find "vdirsyncer")))
        (buf (get-buffer-create " *khalel-vdirsyncer-silent*")))
    (make-process
     :name "khalel-vdirsyncer-silent"
     :buffer buf
     :noquery t
     :command (remq nil (flatten-list
                         `(,vdirsyncer
                           ,@(when khalel-vdirsyncer-extra-options
                               (split-string khalel-vdirsyncer-extra-options))
                           "sync"
                           ,@(when khalel-vdirsyncer-collections
                               (split-string khalel-vdirsyncer-collections)))))
     :sentinel (lambda (p e)
                 (when (and (eq 'exit (process-status p))
                            (zerop (process-exit-status p)))
                   (when khalel-import-events-after-vdirsyncer
                     (khalel-import-events)))
                 (kill-buffer buf)))))

;; (run-at-time nil 600 'khalel-run-vdirsyncer-silent)

;; (add-to-list 'load-path "~/.config/emacs/.local/elpa/org-caldav-20260501.8/")
;; (require 'org-caldav)

;; ;; URL of the caldav server
;; (setq org-caldav-url "https://sync.infomaniak.com/calendars/AH07332")

;; ;; calendar ID on server
;; (setq org-caldav-calendar-id "8f599f55-213b-43b2-a84f-ba16a2aa36f6")

;; ;; Org filename where new entries from calendar stored
;; (setq org-caldav-inbox "~/org/calendar.org")

;; ;; Additional Org files to check for calendar events
;; (setq org-caldav-files nil)

;; ;; Usually a good idea to set the timezone manually
;; (setq org-icalendar-timezone "Europe/Berlin")

(map! :leader
      :desc "Add doi to my bib" "k c a" #'add-doi-to-my-bib
      :desc "View citation network" "k c v" #'view-citation-network
      :desc "Batch process bib entries" "k c b" #'batch-process-bib-entries
      :desc "Goto today's notes" "k n d" (lambda () (interactive) (org-roam-dailies-goto-today "d"))
      :desc "Goto today's journal" "k n j" #'anthe-roam-journal-goto-today
      :desc "Org capture" "k x" #'org-capture
      :desc "Org Agenda" "k a" #'org-agenda)

(provide 'anthe-workflow)
;;; anthe-workflow.el ends here
