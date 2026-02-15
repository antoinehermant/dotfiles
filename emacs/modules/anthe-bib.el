;;; anthe-bib.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Maintainer: anthe <anthe@inspiron>
;; Created: February 15, 2026
;; Modified: February 15, 2026
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/anthe/anthe-bib
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(defun clean-bibtex-entry()
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
        ;; Second pass: format entries FIXME: commneted out because format does not work
        ;; (while (re-search-forward "^\\s-*\\(\\w+\\)\\s-*=" end t)
        ;;   (replace-match (format "  %-*s = " max-field-width (match-string 1))))
        ))))

(defun add-file-entry ()
  "Add a file entry to the BibTeX entry at point using the citation key."
  (interactive)
  (let ((key (get-citation-key)))
    (when key
      (save-excursion
        ;; (search-forward (concat "}") nil t)
        ;; (beginning-of-line)
        ;; (forward-line 1)
        (newline)
        (insert (format "  file = {:papers/%s.pdf:PDF},\n" key))
        (insert (format "  keywords = {},\n")))))
  (re-search-forward "keywords = {"))

(require 'url-http)
(defun insert-bibtex-from-doi (doi)
  (interactive "sDOI: ")
  (let* ((url (if (string-prefix-p "https://doi.org/" doi)
                  doi
                (concat "https://doi.org/" doi)))
         (url-request-method "GET")
         (url-mime-accept-string "application/x-bibtex"))
    (insert
     (with-current-buffer (url-retrieve-synchronously url t)
        (goto-char (point-min))
        (while (not (looking-at "\n"))
          (forward-line 1))
        (let ((string (buffer-substring-no-properties (point) (point-max))))
          (kill-buffer)
          (decode-coding-string (string-trim string) 'utf-8))))
    (clean-bibtex-entry)
    (add-file-entry)
    (let ((key (get-citation-key)))
      (when key
        (download-pdf-from-doi doi key)))))

(defun download-pdf-from-doi (doi key)
  "Download PDF for DOI and save as KEY.pdf using the Python script.
The command runs asynchronously in the background."
  (let ((command (format "python3 /home/anthe/projects/personal/scripts/research/doi2pdf.py \"%s\" \"%s\""
                         doi key)))
    (start-process-shell-command
     "download-pdf"  ; Name of the process (arbitrary)
     nil              ; No output buffer
     command)         ; Command to run
    (message "Downloading PDF for %s in the background..." key)))

(defun get-citation-key ()
  "Extract the citation key from the BibTeX entry at point."
  (interactive)
  (save-excursion
    (re-search-backward "^@\\(Article\\|Book\\|InProceedings\\|PhdThesis\\|TechReport\\|Misc\\){\\([^,]*\\)," nil t)
    (match-string 2)))

(defvar default-bib "/home/anthe/library/research/research.bib")
(defun add-doi-to-my-bib ()
  (interactive)
  (let ((doi (read-string "DOI: ")))
    (if (search-doi-in-bib doi)
        (message "DOI already exists in the BibTeX file!")
      (popper-toggle)
      (let ((buffer (find-file default-bib)))
        (with-current-buffer buffer
          (goto-char (point-max))
          (insert "\n")
          (insert-bibtex-from-doi doi)
          (save-buffer)))
      (message "DOI added to the BibTeX file!"))))

(defun search-doi-in-bib (doi)
  "Check if the DOI exists in the default BibTeX file using a Python script.
Returns t if the DOI exists, nil otherwise."
  (let ((command (format "python3 /home/anthe/projects/personal/scripts/research/doiexistsinbib.py \"%s\" \"%s\""
                         doi default-bib)))
    (string-equal "True" (string-trim (shell-command-to-string command)))))

(map! :leader
      :desc "Add doi to my bib" "k c a" #'add-doi-to-my-bib)

(provide 'anthe-bib)
;;; anthe-bib.el ends here
