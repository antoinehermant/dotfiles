;;; anthe-bib.el --- Bibliography management for Emacs -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Maintainer: anthe <anthe@inspiron>
;; Created: February 15, 2026
;; Modified: August 10, 2026
;; Version: 0.1.0
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

(defun python-process-doi (doi bib-file pdf-dir)
  "Call Python bibliography manager to process a DOI.
This function calls the Python bibliography manager which handles:
- Fetching BibTeX from DOI
- Cleaning the entry
- Generating unique citation keys (Author_YYYYa, Author_YYYYb, etc.)
- Adding to BibTeX file
- Downloading PDF

Returns a list of (success message citation-key bibtex-entry pdf-path)."
  (let* ((command (format "python3 -m python_utils.research.bibliography process \"%s\" --bib \"%s\" --pdf-dir \"%s\" 2>/dev/null"
                          doi bib-file pdf-dir))
         (result (shell-command-to-string command)))
    ;; Parse the JSON result
    (let ((json-result (json-parse-string result)))
      (list (gethash "success" json-result)
            (gethash "message" json-result)
            (gethash "citation_key" json-result)
            (gethash "bibtex_entry" json-result)
            (gethash "pdf_path" json-result)))))


(defun python-check-doi-exists (doi bib-file)
  "Check if DOI exists in BibTeX file using Python."
  (let ((command (format "python3 -m python_utils.research.bibliography check \"%s\" --bib \"%s\" 2>/dev/null"
                         doi bib-file)))
    (string-equal "True" (string-trim (shell-command-to-string command)))))


(defun insert-bibtex-from-doi (doi)
  "Insert BibTeX entry from DOI at point using Python backend."
  (interactive "sDOI: ")
  (let* ((url (if (string-prefix-p "https://doi.org/" doi)
                  doi
                (concat "https://doi.org/" doi)))
         (result (python-process-doi doi default-bib default-bib-download-path)))
    
    (let ((success (nth 0 result))
          (message (nth 1 result))
          (citation-key (nth 2 result))
          (bibtex-entry (nth 3 result))
          (pdf-path (nth 4 result)))
      
      (if success
          (progn
            (insert bibtex-entry)
            (clean-bibtex-entry)
            (message "BibTeX entry inserted: %s" citation-key))
        (message "Failed to insert BibTeX entry: %s" message)))))


(defun add-doi-to-my-bib ()
  "Add a DOI to the default BibTeX file using Python backend.

This is the main function for adding new bibliography entries.
It will:
1. Check if DOI already exists
2. Fetch BibTeX entry from DOI
3. Clean and format the entry
4. Generate a unique citation key (handling duplicates with a, b, c suffixes)
5. Add entry to BibTeX file
6. Download PDF
7. Add file and keywords fields"
  (interactive)
  (let ((doi (read-string "DOI: ")))
    (if (python-check-doi-exists doi default-bib)
        (message "DOI already exists in the BibTeX file!")
      (popper-toggle)
      (let ((buffer (find-file default-bib)))
        (with-current-buffer buffer
          (goto-char (point-max))
          (insert "\n")
          (insert-bibtex-from-doi doi)
          (save-buffer))
        (message "DOI added to the BibTeX file!")))))


;; Keybindings
(map! :leader
      :desc "Add doi to my bib" "k c a" #'add-doi-to-my-bib)

;; Hooks
(add-hook 'bibtex-mode-hook (lambda () (apheleia-mode -1)))

(provide 'anthe-bib)
;;; anthe-bib.el ends here
