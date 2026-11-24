;;; anthe-citar.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Maintainer: anthe <anthe@inspiron>
;; Created: February 15, 2026
;; Modified: February 15, 2026
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/anthe/anthe-citar
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(add-to-list 'load-path "~/.config/emacs/.local/straight/repos/citar/")
(add-to-list 'load-path "~/.config/emacs/.local/straight/repos/parsebib/")
(add-to-list 'load-path "~/.config/emacs/.local/straight/repos/citeproc-el/")
(add-to-list 'load-path "~/.config/emacs/.local/straight/repos/queue/")
;; citar loads with its first command (autoloads), citar-org with org-cite,
;; citar-embark with embark (Doom's biblio module)

;; Each topic of ~/library/science has its bib, of its name (python-utils'
;; research/library.py, `SPC k c a'); its keywords have the topic, so that
;; "astronomy" finds the topic. Then the other bibs of ~/library, and the
;; index of the documents without an entry (library.py index)
(defvar anthe/citar-other-bibs '("~/library/textbooks/textbooks.bib"
                                 "~/library/cheatsheets/cheatsheets.bib"
                                 "~/library/library.bib"))

(defun anthe/citar-bibliographies ()
  "The bibs of ~/library: those of the topics, then the others."
  (append (seq-filter (lambda (bib)
                        (equal (file-name-base bib)
                               (file-name-nondirectory
                                (directory-file-name (file-name-directory bib)))))
                      (file-expand-wildcards "~/library/science/*/*.bib"))
          (seq-filter #'file-exists-p anthe/citar-other-bibs)))

(defun anthe/citar-update-bibliography ()
  "Read the bibs of ~/library again: a new topic."
  (interactive)
  (setq citar-bibliography (anthe/citar-bibliographies)
        bibtex-completion-bibliography citar-bibliography))

(anthe/citar-update-bibliography)

;; The icons need citar
(with-eval-after-load 'citar
  (defvar citar-indicator-notes-icons
    (citar-indicator-create
     :symbol (nerd-icons-mdicon
              "nf-md-notebook"
              :face 'nerd-icons-blue
              :v-adjust -0.3)
     :function #'citar-has-notes
     :padding "  "
     :tag "has:notes"))

  (defvar citar-indicator-links-icons
    (citar-indicator-create
     :symbol (nerd-icons-octicon
              "nf-oct-link"
              :face 'nerd-icons-orange
              :v-adjust -0.1)
     :function #'citar-has-links
     :padding "  "
     :tag "has:links"))

  (defvar citar-indicator-files-icons
    (citar-indicator-create
     :symbol (nerd-icons-faicon
              "nf-fa-file"
              :face 'nerd-icons-purple
              :v-adjust -0.1)
     :function #'citar-has-files
     :padding "  "
     :tag "has:files"))

  (setq citar-indicators
        (list citar-indicator-files-icons
              citar-indicator-notes-icons
              citar-indicator-links-icons)))

(setq citar-templates
      '((main . "${author editor:40%sn}  ${date year issued:4}  ${title:100}  ${journal:10} ")
        (suffix . " ${journalgroup} ${publisher:10}  ${=type=:0}  ${tags keywords:*}") ;; ${=key= id:15}
        (preview . "${author editor:%etal} (${year issued date}) ${title}, ${journal journaltitle publisher container-title collection-title}.\n")
        (note . "Notes on ${author editor:%etal}, ${title}")))

(setq citar-open-prompt
      '(citar-attach-files citar-open citar-open-note))

(setq citar-file-open-functions
      '(("html" . citar-file-open-external)
        (t . find-file)))

(map! :leader
      (:prefix ("k c" . "citar")
       :desc "insert citation" "i" #'citar-insert-citation
       :desc "open" "o" #'citar-open
       :desc "dwim" "d" #'citar-dwim
       :desc "open at point" "O" #'citar-open-entry
       :desc "note" "n" #'anthe-bib-note
       :desc "add a DOI" "a" #'add-doi-to-my-bib
       :desc "add a queued DOI" "q" #'anthe-bib-add-queued
       :desc "related articles" "r" #'anthe-bib-related
       :desc "citation map" "v" #'anthe-bib-map))

;; After org, not oc: org loads oc before it has its map
(with-eval-after-load 'org
  (define-key org-mode-map (kbd "RET") #'citar-dwim))

(provide 'anthe-citar)
;;; anthe-citar.el ends here
