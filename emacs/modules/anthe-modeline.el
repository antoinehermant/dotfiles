;;; anthe-modeline.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Maintainer: anthe <anthe@inspiron>
;; Created: May 28, 2026
;; Modified: May 28, 2026
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/anthe/anthe-modeline
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(require 'doom-modeline)
(doom-modeline-mode 1)

(setq doom-modeline-battery t)
(setq doom-modeline-icon t)
(setq doom-modeline-major-mode-icon t)
(setq doom-modeline-buffer-modification-icon t)
(setq doom-modeline-lsp-icon t)
(setq doom-modeline-time-icon t)
(setq doom-modeline-time t)
(setq doom-modeline-time-live-icon t)
(setq doom-modeline-time-analogue-clock t)
(setq doom-modeline-vcs-max-length 15)
(setq doom-modeline-project-name nil)
(setq doom-modeline-workspace-name nil)
(setq doom-modeline-persp-name t)
(setq doom-modeline-persp-icon t)


(provide 'anthe-modeline)
;;; anthe-modeline.el ends here
