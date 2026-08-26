;;; anthe-roam-journal.el --- Journal notes for Org-roam -*- coding: utf-8; lexical-binding: t; -*-

;; Copyright © 2026 anthe

;; Author: anthe <anthe@inspiron>
;; URL: https://github.com/anthe/dotfiles

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; This extension provides functionality for creating journal-notes, or shortly
;; "journal". Journal notes are implemented as a unique node per unique file, where
;; each file named after certain date and stored in `anthe-roam-journal-directory'.
;;
;; Journal notes are automatically tagged with @journal for easy navigation
;; and filtering in org-roam.
;;
;;; Code:
(require 'org-roam)

;;; Faces
(defface anthe-roam-journal-calendar-note
  '((t :inherit (org-link) :underline nil))
  "Face for dates with a journal-note in the calendar."
  :group 'org-roam-faces)

;;; Options
(defcustom anthe-roam-journal-directory "journal/"
  "Path to journal-notes.
This path is relative to `org-roam-directory'."
  :group 'org-roam
  :type 'string)

(defcustom anthe-roam-journal-file-format "%Y.%m.%d.org"
  "File format for journal notes."
  :group 'org-roam
  :type 'string)

(defcustom anthe-roam-journal-date-format "%a, %Y.%m.%d"
  "Date format for journal note titles."
  :group 'org-roam
  :type 'string)

(defcustom anthe-roam-journal-find-file-hook nil
  "Hook that is run right after navigating to a journal-note."
  :group 'org-roam
  :type 'hook)

(defcustom anthe-roam-journal-capture-templates
  `(("j" "default" entry
     "* %?"
     :target (file+head "%<%Y.%m.%d>.org"
                        "#+title: %<%Y.%m.%d>\n#+roam_tags: @journal\n\n")))
  "Capture templates for journal-notes in Org-roam.
Note that for journal files to show up in the calendar, they have to be of format
\"org-time-string.org\".
See `org-roam-capture-templates' for the template documentation."
  :group 'org-roam
  :type 'sexp)

;;; Commands
;;;; Today
;;;###autoload
(defun anthe-roam-journal-capture-today (&optional goto keys)
  "Create an entry in the journal-note for today.
When GOTO is non-nil, go the note without creating an entry.

ELisp programs can set KEYS to a string associated with a template.
In this case, interactive selection will be bypassed."
  (interactive "P")
  (anthe-roam-journal--capture (current-time) goto keys))

;;;###autoload
(defun anthe-roam-journal-goto-today (&optional keys)
  "Find the journal-note for today, creating it if necessary.

ELisp programs can set KEYS to a string associated with a template.
In this case, interactive selection will be bypassed."
  (interactive)
  (anthe-roam-journal-capture-today t keys))

;;;; Tomorrow
;;;###autoload
(defun anthe-roam-journal-capture-tomorrow (n &optional goto keys)
  "Create an entry in the journal-note for tomorrow.

With numeric argument N, use the journal-note N days in the future.

With a `C-u' prefix or when GOTO is non-nil, go the note without
creating an entry.

ELisp programs can set KEYS to a string associated with a template.
In this case, interactive selection will be bypassed."
  (interactive "p")
  (anthe-roam-journal--capture (time-add (* n 86400) (current-time)) goto keys))

;;;###autoload
(defun anthe-roam-journal-goto-tomorrow (n &optional keys)
  "Find the journal-note for tomorrow, creating it if necessary.

With numeric argument N, use the journal-note N days in the
future.

ELisp programs can set KEYS to a string associated with a template.
In this case, interactive selection will be bypassed."
  (interactive "p")
  (anthe-roam-journal-capture-tomorrow n t keys))

;;;; Yesterday
;;;###autoload
(defun anthe-roam-journal-capture-yesterday (n &optional goto keys)
  "Create an entry in the journal-note for yesterday.

With numeric argument N, use the journal-note N days in the past.

When GOTO is non-nil, go the note without creating an entry.

ELisp programs can set KEYS to a string associated with a template.
In this case, interactive selection will be bypassed."
  (interactive "p")
  (anthe-roam-journal--capture (time-subtract (* n 86400) (current-time)) goto keys))

;;;###autoload
(defun anthe-roam-journal-goto-yesterday (n &optional keys)
  "Find the journal-note for yesterday, creating it if necessary.

With numeric argument N, use the journal-note N days in the
past.

ELisp programs can set KEYS to a string associated with a template.
In this case, interactive selection will be bypassed."
  (interactive "p")
  (anthe-roam-journal-capture-yesterday n t keys))

;;;; Date
;;;###autoload
(defun anthe-roam-journal-capture-date (&optional goto prefer-future keys)
  "Create an entry in the journal-note for a date using the calendar.
Prefer past dates, unless PREFER-FUTURE is non-nil.
With a `C-u' prefix or when GOTO is non-nil, go the note without
creating an entry.

ELisp programs can set KEYS to a string associated with a template.
In this case, interactive selection will be bypassed."
  (interactive "P")
  (let ((time (let ((org-read-date-prefer-future prefer-future))
                (org-read-date nil t nil (if goto
                                             "Find journal-note: "
                                           "Capture to journal-note: ")))))
    (anthe-roam-journal--capture time goto keys)))

;;;###autoload
(defun anthe-roam-journal-goto-date (&optional prefer-future keys)
  "Find the journal-note for a date using the calendar, creating it if necessary.
Prefer past dates, unless PREFER-FUTURE is non-nil.

ELisp programs can set KEYS to a string associated with a template.
In this case, interactive selection will be bypassed."
  (interactive)
  (anthe-roam-journal-capture-date t prefer-future keys))

;;;; Navigation
(defun anthe-roam-journal-goto-next-note (&optional n)
  "Find next journal-note.

With numeric argument N, find note N days in the future. If N is
negative, find note N days in the past."
  (interactive "p")
  (unless (anthe-roam-journal--journal-note-p)
    (user-error "Not in a journal-note"))
  (setq n (or n 1))
  (let* ((journals (anthe-roam-journal--list-files))
         (position
          (cl-position-if (lambda (candidate)
                            (string= (buffer-file-name (buffer-base-buffer)) candidate))
                          journals))
         note)
    (unless position
      (user-error "Can't find current note file - have you saved it yet?"))
    (pcase n
      ((pred (natnump))
       (when (eq position (- (length journals) 1))
         (user-error "Already at newest note")))
      ((pred (integerp))
       (when (eq position 0)
         (user-error "Already at oldest note"))))
    (setq note (nth (+ position n) journals))
    (find-file note)
    (run-hooks 'anthe-roam-journal-find-file-hook)))

(defun anthe-roam-journal-goto-previous-note (&optional n)
  "Find previous journal-note.

With numeric argument N, find note N days in the past. If N is
negative, find note N days in the future."
  (interactive "p")
  (let ((n (if n (- n) -1)))
    (anthe-roam-journal-goto-next-note n)))

(defun anthe-roam-journal--list-files (&rest extra-files)
  "List all files in `anthe-roam-journal-directory'.
EXTRA-FILES can be used to append extra files to the list."
  (let ((dir (expand-file-name anthe-roam-journal-directory org-roam-directory))
        (regexp (rx-to-string `(seq (literal ".") (or ,@org-roam-file-extensions) eos))))
    (append (seq-remove (lambda (file)
                          (let ((name (file-name-nondirectory file)))
                            (or (auto-save-file-name-p name)
                                (backup-file-name-p name)
                                (string-match "^\\." name))))
                        (directory-files-recursively dir regexp))
            extra-files)))

(defun anthe-roam-journal--journal-note-p (&optional file)
  "Return t if FILE is an anthe-roam journal-note, nil otherwise.
If FILE is not specified, use the current buffer's file-path."
  (when-let* ((path (expand-file-name
                     (or file
                         (buffer-file-name (buffer-base-buffer)))))
              (directory (expand-file-name anthe-roam-journal-directory org-roam-directory)))
    (setq path (expand-file-name path))
    (save-match-data
      (and
       (org-roam-file-p path)
       (org-roam-descendant-of-p path directory)))))

;;;###autoload
(defun anthe-roam-journal-find-directory ()
  "Find and open `anthe-roam-journal-directory'."
  (interactive)
  (find-file (expand-file-name anthe-roam-journal-directory org-roam-directory)))

;;; Calendar integration
(defun anthe-roam-journal-calendar--file-to-date (file)
  "Convert FILE to date.
Return (MONTH DAY YEAR) or nil if not an Org time-string."
  (ignore-errors
    (cl-destructuring-bind (_ _ _ d m y _ _ _)
        (org-parse-time-string
         (file-name-sans-extension
          (file-name-nondirectory file)))
      (list m d y))))

(defun anthe-roam-journal-calendar-mark-entries ()
  "Mark days in the calendar for which a journal-note is present."
  (when (file-exists-p (expand-file-name anthe-roam-journal-directory org-roam-directory))
    (dolist (date (remove nil
                          (mapcar #'anthe-roam-journal-calendar--file-to-date
                                  (anthe-roam-journal--list-files))))
      (when (calendar-date-is-visible-p date)
        (calendar-mark-visible-date date 'anthe-roam-journal-calendar-note)))))

(add-hook 'calendar-today-visible-hook #'anthe-roam-journal-calendar-mark-entries)
(add-hook 'calendar-today-invisible-hook #'anthe-roam-journal-calendar-mark-entries)

;;; Capture implementation
(add-to-list 'org-roam-capture--template-keywords :override-default-time)

(defun anthe-roam-journal--capture (time &optional goto keys)
  "Capture an entry in a journal-note for TIME, creating it if necessary.
When GOTO is non-nil, go the note without creating an entry.

ELisp programs can set KEYS to a string associated with a template.
In this case, interactive selection will be bypassed."
  (let ((org-roam-directory (expand-file-name anthe-roam-journal-directory org-roam-directory))
        (anthe-roam-journal-directory "./"))
    (org-roam-capture- :goto (when goto '(4))
                       :keys keys
                       :node (org-roam-node-create)
                       :templates anthe-roam-journal-capture-templates
                       :props (list :override-default-time time))
    (when goto (run-hooks 'anthe-roam-journal-find-file-hook))))

(add-hook 'org-roam-capture-preface-hook #'anthe-roam-journal--override-capture-time-h)

(defun anthe-roam-journal--override-capture-time-h ()
  "Override the `:default-time' with the time from `:override-default-time'."
  (when (org-roam-capture--get :override-default-time)
    (org-capture-put :default-time (org-roam-capture--get :override-default-time)))
  nil)

;;; Bindings
(defvar anthe-roam-journal-map (make-sparse-keymap)
  "Keymap for `anthe-roam-journal'.")

(define-prefix-command 'anthe-roam-journal-map)

(define-key anthe-roam-journal-map (kbd "d") #'anthe-roam-journal-goto-today)
(define-key anthe-roam-journal-map (kbd "y") #'anthe-roam-journal-goto-yesterday)
(define-key anthe-roam-journal-map (kbd "t") #'anthe-roam-journal-goto-tomorrow)
(define-key anthe-roam-journal-map (kbd "n") #'anthe-roam-journal-capture-today)
(define-key anthe-roam-journal-map (kbd "f") #'anthe-roam-journal-goto-next-note)
(define-key anthe-roam-journal-map (kbd "b") #'anthe-roam-journal-goto-previous-note)
(define-key anthe-roam-journal-map (kbd "c") #'anthe-roam-journal-goto-date)
(define-key anthe-roam-journal-map (kbd "v") #'anthe-roam-journal-capture-date)
(define-key anthe-roam-journal-map (kbd ".") #'anthe-roam-journal-find-directory)

;;; Keybindings
(map! :leader
      :desc "Journal goto date" "n r j d" #'anthe-roam-journal-goto-date
      :desc "Journal capture date" "n r j D" #'anthe-roam-journal-capture-date
      :desc "Journal yesterday" "n r j y" #'anthe-roam-journal-goto-yesterday
      :desc "Journal capture yesterday" "n r j Y" #'anthe-roam-journal-capture-yesterday
      :desc "Journal tomorrow" "n r j m" #'anthe-roam-journal-goto-tomorrow
      :desc "Journal capture tomorrow" "n r j m" #'anthe-roam-journal-goto-tomorrow
      :desc "Journal goto today" "n r j t" #'anthe-roam-journal-goto-today
      :desc "Journal capture today" "n r j n" #'anthe-roam-journal-capture-today
      :desc "Journal next note" "n r j f" #'anthe-roam-journal-goto-next-note
      :desc "Journal previous note" "n r j b" #'anthe-roam-journal-goto-previous-note
      :desc "Journal directory" "n r j -" #'anthe-roam-journal-find-directory
      ;; :desc "Migrate journal files" "n r j m" #'anthe-roam-journal-migrate-existing-files
      )

;;; Migration function for existing journal files
(defun anthe-roam-journal--add-id-and-title-to-file (file)
  "Add ID property and title to FILE if they don't exist."
  (when (file-exists-p file)
    (with-current-buffer (find-file-noselect file)
      (save-excursion
        (goto-char (point-min))
        
        ;; Check if file already has an ID
        (unless (re-search-forward "^:ID:" nil t)
          (goto-char (point-min))
          
          ;; Insert ID property at the beginning
          (insert ":PROPERTIES:\n:ID:       "
                  (org-id-new) "\n:END:\n\n")
          
          ;; Save the buffer to write changes
          (save-buffer))
        
        ;; Check if file already has a title
        (goto-char (point-min))
        (unless (re-search-forward "^#+title:" nil t)
          (goto-char (point-min))
          
          ;; Extract date from filename (format: 2025.08.04.org)
          (let* ((filename (file-name-nondirectory file))
                 (date-str (file-name-sans-extension filename))
                 (title (format "%s" date-str)))
            
            ;; Check if there's already a title heading
            (if (re-search-forward "^\* .*" nil t)
                (progn
                  (beginning-of-line)
                  (insert "#+title: " title "\n#+roam_tags: @journal\n\n")
                  (save-buffer))
              ;; No title heading found, add at beginning
              (goto-char (point-min))
              (insert "#+title: " title "\n#+roam_tags: @journal\n\n")
              (save-buffer))))))))

;;;###autoload
(defun anthe-roam-journal-migrate-existing-files ()
  "Add ID properties and titles to all existing journal files.
This makes them visible to org-roam."
  (interactive)
  (let* ((dir (expand-file-name anthe-roam-journal-directory org-roam-directory))
         (files (directory-files-recursively dir "\\.org$")))
    (dolist (file files)
      (message "Processing: %s" file)
      (anthe-roam-journal--add-id-and-title-to-file file))
    (message "Migration complete! %d files processed." (length files))))

;;; Journal mode for quick navigation between journal notes
;; This provides similar functionality to daily-mode but for journal notes

;; Keymap for journal-mode
(defvar anthe-roam-journal-mode-map (make-sparse-keymap)
  "Keymap for `anthe-roam-journal-mode'.")

;; Define dedicated functions for journal mode that close current buffer
(defun anthe-roam-journal--goto-previous-and-close ()
  "Go to the previous journal note, closing current buffer."
  (interactive)
  (unless (anthe-roam-journal--journal-note-p)
    (user-error "Not in a journal note"))
  
  (let* ((current-file (buffer-file-name (buffer-base-buffer)))
         (journals (anthe-roam-journal--list-files))
         (current-index (cl-position-if (lambda (candidate)
                                          (string= (file-name-nondirectory candidate)
                                                   (file-name-nondirectory current-file)))
                                        journals)))
    
    (unless current-index
      (user-error "Can't find current note in journal files"))
    
    (if (= current-index 0)
        (user-error "Already at the first journal note")
      
      ;; Kill current buffer
      (save-buffer)
      (kill-current-buffer)
      
      ;; Open previous note
      (let ((previous-file (nth (1- current-index) journals)))
        (find-file previous-file)))))

(defun anthe-roam-journal--goto-next-and-close ()
  "Go to the next journal note, closing current buffer."
  (interactive)
  (unless (anthe-roam-journal--journal-note-p)
    (user-error "Not in a journal note"))
  
  (let* ((current-file (buffer-file-name (buffer-base-buffer)))
         (journals (anthe-roam-journal--list-files))
         (current-index (cl-position-if (lambda (candidate)
                                          (string= (file-name-nondirectory candidate)
                                                   (file-name-nondirectory current-file)))
                                        journals)))
    
    (unless current-index
      (user-error "Can't find current note in journal files"))
    
    (if (= current-index (1- (length journals)))
        (user-error "Already at the last journal note")
      
      ;; Kill current buffer
      (save-buffer)
      (kill-current-buffer)
      
      ;; Open next note
      (let ((next-file (nth (1+ current-index) journals)))
        (find-file next-file)))))

;; Define the keys in the keymap - use C-p and C-n
(define-key anthe-roam-journal-mode-map (kbd "C-p") #'anthe-roam-journal--goto-previous-and-close)
(define-key anthe-roam-journal-mode-map (kbd "C-n") #'anthe-roam-journal--goto-next-and-close)

;; For evil-mode users, also define in evil-normal-state
(when (fboundp 'evil-define-key)
  (evil-define-key 'normal anthe-roam-journal-mode-map
    (kbd "C-p") #'anthe-roam-journal--goto-previous-and-close
    (kbd "C-n") #'anthe-roam-journal--goto-next-and-close))

;; Define the minor mode
(define-minor-mode anthe-roam-journal-mode
  "Minor mode for quick navigation between journal notes.

This mode provides C-p and C-n for navigating between journal notes,
overriding their normal behavior (e.g., Evil's line navigation)."
  :lighter " Journal"
  :keymap anthe-roam-journal-mode-map
  :global nil
  
  ;; Add to minor-mode-map-alist to give priority over major mode keymap
  (when anthe-roam-journal-mode
    (or (assq 'anthe-roam-journal-mode minor-mode-map-alist)
        (push `(anthe-roam-journal-mode . ,anthe-roam-journal-mode-map) minor-mode-map-alist))))

;; Enable journal-mode automatically when visiting a journal note
(defun anthe-roam-journal--enable-mode-if-journal ()
  "Enable journal-mode if current buffer is a journal note."
  (when (and (buffer-file-name)
             (anthe-roam-journal--journal-note-p)
             (not anthe-roam-journal-mode))
    (anthe-roam-journal-mode 1)))

;; Also ensure the keymap is in the alist when mode is toggled on
(add-hook 'anthe-roam-journal-mode-hook
          (lambda ()
            (when anthe-roam-journal-mode
              (or (assq 'anthe-roam-journal-mode minor-mode-map-alist)
                  (push `(anthe-roam-journal-mode . ,anthe-roam-journal-mode-map) minor-mode-map-alist)))))

;; Hook into org-mode to enable journal-mode for journal notes
(add-hook 'org-mode-hook #'anthe-roam-journal--enable-mode-if-journal)

;; Also hook into find-file-hook to catch files opened directly
(add-hook 'find-file-hook
          (lambda ()
            (when (and (buffer-file-name)
                       (anthe-roam-journal--journal-note-p)
                       (not anthe-roam-journal-mode))
              (anthe-roam-journal-mode 1))))

;; Also check when switching buffers
(add-hook 'buffer-list-update-hook
          (lambda ()
            (when (and (buffer-live-p (current-buffer))
                       (derived-mode-p 'org-mode))
              (anthe-roam-journal--enable-mode-if-journal))))

(provide 'anthe-roam-journal)
;;; anthe-roam-journal.el ends here
