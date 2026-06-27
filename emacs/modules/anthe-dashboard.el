;;; anthe-dashboard.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Maintainer: anthe <anthe@inspiron>
;; Created: May 17, 2026
;; Modified: May 17, 2026
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/anthe/anthe-dashboard
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

;; Customize the dashboard

(use-package dashboard
  :ensure t
  :config
  (dashboard-setup-startup-hook))

;; (setq initial-buffer-choice 'dashboard-open)
;; (add-hook 'server-after-make-frame-hook 'dashboard-open)

(setq dashboard-banner-logo-title "Emacs")
(setq dashboard-display-icons-p t)     ; display icons on both GUI and terminal
(setq dashboard-icon-type 'nerd-icons) ; use `nerd-icons' package
(setq dashboard-set-heading-icons t)
(setq dashboard-set-file-icons t)
(setq dashboard-startup-banner "~/documents/pictures/logo-ascii.txt")
(setq dashboard-center-content t)
(setq dashboard-vertically-center-content t)

(defun get-today-cryolist ()
  (shell-command-to-string "/home/anthe/projects/perso/python/python-utils/python_utils/research/cryolist.py"))

(defun dashboard-insert-cryolist (_)
  (dashboard-insert-heading "   Cryolist:")  
  (let ((content (with-temp-buffer  
                   (get-today-cryolist)
                   (insert-file-contents "~/projects/perso/python/python-utils/python_utils/research/cryolist.txt")
                   (font-lock-ensure)  
                   (buffer-string))))  
    (dolist (line (split-string content "\n"))  
      (insert "\n    " line)))) 


(defun dashboard-insert-research-news (_)  
  (dashboard-insert-heading "   Research news:")  
  (let ((content (with-temp-buffer  
                   (insert-file-contents "~/org/roam/digest/articles_of_the_day.org")  
                   (org-mode)  
                   (font-lock-ensure)  
                   (org-indent-region (point-min) (point-max)) ; Applies Org indentation 
                   (buffer-string))))  
    (dolist (line (split-string content "\n"))  
      (insert "\n    " line)))) 

(defun dashboard-filter-time-no-habits ()
  "Include entries with future scheduled/deadline times, excluding habits."
  (let ((scheduled-time (org-get-scheduled-time (point)))
        (deadline-time (org-get-deadline-time (point)))
        (entry-timestamp (dashboard-agenda--entry-timestamp (point)))
        (due-date (dashboard-due-date-for-agenda))
        (now (current-time)))
    (when (or (member "habit" (org-get-tags))
              (org-entry-is-done-p)
              (org-in-archived-heading-p)
              (not (or (and scheduled-time (time-less-p scheduled-time due-date))
                       (and deadline-time (time-less-p deadline-time due-date))
                       (and entry-timestamp
                            (time-less-p now entry-timestamp)
                            (time-less-p entry-timestamp due-date)))))
      (point))))

(setq dashboard-filter-agenda-entry #'dashboard-filter-time-no-habits)
;; Add the widget to dashboard-items

(setq dashboard-items '((recents   . 5)
                        ;; (bookmarks . 5)
                        (agenda    . 5)
                        (projects  . 5)
                        ;; (registers . 5)
                        ;; (custom   . dashboard-insert-cryolist)
                        ))
(setq dashboard-week-agenda t)
(setq dashboard-agenda-tags-format 'ignore)
(setq dashboard-filter-agenda-entry 'dashboard-filter-agenda-by-time)

(add-to-list 'dashboard-item-generators '(cryolist . dashboard-insert-cryolist))  
(add-to-list 'dashboard-item-generators '(research-news . dashboard-insert-research-news))  

(add-to-list 'dashboard-items '(cryolist . 5) t)  
(add-to-list 'dashboard-items '(research-news . 3) t) 

(setq dashboard-projects-switch-function 'projectile-persp-switch-project)
(setq dashboard-projects-backend 'projectile)
(setq dashboard-show-shortcuts nil)

;; This is helpful as I cannot get dashboard to open agenda files otherwise
;; One can use org-agenda-list, but here I directly display my dashboard
(add-hook 'after-init-hook (lambda () (org-agenda nil "d")))

(setq initial-buffer-choice #'dashboard-open) 
(setq doom-fallback-buffer-name "*dashboard*")

(defun anthe-refresh-dashboard-buffer ()
  (interactive)
  "Refresh the dashboard buffer without switching to it."
  (when-let ((buf (get-buffer "*dashboard*")))
    (save-excursion
      (save-window-excursion
        (with-current-buffer buf
          (dashboard-refresh-buffer))))))

(map! :leader
      (:prefix ("k d" . "dashboard")
       :desc "refrech dashboard buffer" "r" #'anthe-refresh-dashboard-buffer
       :desc "Open dashboard" "o" #'dashboard-open))
;; (run-at-time nil 120 'anthe-refresh-dashboard-buffer)

(provide 'anthe-dashboard)
;;; anthe-dashboard.el ends here
