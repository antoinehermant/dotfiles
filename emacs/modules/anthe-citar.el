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
(require 'citar)
(require 'citar-org)
(require 'citar-capf)
(require 'citar-capf)
(require 'citar-cache)
(require 'citar-citeproc)
(require 'citar-embark)
(require 'citar-file)
(require 'citar-format)

(setq bibtex-completion-bibliography '("~/library/research/research.bib",
                                        "~/library/textbooks/textbooks.bib"))
(setq citar-bibliography '("~/library/research/research.bib"
                           "~/library/textbooks/textbooks.bib"))

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
        citar-indicator-links-icons))

(setq citar-templates
      '((main . "${author editor:30%sn}   ${date year issued:4}   ${title:80}   ${journal:16}")
        (suffix . "     ${=type=:10}  ${tags keywords:*}") ;; ${=key= id:15}
        (preview . "${author editor:%etal} (${year issued date}) ${title}, ${journal journaltitle publisher container-title collection-title}.\n")
        (note . "Notes on ${author editor:%etal}, ${title}")))

(setq citar-open-prompt
      '(citar-attach-files citar-open citar-open-note))

(setq citar-file-open-functions
      '(("html" . citar-file-open-external)
        (t . find-file)))

(map! :leader
      (:prefix ("k c" . "citar")
       :desc "Citar open" "o" #'citar-open
       :desc "Citar open at point" "O" #'citar-open-entry))

(with-eval-after-load 'oc
  (define-key org-mode-map (kbd "RET") #'citar-dwin))

(provide 'anthe-citar)
;;; anthe-citar.el ends here
