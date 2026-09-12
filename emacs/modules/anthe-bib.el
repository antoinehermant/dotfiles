;;; anthe-bib.el --- Bibliography management for Emacs -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Maintainer: anthe <anthe@inspiron>
;; Created: February 15, 2026
;; Modified: August 12, 2026
;; Version: 0.2.0
;; Keywords: bibtex, bibliography, doi, research
;; Homepage: https://github.com/anthe/anthe-bib
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  This module provides bibliography management functions that interface
;;  with a Python backend for robust DOI processing, BibTeX entry fetching,
;;  citation key management, and PDF downloading.
;;
;;  Main functions:
;;  - add-doi-to-my-bib: Add a DOI to the bibliography (bound to k c a)
;;  - insert-bibtex-from-doi: Insert BibTeX entry from DOI at point
;;  - clean-bibtex-entry: Format the current BibTeX entry
;;
;;; Code:

;; Configuration variables
(defvar default-bib-download-path "/home/anthe/library/research/papers/"
  "Default directory for downloading PDFs.")

(defvar default-bib "/home/anthe/library/research/research.bib"
  "Default BibTeX file for adding new entries.")


(defun clean-bibtex-entry ()
  "Format the current BibTeX entry without wrapping lines."
  (interactive)
  (save-excursion
    (bibtex-beginning-of-entry)
    (let ((bibtex-align-at-equal-sign t)
          (bibtex-text-indentation 2)
          (bibtex-comma-after-last-field t)
          (bibtex-entry-format '(opts-or-alts required-fields numerical-fields
                                 page-dashes delimiters last-comma
                                 unify-case sort-fields))
          (bibtex-field-delimiters 'braces)
          (fill-column 100000)  ; Set a very large fill-column to prevent wrapping
          (max-field-width 0))
      (bibtex-clean-entry)
      (let ((end (save-excursion (bibtex-end-of-entry) (point))))
        ;; First pass: find the maximum field name width
        (save-excursion
          (while (re-search-forward "^\\s-*\\(\\w+\\)\\s-*=" end t)
            (setq max-field-width (max max-field-width (length (match-string 1))))))
        ;; Second pass: format entries FIXME: commented out because format does not work
        ;; (while (re-search-forward "^\\s-*\\(\\w+\\)\\s-*=" end t)
        ;;   (replace-match (format "  %-*s = " max-field-width (match-string 1))))
        ))))


(defun get-citation-key ()
  "Extract the citation key from the BibTeX entry at point."
  (interactive)
  (save-excursion
    (re-search-backward "^@\\(Article\\|Book\\|InProceedings\\|PhdThesis\\|TechReport\\|Misc\\){\\([^,]*\\)," nil t)
    (match-string 2)))


(defun add-file-entry ()
  "Add a file entry to the BibTeX entry at point using the citation key."
  (interactive)
  (let ((key (get-citation-key)))
    (when key
      (save-excursion
        (newline)
        (insert (format "  file = {:papers/%s.pdf:PDF},\n" key))
        (insert (format "  keywords = {},\n")))))
  (re-search-forward "keywords = {"))


;; Python backend integration

(defun python-check-doi-exists (doi bib-file)
  "Check if DOI exists in BibTeX file using Python."
  (let ((command (format "python3 -m python_utils.research.bibliography check \"%s\" --bib \"%s\" 2>/dev/null"
                         doi bib-file)))
    (string-equal "True" (string-trim (shell-command-to-string command)))))


(defun python-fetch-and-clean-doi (doi bib-file)
  """Fetch BibTeX from DOI, clean it, and generate citation key.
Does NOT add to BibTeX file or download PDF.

Returns a list of (success message citation-key bibtex-entry)."""
  (let* ((command (format "python3 -m python_utils.research.bibliography fetch-clean \"%s\" --bib \"%s\" 2>/dev/null"
                          doi bib-file))
         (result (shell-command-to-string command)))
    ;; Parse the JSON result
    (let ((json-result (json-parse-string result)))
      (list (gethash "success" json-result)
            (gethash "message" json-result)
            (gethash "citation_key" json-result)
            (gethash "bibtex_entry" json-result)))))


(defun python-download-pdf (doi citation-key pdf-dir)
  """Download PDF for DOI in the background."""
  (let ((proc (start-process "bib-pdf-dl" nil "python3" "-m" "python_utils.research.bibliography" "download-pdf" doi citation-key "--pdf-dir" pdf-dir)))
    (set-process-sentinel proc (lambda (p _)
                                 (if (eq (process-exit-status p) 0)
                                     (message "PDF downloaded successfully for %s" citation-key)
                                   (message "PDF download failed for %s" citation-key))))
    (message "Downloading PDF for %s in the background..." citation-key)))


(defun python-extract-references-background (doi citation-key)
  """Extract cited DOIs from a DOI in the background using Python backend."""
  (let ((proc (start-process "bib-ref-extract" nil
                             "python3" "-m" "python_utils.research.bibliography"
                             "extract-references" doi "--key" citation-key)))
    (set-process-sentinel proc (lambda (p _)
                                 (if (eq (process-exit-status p) 0)
                                     (progn
                                       (message "Reference extraction completed for %s" citation-key)
                                       (call-process "notify-send" nil nil nil
                                                     "Reference Extraction"
                                                     (format "Completed for %s" citation-key)))
                                   (message "Reference extraction failed for %s" citation-key)
                                   (call-process "notify-send" nil nil nil
                                                 "Reference Extraction"
                                                 (format "Failed for %s" citation-key)))))
    (message "Starting reference extraction for %s in background..." citation-key)))

(defun insert-bibtex-from-doi (doi)
  """Insert BibTeX entry from DOI at point using Python backend.

Always extracts cited DOIs from the paper in the background."""
  (interactive "sDOI: ")
  (let* ((result (python-fetch-and-clean-doi doi default-bib)))
    
    (let ((success (nth 0 result))
          (message (nth 1 result))
          (citation-key (nth 2 result))
          (bibtex-entry (nth 3 result)))
      
      (if success
          (progn
            (insert bibtex-entry)
            (clean-bibtex-entry)
            (add-file-entry)
            (message "BibTeX entry inserted: %s" citation-key)
            ;; Start PDF download in background
            (python-download-pdf doi citation-key default-bib-download-path)
            ;; Always extract references in background
            (python-extract-references-background doi citation-key))
        (message "Failed to insert BibTeX entry: %s" message)))))


(defun add-file-entry ()
  "Add a file entry to the BibTeX entry at point using the citation key."
  (interactive)
  (let ((key (get-citation-key)))
    (when key
      (save-excursion
        (newline)
        (insert (format "  file = {:papers/%s.pdf:PDF},\n" key))
        (insert (format "  keywords = {},\n")))))
  (re-search-forward "keywords = {"))


;; Python backend integration

(defun python-check-doi-exists (doi bib-file)
  "Check if DOI exists in BibTeX file using Python."
  (let ((command (format "python3 -m python_utils.research.bibliography check \"%s\" --bib \"%s\" 2>/dev/null"
                         doi bib-file)))
    (string-equal "True" (string-trim (shell-command-to-string command)))))


(defun python-fetch-and-clean-doi (doi bib-file)
  """Fetch BibTeX from DOI, clean it, and generate citation key.
Does NOT add to BibTeX file or download PDF.

Returns a list of (success message citation-key bibtex-entry)."""
  (let* ((command (format "python3 -m python_utils.research.bibliography fetch-clean \"%s\" --bib \"%s\" 2>/dev/null"
                          doi bib-file))
         (result (shell-command-to-string command)))
    ;; Parse the JSON result
    (let ((json-result (json-parse-string result)))
      (list (gethash "success" json-result)
            (gethash "message" json-result)
            (gethash "citation_key" json-result)
            (gethash "bibtex_entry" json-result)))))


(defun python-download-pdf (doi citation-key pdf-dir)
  """Download PDF for DOI in the background."""
  (let ((proc (start-process "bib-pdf-dl" nil "python3" "-m" "python_utils.research.bibliography" "download-pdf" doi citation-key "--pdf-dir" pdf-dir)))
    (set-process-sentinel proc (lambda (p _)
                                 (if (eq (process-exit-status p) 0)
                                     (message "PDF downloaded successfully for %s" citation-key)
                                   (message "PDF download failed for %s" citation-key))))
    (message "Downloading PDF for %s in the background..." citation-key)))


(defun python-extract-references-background (doi citation-key)
  """Extract cited DOIs from a DOI in the background using Python backend."""
  (let ((proc (start-process "bib-ref-extract" nil
                             "python3" "-m" "python_utils.research.bibliography"
                             "extract-references" doi "--key" citation-key)))
    (set-process-sentinel proc (lambda (p _)
                                 (if (eq (process-exit-status p) 0)
                                     (progn
                                       (message "Reference extraction completed for %s" citation-key)
                                       (call-process "notify-send" nil nil nil
                                                     "Reference Extraction"
                                                     (format "Completed for %s" citation-key)))
                                   (message "Reference extraction failed for %s" citation-key)
                                   (call-process "notify-send" nil nil nil
                                                 "Reference Extraction"
                                                 (format "Failed for %s" citation-key)))))
    (message "Starting reference extraction for %s in background..." citation-key)))

(defun insert-bibtex-from-doi (doi)
  """Insert BibTeX entry from DOI at point using Python backend.

Always extracts cited DOIs from the paper in the background."""
  (interactive "sDOI: ")
  (let* ((result (python-fetch-and-clean-doi doi default-bib)))
    
    (let ((success (nth 0 result))
          (message (nth 1 result))
          (citation-key (nth 2 result))
          (bibtex-entry (nth 3 result)))
      
      (if success
          (progn
            (insert bibtex-entry)
            (clean-bibtex-entry)
            (add-file-entry)
            (message "BibTeX entry inserted: %s" citation-key)
            ;; Start PDF download in background
            (python-download-pdf doi citation-key default-bib-download-path)
            ;; Always extract references in background
            (python-extract-references-background doi citation-key))
        (message "Failed to insert BibTeX entry: %s" message)))))


(defun add-doi-to-my-bib ()
  """Add a DOI to the default BibTeX file using Python backend.

This is the main function for adding new bibliography entries.
Workflow:
1. Check if DOI already exists - if yes, abort immediately
2. Fetch BibTeX entry from DOI
3. Clean and format the entry
4. Generate a unique citation key (handling duplicates with a, b, c suffixes)
5. Add entry to BibTeX file with file and keywords fields
6. Start PDF download in background
7. Always extract cited references in background

The PDF download and reference extraction run asynchronously so Emacs doesn't freeze."""
  (interactive)
  (let ((doi (read-string "DOI: ")))
    ;; First check if DOI already exists - synchronous, abort if true
    (if (python-check-doi-exists doi default-bib)
        (message "DOI already exists in the BibTeX file!")
      ;; DOI doesn't exist, proceed with processing
      (popper-toggle)
      (let ((buffer (find-file default-bib)))
        (with-current-buffer buffer
          (goto-char (point-max))
          (insert "\n")
          (insert-bibtex-from-doi doi)
          (save-buffer))
        (message "DOI added to the BibTeX file! PDF download started in background.")))))


(defun python-generate-visualization (&optional open-in-browser)
  """Generate citation network visualization HTML file.

If OPEN-IN-BROWSER is non-nil, open the visualization in a web browser."""
  (interactive "P")
  (let* ((command (if open-in-browser
                      "python3 -m python_utils.research.bibliography generate-viz --open 2>/dev/null"
                    "python3 -m python_utils.research.bibliography generate-viz 2>/dev/null"))
         (result (shell-command-to-string command)))
    (message "%s" result)
    (when (string-match "Visualization generated:" result)
      (message "Opening visualization in browser..."))))


(defun view-citation-network ()
  """View the current citation network visualization."""
  (interactive)
  (python-generate-visualization t))


(defun batch-process-bib-entries (&optional limit)
  """Batch process all entries in the BibTeX file to extract references.

If LIMIT is provided, only process that many entries."""
  (interactive "nLimit (0 for all): ")
  (let* ((limit-arg (if (and limit (> limit 0)) limit nil))
         (command (format "python3 /home/anthe/projects/perso/python/python-utils/python_utils/research/batch_process_bib.py %s 2>/dev/null"
                          (if limit-arg (format "--limit %d" limit-arg) "")))
         (result (shell-command-to-string command)))
    (message "%s" result)
    (when (string-match "Batch processing completed successfully" result)
      (message "Batch processing completed! Visualization updated."))))


;; Hooks
(add-hook 'bibtex-mode-hook (lambda () (apheleia-mode -1)))

(defun python-scholar-update-background (&optional days num-articles)
  "Run email summary script in background.
With prefix argument, prompts for DAYS and NUM-ARTICLES.
Otherwise uses defaults (3 days, 5 articles)."
  (interactive
   (if current-prefix-arg
       (list
        (read-number "Days to look back (default 3): " 3)
        (read-number "Number of top articles (default 5): " 5))
     (list 3 5)))
  (let ((proc (start-process "scholar-update" nil
                             "python3" "-m" "python_utils.email.summary"
                             "--days" (number-to-string days)
                             "--num-articles" (number-to-string num-articles))))
    (set-process-sentinel proc
                          (lambda (process event)
                            (if (eq (process-status process) 'exit)
                                (message "Scholar update completed with %d articles from last %d days"
                                         num-articles days)
                              (message "Scholar update process: %s" event)))))
  (anthe-refresh-dashboard-buffer))

(defun python-scholar-update-monday-check ()
  "Run scholar update on Monday at Emacs startup if today's file doesn't exist."
  (interactive)
  (message "In Monday check - day of week: %d" (calendar-day-of-week (current-time)))
  (let ((today-file (format "/home/anthe/org/roam/digest/scholar_updates_%s.org"
                            (format-time-string "%Y-%m-%d"))))
    (message "Today's file: %s, exists: %s" today-file (file-exists-p today-file))
    (when (eq (calendar-day-of-week (current-time)) 1) ; Monday is day 1
      (if (file-exists-p today-file)
          (message "Scholar digest already created for today: %s" today-file)
        (message "Running Monday scholar digest...")
        (python-scholar-update-background 7 5)))))

(add-hook 'after-init-hook 'python-scholar-update-monday-check)

(provide 'anthe-bib)
;;; anthe-bib.el ends here
