;;; init-hpc.el -*- lexical-binding: t; -*-

;; Doom's modules on the HPC (UBELIX), where ~/.config/doom/init.el links
;; here: the laptop's init.el, without what isn't used there. Run
;; `doomc sync' after a change.
;;
;; Left out, against the laptop's: eshell; spell and grammar checkers;
;; biblio, docker, llm; latex, lua; org's roam and journal (org stays, for
;; READMEs); everything of the desktop (EXWM, mail, calendars, contacts:
;; packages-hpc.el).

;; As on the laptop: j, k, 0 and $ move by screen lines
(setq evil-respect-visual-line-mode t)

(doom! :completion
       (company +childframe)
       vertico

       :ui
       doom
       hl-todo
       indent-guides
       modeline
       ophints
       (vc-gutter +pretty)
       vi-tilde-fringe
       workspaces

       :editor
       (evil +everywhere)
       file-templates
       fold
       (format +onsave)
       snippets

       :emacs
       dired
       electric
       ibuffer
       undo
       vc

       :term
       vterm

       :checkers
       syntax

       :tools
       (debugger +lsp)        ; anthe-dap
       (eval +overlay)
       lookup
       lsp
       magit
       pdf                    ; anthe-pdf
       tree-sitter

       :lang
       (cc +lsp)              ; PISM
       emacs-lisp
       json
       markdown
       org
       (python +lsp +pyenv)
       sh
       yaml

       :config
       (default +bindings +smartparens))
