;;; anthe-file-manager.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Maintainer: anthe <anthe@inspiron>
;; Created: February 15, 2026
;; Modified: February 15, 2026
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/anthe/anthe-file-manager
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(setq ibuffer-formats
        '((mark modified read-only locked " "
                (name 40 40 :left :elide)
                " "
                (size 7 -1 :right)
                " "
                (mode 12 12 :left :elide)
                " "
                (vc-status 9 :left)
                " " filename-and-process)
        (mark " "
                (name 10 -1)
                " " filename)))

(require 'dirvish)

(setq dired-kill-when-opening-new-dired-buffer t)
(setq dired-omit-extensions '(".o" ".bin" ".lbin" ".so" ".a" ".ln" ".blg" ".bbl" ".elc" ".lof" ".glo" ".idx" ".lot" ".svn/" ".hg/" ".git/" ".bzr/" "CVS/" "_darcs/" "_MTN/" ".fmt" ".tfm" ".class" ".fas" ".lib" ".mem" ".x86f" ".sparcf" ".dfsl" ".pfsl" ".d64fsl" ".p64fsl" ".lx64fsl" ".lx32fsl" ".dx64fsl" ".dx32fsl" ".fx64fsl" ".fx32fsl" ".sx64fsl" ".sx32fsl" ".wx64fsl" ".wx32fsl" ".fasl" ".ufsl" ".fsl" ".dxl" ".lo" ".la" ".gmo" ".mo" ".toc" ".aux" ".cp" ".fn" ".ky" ".pg" ".tp" ".vr" ".cps" ".fns" ".kys" ".pgs" ".tps" ".vrs" ".pyc" ".pyo" ".idx" ".lof" ".lot" ".glo" ".blg" ".bbl" ".cp" ".cps" ".fn" ".fns" ".ky" ".kys" ".pg" ".pgs" ".tp" ".tps" ".vr" ".vrs"))

(setq dirvish-preview-disabled-exts '("bin" "exe" "gpg" "elc" "eln" "xcf" "ncap2.temp" "pid*" "odp"))

(defun my-dirvish-cdo-preview ()
  (interactive)
  (dirvish-define-preview nc (file ext)
  "Preview netcdf file info with cdo sinfon
   Require: `cdo' (executable)"
  :require ("cdo" )
  (cond ((equal ext "nc") `(shell . ("cdo" "-sinfon" ,file))))))

(defun my-dirvish-ncdump-preview ()
  (interactive)
  (dirvish-define-preview nc (file ext)
  "Preview netcdf file info with ncdump -h
   Require: `ncdump' (executable)"
   :require ("ncdump" )
   (cond ((equal ext "nc") `(shell . ("ncdump" "-h" ,file))))))

(my-dirvish-ncdump-preview) ;; ncdump by default

(add-to-list 'dirvish-preview-dispatchers 'nc)

(setq dired-kill-when-opening-new-dired-buffer t)

(load "~/.config/emacs/.local/dired-x.el")

(dired-async-mode)


(provide 'anthe-file-manager)
;;; anthe-file-manager.el ends here
