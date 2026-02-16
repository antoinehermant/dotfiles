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
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(require 'org)
(defun diary-last-day-of-month (date)
"Return `t` if DATE is the last day of the month."
  (let* ((day (calendar-extract-day date))
         (month (calendar-extract-month date))
         (year (calendar-extract-year date))
         (last-day-of-month
            (calendar-last-day-of-month month year)))
    (= day last-day-of-month)))

(defun my/set-org-agenda-files ()
  (setq org-agenda-files (append (directory-files-recursively "~/org/org/agenda/" "\\.org$"))))

(use-package org
  :config
  (setq org-directory "~/org/org/")
  (setq org-agenda-files (append (directory-files-recursively "~/org/org/agenda/" "\\.org$")))
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
    ("tt" "Inbox" entry (file+olp"~/org/org/agenda/tasks.org" "Inbox")
         "* TODO %?\n  %U\n  %i" :empty-lines 1)
    ("tw" "Work / PhD" entry (file+olp"~/org/org/agenda/tasks.org" "PhD")
         "* TODO %?\n  %U\n  %i" :empty-lines 1)
    ("tp" "Perso" entry (file+olp"~/org/org/agenda/tasks.org" "Perso")
         "* TODO %?\n  %U\n  %i" :empty-lines 1)
    ("te" "Emacs" entry (file+olp"~/org/org/agenda/tasks.org" "Emacs")
         "* TODO %?\n  %U\n  %a\n  %i" :empty-lines 1)
    ("e" "Events" entry (file+olp "~/org/org/agenda/events.org" "Calendar")
       "* %?\n %i" :empty-line 1)))

(map! :leader
      :desc "Agenda Dashbord" "k d" #'(lambda (&optional arg) (interactive "P")(org-agenda arg "d"))
      :desc "Agenda Dashbord" "k w" #'(lambda (&optional arg) (interactive "P")(org-agenda arg "w")))


(add-to-list 'load-path "~/.config/emacs/.local/straight/repos/org-journal/")
(use-package! org-journal)
(setq org-journal-date-format "%a, %d.%m.%Y"
      org-journal-file-format "%d.%m.%Y.org")

(provide 'anthe-workflow)
;;; anthe-workflow.el ends here
