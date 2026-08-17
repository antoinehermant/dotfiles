;;; anthe-roam.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Maintainer: anthe <anthe@inspiron>
;; Created: February 15, 2026
;; Modified: February 15, 2026
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/anthe/anthe-roam
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(add-to-list 'load-path "~/.config/emacs/.local/straight/repos/org-roam/")
(add-to-list 'load-path "~/.config/emacs/.local/straight/repos/emacsql/")
(add-to-list 'load-path "~/.config/emacs/.local/straight/repos/citar-org-roam/")
(use-package org-roam
  :custom
  (org-roam-directory (file-truename "~/org/roam/"))
  :config
  (org-roam-db-autosync-enable))

(use-package citar-org-roam
  :after (citar org-roam)
  :config (citar-org-roam-mode))

(setq citar-org-roam-note-title-template "${title}, ${author:12}")

(setq citar-org-roam-capture-template-key 'nil)

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

;; Load anthe-roam-journal after org-roam
(use-package anthe-roam-journal
  :after org-roam
  :load-path "~/.dotfiles/emacs/modules/"
  :config
  (setq anthe-roam-journal-directory "journal/"))

;;; Daily mode for quick navigation between daily notes

;; Variable to store the current daily note directory
(defvar anthe-daily--daily-directory "daily/"
  "The directory for daily notes, relative to org-roam-directory.")

;; Keymap for daily-mode
(defvar anthe-daily-mode-map (make-sparse-keymap)
  "Keymap for `anthe-daily-mode'.")

;; Define the keys in the keymap - use C-p and C-n as requested
;; These will override Evil's line navigation when daily-mode is active
(define-key anthe-daily-mode-map (kbd "C-p") #'anthe-daily-goto-previous)
(define-key anthe-daily-mode-map (kbd "C-n") #'anthe-daily-goto-next)

;; For evil-mode users, also define in evil-normal-state to ensure priority
(when (fboundp 'evil-define-key)
  (evil-define-key 'normal anthe-daily-mode-map
    (kbd "C-p") #'anthe-daily-goto-previous
    (kbd "C-n") #'anthe-daily-goto-next))

;;;###autoload
(defun anthe-daily--daily-note-p ()
  "Check if current buffer is a daily note."
  (when-let* ((file (buffer-file-name (buffer-base-buffer)))
              (file (expand-file-name file))
              (org-roam-dir (expand-file-name org-roam-directory))
              (daily-dir (expand-file-name anthe-daily--daily-directory org-roam-dir)))
    (org-roam-descendant-of-p file daily-dir)))

;;;###autoload
(defun anthe-daily--list-daily-files ()
  "List all daily note files sorted by date."
  (let* ((dir (expand-file-name anthe-daily--daily-directory org-roam-directory))
         (files (directory-files-recursively dir "\\.org$")))
    ;; Sort files by date (filename is date.org)
    (sort files
          (lambda (a b)
            (string< (file-name-sans-extension a)
                     (file-name-sans-extension b))))))

;;;###autoload
(defun anthe-daily--find-daily-file-index (file)
  "Find the index of FILE in the sorted list of daily files."
  (let* ((files (anthe-daily--list-daily-files))
         (filename (file-name-nondirectory file)))
    (cl-position-if (lambda (f) (string= (file-name-nondirectory f) filename))
                    files)))

;;;###autoload
(defun anthe-daily-goto-previous ()
  "Go to the previous daily note, closing current buffer."
  (interactive)
  (unless (anthe-daily--daily-note-p)
    (user-error "Not in a daily note"))
  
  (let* ((current-file (buffer-file-name (buffer-base-buffer)))
         (files (anthe-daily--list-daily-files))
         (current-index (anthe-daily--find-daily-file-index current-file)))
    
    (unless current-index
      (user-error "Can't find current note in daily files"))
    
    (if (= current-index 0)
        (user-error "Already at the first daily note")
      
      ;; Kill current buffer
      (save-buffer)
      (kill-current-buffer)
      
      ;; Open previous note
      (let ((previous-file (nth (1- current-index) files)))
        (find-file previous-file)))))

;;;###autoload
(defun anthe-daily-goto-next ()
  "Go to the next daily note, closing current buffer."
  (interactive)
  (unless (anthe-daily--daily-note-p)
    (user-error "Not in a daily note"))
  
  (let* ((current-file (buffer-file-name (buffer-base-buffer)))
         (files (anthe-daily--list-daily-files))
         (current-index (anthe-daily--find-daily-file-index current-file)))
    
    (unless current-index
      (user-error "Can't find current note in daily files"))
    
    (if (= current-index (1- (length files)))
        (user-error "Already at the last daily note")
      
      ;; Kill current buffer
      (save-buffer)
      (kill-current-buffer)
      
      ;; Open next note
      (let ((next-file (nth (1+ current-index) files)))
        (find-file next-file)))))

;; Define the minor mode
(define-minor-mode anthe-daily-mode
  "Minor mode for quick navigation between daily notes.
\n\nThis mode provides C-p and C-n for navigating between daily notes,
overriding their normal behavior (e.g., Evil's line navigation)."
  :lighter " Daily"
  :keymap anthe-daily-mode-map
  :global nil
  
  ;; Add to minor-mode-map-alist to give priority over major mode keymap
  (when anthe-daily-mode
    (or (assq 'anthe-daily-mode minor-mode-map-alist)
        (push `(anthe-daily-mode . ,anthe-daily-mode-map) minor-mode-map-alist))))

;; Enable daily-mode automatically when visiting a daily note
(defun anthe-daily--enable-mode-if-daily ()
  "Enable daily-mode if current buffer is a daily note."
  (when (and (buffer-file-name)
             (anthe-daily--daily-note-p)
             (not anthe-daily-mode))
    (anthe-daily-mode 1)))

;; Also ensure the keymap is in the alist when mode is toggled on
(add-hook 'anthe-daily-mode-hook
          (lambda ()
            (when anthe-daily-mode
              (or (assq 'anthe-daily-mode minor-mode-map-alist)
                  (push `(anthe-daily-mode . ,anthe-daily-mode-map) minor-mode-map-alist)))))

;; Hook into org-mode to enable daily-mode for daily notes
(add-hook 'org-mode-hook #'anthe-daily--enable-mode-if-daily)

;; Also hook into find-file-hook to catch files opened by org-roam-dailies
(add-hook 'find-file-hook
          (lambda ()
            (when (and (buffer-file-name)
                       (anthe-daily--daily-note-p)
                       (not anthe-daily-mode))
              (anthe-daily-mode 1))))

;; Also check when switching buffers
(add-hook 'buffer-list-update-hook
          (lambda ()
            (when (and (buffer-live-p (current-buffer))
                       (derived-mode-p 'org-mode))
              (anthe-daily--enable-mode-if-daily))))

(setq org-roam-dailies-capture-templates
      `(("d" "default" entry
         "* %?"
         :target (file+head "%<%Y-%m-%d>.org"
                            "#+title: %<%Y-%m-%d>\n#+filetags: @daily\n"))
        ("c" "TODO at point" entry
         "* TODO %?\n %a\n"
         :target (file+head "%<%Y-%m-%d>.org"
                            "#+title: %<%Y-%m-%d>\n#+filetags: @daily\n"))
        ("t" "TODO" entry
         "* TODO %?\n"
         :target (file+head "%<%Y-%m-%d>.org"
                            "#+title: %<%Y-%m-%d>\n#+filetags: @daily\n"))))

;; ;;; Custom capture template for daily notes
;; ;; Similar to org-capture but for org-roam-dailies

;; (defcustom anthe-daily-capture-template
;;   "* %?\n  %U\n  %a\n"
;;   "Template for custom daily note capture.

;; This uses the same format as org-capture-templates.
;; Available placeholders:
;;   %? - prompt for input
;;   %U - inactive timestamp
;;   %a - link to current location (org-store-link)
;;   %i - inherited tags
;;   %T - active timestamp
;;   %% - literal %

;; Example: \"* %?\\n  %U\\n  %a\\n\"
;; This will create a heading with your text, a timestamp, and a link to where you were."
;;   :type 'string
;;   :group 'org-roam)

;; (defcustom anthe-daily-capture-heading "Inbox"
;;   "Default heading under which to capture in daily notes."
;;   :type 'string
;;   :group 'org-roam)

;; ;;;###autoload
;; (defun anthe-daily-capture (template &optional heading)
;;   "Capture to today's daily note using a custom TEMPLATE.

;; If HEADING is provided, capture under that heading in the daily note.
;; Otherwise, use `anthe-daily-capture-heading`.

;; This works like org-capture but specifically for org-roam-dailies.
;; The capture buffer will open, you type your note, and when you finish
;; (C-c C-c), it will be added to today's daily note with the template expanded."
;;   (interactive "P")
;;   (let* ((template (or template anthe-daily-capture-template))
;;          (heading (or heading anthe-daily-capture-heading))
;;          (daily-file (expand-file-name
;;                       (format-time-string "%Y-%m-%d.org")
;;                       (expand-file-name org-roam-dailies-directory org-roam-directory))))

;;     ;; Ensure the daily file exists
;;     (unless (file-exists-p daily-file)
;;       (org-roam-dailies-goto-today))

;;     ;; Store the current position for %a placeholder
;;     (when (string-match "%a" template)
;;       (org-store-link-props :to-buffer (current-buffer)))

;;     ;; Create a temporary buffer for capture
;;     (let ((capture-buffer (get-buffer-create "*anthe-daily-capture*"))
;;           (inhibit-quit t))

;;       (with-current-buffer capture-buffer
;;         (erase-buffer)
;;         (org-mode)
;;         (insert (replace-regexp-in-string
;;                  "%?" "" template))
;;         (goto-char (point-min))

;;         ;; Set up the capture buffer
;;         (setq buffer-read-only nil)
;;         (use-local-map (copy-keymap org-mode-map))

;;         ;; Define finish function
;;         (defun anthe-daily--finish-capture ()
;;           (interactive)
;;           (let ((content (buffer-string)))
;;             (kill-buffer capture-buffer)

;;             ;; Expand template placeholders
;;             (setq content
;;                   (replace-regexp-in-string
;;                    "%?" content template))

;;             ;; Handle %U (inactive timestamp)
;;             (setq content
;;                   (replace-regexp-in-string
;;                    "%U" (org-time-stamp-inactive) content))

;;             ;; Handle %T (active timestamp)
;;             (setq content
;;                   (replace-regexp-in-string
;;                    "%T" (org-time-stamp) content))

;;             ;; Handle %a (link to current location)
;;             (when (string-match "%a" content)
;;               (setq content
;;                     (replace-regexp-in-string
;;                      "%a" 
;;                      (or (org-make-link-string) "")
;;                      content)))

;;             ;; Handle %i (inherited tags) - for daily notes, we might not have these
;;             (setq content
;;                   (replace-regexp-in-string
;;                    "%i" "" content))

;;             ;; Handle %% (literal %)
;;             (setq content
;;                   (replace-regexp-in-string
;;                    "%%" "%" content))

;;             ;; Add to daily file
;;             (with-current-buffer (find-file-noselect daily-file)
;;               (save-excursion
;;                 (goto-char (point-max))

;;                 ;; Find or create the heading
;;                 (unless (re-search-backward (format "^\*+ %s" heading) nil t)
;;                   (goto-char (point-max))
;;                   (insert "\n" (make-string (1- (org-current-level)) ?*) " " heading "\n"))

;;                 (goto-char (point-max))
;;                 (insert "\n" content "\n")
;;                 (save-buffer)))

;;             (message "Captured to %s" daily-file)))

;;         ;; Define abort function
;;         (defun anthe-daily--abort-capture ()
;;           (interactive)
;;           (kill-buffer capture-buffer)
;;           (message "Capture aborted"))

;;         ;; Bind keys
;;         (local-set-key (kbd "C-c C-c") #'anthe-daily--finish-capture)
;;         (local-set-key (kbd "C-c C-k") #'anthe-daily--abort-capture)

;;         ;; Switch to capture buffer
;;         (switch-to-buffer capture-buffer)
;;         (goto-char (point-min))))))

;; ;; Keybinding for the custom capture
;; (map! :leader
;;       :desc "Custom daily capture" "n r d c" #'anthe-daily-capture)

(provide 'anthe-roam)
;;; anthe-roam.el ends here
