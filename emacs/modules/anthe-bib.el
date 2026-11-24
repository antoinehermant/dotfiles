;;; anthe-bib.el --- Bibliography management for Emacs -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Maintainer: anthe <anthe@inspiron>
;; Created: February 15, 2026
;; Modified: November 22, 2026
;; Version: 0.4.0
;; Keywords: bibtex, bibliography, doi, research
;; Homepage: https://github.com/anthe/anthe-bib
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  My bibliography: one bib per topic of ~/library/science (glaciology,
;;  astronomy...), each with its PDFs beside, read by python-utils'
;;  research/library.py; citar reads them all (anthe-citar.el).
;;
;;  - add-doi-to-my-bib (SPC k c a): a DOI to the bib of a topic, in the
;;    background: the topic asked (OpenAlex suggests one), the entry with the
;;    topic in its keywords, its PDF; then the map and the web app updated
;;  - anthe-bib-add-from-pdf (in a PDF, SPC m a; b and B in zathura): a DOI
;;    of the PDF read: the selected reference, else one of the page's
;;  - anthe-bib-add-queued (SPC k c q): a DOI queued from the phone or the
;;    map (the web app on the pi, research/libweb)
;;  - anthe-bib-related (SPC k c r): my articles nearest an entry, by their
;;    citations (research/graph.py)
;;  - anthe-bib-map (SPC k c v): the citation map, in the browser
;;  - anthe-bib-note (SPC k c n): the org-roam note of an entry
;;  - clean-bibtex-entry: format the BibTeX entry at point
;;
;;; Code:

(require 'json)

(defvar anthe-bib-python "/home/anthe/software/miniconda3/envs/processing/bin/python3"
  "The Python with python-utils: the system python3 does not have it.")

(defvar anthe-bib-show-added t
  "Non-nil: show an entry once added, at its keywords, to add some.")

(defvar anthe-bib-feed "~/org/roam/digest/feed.org"
  "The research feed, whose entries have the abstracts for the notes.")

(defvar anthe-bib-web "https://pi.tail47921c.ts.net:8443/"
  "The library's web app, on the pi (python-utils' research/libweb): the
library on the phone, and the citation map.")

(defvar anthe-bib-queue "~/org/library-queue.org"
  "The DOIs queued from the phone or the map, to add here (SPC k c q).")

(defconst anthe-bib--errors " *anthe-bib errors*")


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
          (fill-column 100000))  ; Set a very large fill-column to prevent wrapping
      (bibtex-clean-entry))))


;;; The library (python-utils' research/library.py)

(defun anthe-bib--run (args callback &optional module)
  "Run library.py (or MODULE of research/) with ARGS in the background, then
CALLBACK with its JSON. An alist, or nil if it gave none: its errors are in
`anthe-bib--errors'."
  (let ((output (generate-new-buffer " *anthe-bib*")))
    (make-process
     :name "anthe-bib" :buffer output :noquery t
     :stderr (get-buffer-create anthe-bib--errors)
     :command (append (list anthe-bib-python "-m"
                            (concat "python_utils.research." (or module "library")))
                      args)
     :sentinel (lambda (process _)
                 (unless (process-live-p process)
                   (let ((json (with-current-buffer output
                                 (goto-char (point-max))
                                 (when (re-search-backward "^[{[]" nil t)
                                   (ignore-errors
                                     (json-parse-buffer :object-type 'alist
                                                        :array-type 'list
                                                        :null-object nil
                                                        :false-object nil))))))
                     (kill-buffer output)
                     (funcall callback json)))))))

(defconst anthe-bib--doi-regexp "\\b\\(10\\.[0-9]\\{4,9\\}/[^][:space:]\"<>{}]+\\)"
  "A DOI, without its doi.org.")

(defun anthe-bib--doi-near ()
  "A DOI in the region, at point or in the clipboard, or nil."
  (seq-some (lambda (text)
              (when (and text (string-match anthe-bib--doi-regexp text))
                (string-trim-right (match-string 1 text) "[.,;)]+")))
            (list (when (use-region-p)
                    (buffer-substring-no-properties (region-beginning) (region-end)))
                  (thing-at-point 'url t)
                  (thing-at-point 'symbol t)
                  (ignore-errors (current-kill 0 t)))))

(defun anthe-bib--read-doi ()
  (let ((near (anthe-bib--doi-near)))
    (string-trim (read-string (format-prompt "DOI" near) nil nil near))))

(defun add-doi-to-my-bib (doi)
  "Add DOI to the bib of a topic of ~/library/science, its PDF beside.
In the background: where DOI already is, else the topic OpenAlex suggests;
then the topic is asked (a new name makes the topic), the entry added with
it in its keywords (a preprint also with preprint, its PDF in preprints/),
its PDF downloaded (the open one, else the publisher's or Sci-Hub); then
the map and the web app are updated, and DOI leaves the queue."
  (interactive (list (anthe-bib--read-doi)))
  (when (string-empty-p doi) (user-error "No DOI"))
  (message "Looking up %s..." doi)
  (anthe-bib--run
   (list "lookup" doi)
   (lambda (found)
     (cond ((null found)
            (message "Could not look %s up: see the buffer %s" doi anthe-bib--errors))
           ((alist-get 'key found)
            (anthe-bib--unqueue doi)
            (message "%s is already in %s as %s" doi
                     (file-name-nondirectory (alist-get 'bib found)) (alist-get 'key found)))
           (t (run-at-time 0 nil #'anthe-bib--add found))))))

(defun anthe-bib--add (found)
  "Ask the topic of FOUND, a lookup, and add it there."
  (let* ((doi (alist-get 'doi found))
         (title (truncate-string-to-width (or (alist-get 'title found) doi) 70 nil nil "…"))
         (topic (completing-read
                 (format-prompt "Topic of %s%s" (alist-get 'topic found) title
                                (if (alist-get 'preprint found) " (preprint)" ""))
                 (alist-get 'topics found) nil nil nil nil (alist-get 'topic found))))
    (message "Adding %s to %s..." title topic)
    (anthe-bib--run
     (list "add" doi "--topic" topic)
     (lambda (added)
       (if (or (null added) (alist-get 'error added))
           (message "Not added: %s" (or (alist-get 'error added)
                                        (format "see the buffer %s" anthe-bib--errors)))
         (anthe-bib--added added doi))))))

(defun anthe-bib--added (added doi)
  "After ADDED, the entry of DOI: show it, update the map and the web app."
  (let ((key (alist-get 'key added))
        (bib (alist-get 'bib added)))
    (when (fboundp 'anthe/citar-update-bibliography)
      (anthe/citar-update-bibliography))
    (when-let* ((buffer (find-buffer-visiting bib)))
      (with-current-buffer buffer (revert-buffer t t t)))
    (anthe-bib--unqueue doi)
    (anthe-bib-refresh-web)
    (when anthe-bib-show-added
      (anthe-bib-show key bib))
    (message "Added %s to %s, %s. SPC k c n: its note"
             key (alist-get 'topic added)
             (if (alist-get 'pdf added) "with its PDF" "no PDF found"))))

(defun anthe-bib-show (key bib)
  "Show the entry KEY of BIB, at the end of its keywords."
  (pop-to-buffer (find-file-noselect bib))
  (goto-char (point-min))
  (when (re-search-forward (format "^@[[:alnum:]]+{%s," (regexp-quote key)) nil t)
    (beginning-of-line)
    (recenter 3)
    (let ((end (save-excursion (bibtex-end-of-entry))))
      (when (re-search-forward "^[ \t]*keywords[ \t]*=[ \t]*{" end t)
        (backward-char)
        (forward-sexp)
        (backward-char)))))

;;; The map and the web app (research/graph.py, research/web.py)

(defun anthe-bib-refresh-web ()
  "Update the citation map and the web app's data, in the background: the
pi has them as Syncthing brings ~/library."
  (interactive)
  (anthe-bib--run '("refresh")
                  (lambda (done)
                    (unless done
                      (message "The map is not updated: see the buffer %s" anthe-bib--errors)))
                  "web"))

(defun anthe-bib-map (&optional key)
  "The citation map of my library, in the browser; at KEY, the entry at point."
  (interactive (list (anthe-bib--key-here)))
  (browse-url (concat anthe-bib-web "map.html" (if key (concat "#" key) ""))))

(defun anthe-bib-related (key)
  "My articles nearest KEY, the entry at point or one chosen: those it cites,
those citing it, those sharing its references or its citers. Open one."
  (interactive (list (or (anthe-bib--key-here) (citar-select-ref))))
  (message "The articles near %s..." key)
  (anthe-bib--run
   (list "related" key)
   (lambda (found)
     (cond ((null found)
            (message "Nothing found: see the buffer %s" anthe-bib--errors))
           ((alist-get 'error found) (message "%s" (alist-get 'error found)))
           (t
            (run-at-time
             0 nil
             (lambda ()
               (let* ((choices
                       (mapcar (lambda (r)
                                 (cons (format "%-18s %s  %s"
                                               (format "%s %s" (alist-get 'author r) (alist-get 'year r))
                                               (truncate-string-to-width (alist-get 'title r) 80 nil nil "…")
                                               (propertize (alist-get 'why r) 'face 'shadow))
                                       (alist-get 'key r)))
                               found))
                      (choice (completing-read (format "Near %s: " key) choices nil t)))
                 (citar-open (list (cdr (assoc choice choices))))))))))
   "graph"))


;;; The queue: DOIs from the phone or the map, to add here

(defun anthe-bib--queued ()
  "The items of the queue: (DOI TITLE), first queued first."
  (let ((file (expand-file-name anthe-bib-queue)) items)
    (when (file-exists-p file)
      (with-temp-buffer
        (insert-file-contents file)
        (goto-char (point-min))
        (while (re-search-forward "^\\* \\(.*\\)$" nil t)
          (let ((title (match-string 1))
                (end (save-excursion
                       (if (re-search-forward "^\\* " nil t) (match-beginning 0) (point-max)))))
            (when (re-search-forward "^:DOI:[ \t]*\\(.+?\\)[ \t]*$" end t)
              (push (list (match-string 1) title) items))
            (goto-char end)))))
    (nreverse items)))

(defun anthe-bib--unqueue (doi)
  "Remove DOI from the queue, if there."
  (let ((file (expand-file-name anthe-bib-queue))
        (case-fold-search t))
    (when (and (file-exists-p file)
               (with-temp-buffer
                 (insert-file-contents file)
                 (re-search-forward (format "^:DOI:[ \t]*%s[ \t]*$" (regexp-quote doi)) nil t)))
      (with-current-buffer (find-file-noselect file)
        (save-excursion
          (goto-char (point-min))
          (when (re-search-forward (format "^:DOI:[ \t]*%s[ \t]*$" (regexp-quote doi)) nil t)
            (let ((start (save-excursion (re-search-backward "^\\* ") (point)))
                  (end (if (re-search-forward "^\\* " nil t) (match-beginning 0) (point-max))))
              (delete-region start end)
              (save-buffer))))))))

(defun anthe-bib-add-queued ()
  "Add a DOI of the queue: queued from the phone or the citation map."
  (interactive)
  (let* ((items (or (anthe-bib--queued) (user-error "Nothing queued")))
         (choices (mapcar (lambda (i)
                            (cons (format "%s  %s" (cadr i) (propertize (car i) 'face 'shadow))
                                  (car i)))
                          items)))
    (add-doi-to-my-bib (cdr (assoc (completing-read "Add: " choices nil t) choices)))))


;;; A DOI of the PDF read: pdf-view, or zathura (bin/zathura-doi)

(defun anthe-bib-add-from-pdf (&optional file page text)
  "Add a DOI of the PDF read: of the selected TEXT, else one of the page's
references (all the PDF's, if the page has none). A selected reference
without a DOI is looked up in Crossref. FILE and PAGE are pdf-view's, or
zathura's (bin/zathura-doi)."
  (interactive)
  (when (derived-mode-p 'pdf-view-mode)
    (setq file (or file buffer-file-name)
          page (or page (pdf-view-current-page))
          text (or text (and (pdf-view-active-region-p)
                             (string-join (pdf-view-active-region-text) " ")))))
  (unless file (user-error "Not in a PDF"))
  (setq text (and text (string-trim (replace-regexp-in-string "[\u2010\u2011]" "-" text))))
  (cond ((and text (string-match anthe-bib--doi-regexp text))
         (add-doi-to-my-bib (string-trim-right (match-string 1 text) "[.,;)]+")))
        ((and text (> (length text) 20))
         (anthe-bib--resolve text))
        (t
         (message "The DOIs of %s..." (file-name-nondirectory file))
         (anthe-bib--run
          (append (list "dois" (expand-file-name file))
                  (when page (list "--page" (number-to-string page))))
          (lambda (found)
            (if (null found)
                (message "No DOI in this PDF: select a reference, it is looked up")
              (run-at-time 0 nil #'anthe-bib--choose-doi found)))))))

(defun anthe-bib--choose-doi (found)
  "Add one of FOUND, the DOIs of a PDF with their references, chosen."
  (let* ((choices
          (mapcar (lambda (d)
                    (cons (format "%s  %s%s"
                                  (truncate-string-to-width
                                   (let ((ref (alist-get 'reference d)))
                                     (if (> (length ref) 110) (substring ref -110) ref))
                                   110 nil ?\s "…")
                                  (propertize (alist-get 'doi d) 'face 'shadow)
                                  (if (alist-get 'key d)
                                      (propertize (format "  ✓ %s" (alist-get 'key d)) 'face 'success)
                                    ""))
                          (alist-get 'doi d)))
                  found))
         (choice (completing-read "Add the reference: " choices nil t)))
    (add-doi-to-my-bib (cdr (assoc choice choices)))))

(defun anthe-bib--resolve (text)
  "Add the article of the reference TEXT, which has no DOI: Crossref's match,
confirmed."
  (message "Looking the reference up in Crossref...")
  (anthe-bib--run
   (list "resolve" text)
   (lambda (found)
     (cond ((or (null found) (alist-get 'error found))
            (message "Crossref did not answer: %s" (or (alist-get 'error found) "")))
           (t
            (run-at-time
             0 nil
             (lambda ()
               (let* ((choices
                       (mapcar (lambda (m)
                                 (cons (format "%s %s  %s  %s" (alist-get 'author m) (alist-get 'year m)
                                               (alist-get 'title m)
                                               (propertize (alist-get 'doi m) 'face 'shadow))
                                       (alist-get 'doi m)))
                               found))
                      (choice (completing-read "This one? " choices nil t)))
                 (add-doi-to-my-bib (cdr (assoc choice choices)))))))))))


;;; Notes, in org-roam (citar-org-roam)

(defun anthe-bib--key-here ()
  "The citation key at point: a citation, or the BibTeX entry."
  ;; citar isn't loaded at startup: the commands asking for a key load it
  (or (and (require 'citar nil t) (citar-key-at-point))
      (and (derived-mode-p 'bibtex-mode)
           (save-excursion
             (bibtex-beginning-of-entry)
             (and (looking-at bibtex-entry-maybe-empty-head)
                  (bibtex-key-in-head))))))

(defun anthe-bib-note (key)
  "Open the org-roam note of KEY, or create it: the entry at point, else one
chosen."
  (interactive (list (or (anthe-bib--key-here) (citar-select-ref))))
  (citar-open-notes (list key)))

(defun anthe-bib--abstract (doi)
  "The abstract of DOI: from the research feed, else OpenAlex."
  (or (let ((feed (expand-file-name anthe-bib-feed)))
        (when (file-exists-p feed)
          (with-temp-buffer
            (insert-file-contents feed)
            (let ((case-fold-search t))
              (when (re-search-forward (format "^[ \t]*:DOI:[ \t]+%s[ \t]*$" (regexp-quote doi)) nil t)
                (re-search-forward "^[ \t]*:END:[ \t]*\n" nil t)
                (let ((text (string-trim (buffer-substring
                                          (point) (if (re-search-forward "^\\*" nil t)
                                                      (match-beginning 0) (point-max))))))
                  (unless (string-empty-p text) text)))))))
      (let ((text (string-trim
                   (with-output-to-string
                     (call-process anthe-bib-python nil standard-output nil
                                   "-m" "python_utils.research.library" "abstract" doi)))))
        (unless (string-empty-p text) text))))

(defun anthe-bib-create-note (citekey entry)
  "Create the org-roam note of CITEKEY (ENTRY): the PDF for org-noter, links
to the PDF, the DOI and the entry, the abstract; a place for a summary.
In place of citar-org-roam's, which writes only the title."
  (let* ((title (citar-format--entry citar-org-roam-note-title-template entry))
         (doi (citar-get-value "doi" entry))
         (file (car (gethash citekey (citar-get-files citekey))))
         (abstract (or (citar-get-value "abstract" entry)
                       (and doi (anthe-bib--abstract doi)))))
    (org-roam-capture-
     :info (list :citar-citekey citekey :note-title title)
     :node (org-roam-node-create :title title)
     :props '(:finalize find-file)
     :templates
     `(("r" "reference" plain "" :target
        (file+head ,(concat (when citar-org-roam-subdir (concat citar-org-roam-subdir "/"))
                            "${citar-citekey}.org")
                   "#+title: ${note-title}\n#+filetags: :reference:\n")
        :immediate-finish t :unnarrowed t)))
    (org-roam-ref-add (concat "@" citekey))
    (when file
      (org-entry-put (point-min) "NOTER_DOCUMENT" (abbreviate-file-name file)))
    (goto-char (point-max))
    (insert "\n* Links\n"
            (if file (format "- PDF: [[file:%s][%s]]\n" (abbreviate-file-name file)
                             (file-name-nondirectory file))
              "")
            (if doi (format "- DOI: [[https://doi.org/%s][%s]]\n" doi doi) "")
            (format "- Entry: [cite:@%s]\n" citekey)
            "\n* Summary\n\n")
    (let ((summary (1- (point))))
      (insert "\n* Notes\n"
              (if abstract (concat "\n* Abstract\n" abstract "\n") ""))
      (save-buffer)
      (goto-char summary))))

(with-eval-after-load 'citar-org-roam
  (advice-add 'citar-org-roam--create-capture-note :override #'anthe-bib-create-note))


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
                             anthe-bib-python "-m" "python_utils.email.summary"
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
  (message "In Monday check - day of week: %d" (string-to-number (format-time-string "%u")))
  (let ((today-file (format "/home/anthe/org/roam/digest/scholar_updates_%s.org"
                            (format-time-string "%Y-%m-%d"))))
    (message "Today's file: %s, exists: %s" today-file (file-exists-p today-file))
    (when (eq (string-to-number (format-time-string "%u")) 1) ; Monday is day 1
      (if (file-exists-p today-file)
          (message "Scholar digest already created for today: %s" today-file)
        (message "Running Monday scholar digest...")
        (python-scholar-update-background 7 5)))))

;; Replaced by the research feed (python-utils' research/feed.py, a daily
;; timer, on the dashboard): OpenAlex, no mail alerts nor AI
;; (add-hook 'after-init-hook 'python-scholar-update-monday-check)

(provide 'anthe-bib)
;;; anthe-bib.el ends here
