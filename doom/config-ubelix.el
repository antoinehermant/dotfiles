;;; machine-specific.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2025 anthe
;;
;; Author: anthe
;; Maintainer: anthe
;; Created: January 18, 2025
;; Modified: January 18, 2025
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/anthe/machine-specific
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(provide 'machine-specific)

;; (setq doom-theme 'doom-challenger-deep)
(setq doom-theme 'doom-material-dark)
;;(add-to-list 'load-path "~/software/emacs-libvterm")

(setq exec-path (append exec-path '("/software.9/software/CMake/3.26.3-GCCcore-12.3.0/bin")))

;; openwith ncview is already in the config.el but this is in case ncview is not loaded on ubelix
;; (use-package! openwith
;;   :config
;;   (setq openwith-associations '(("\\.nc\\'" "/software.9/software/ncview/2.1.8-gompi-2023a/bin/ncview" (file))))
;;   (openwith-mode t))

;; (defun open-ncview (file)
;;   "Open FILE with ncview."
;;   (interactive "fOpen .nc file: ")
;;   (when (y-or-n-p (format "Open '%s' with ncview?" file))
;;     (let ((original-buffer (current-buffer)))  ;; Save the current buffer
;;       (start-process "/software.9/software/ncview/2.1.8-gompi-2023a/bin/ncview" nil "/software.9/software/ncview/2.1.8-gompi-2023a/bin/ncview" file)  ;; Open with ncview
;;       (kill-buffer original-buffer)                ;; Kill the current buffer
;;       ;; Switch back to the original buffer
;;       (switch-to-buffer original-buffer))))

;; (add-hook 'find-file-hook 'my-find-file-hook)
;; Add this to make sure that sub shell initialises properly with .bashrc (-i flag)
;; XXX: no idea why but this completely made my emacs laggy for longer files like in python for example
;; (setq shell-command-switch "-ic")

;; Add the nerd fonts
;;
(setq nerd-icons-font-family "NerdFontsSymbols ")
(setq nerd-icons-font-names '("~/.fonts/NerdFontsSymbols/SymbolsNerdFont-Regular.ttf"))
(setq doom-font (font-spec :family "Ubuntu Sans Mono" :height 109 :path "~/.fonts/UbuntuSansMono/UbuntuSansMono-Regular-BF65bb038c1183a.otf"))
;; ;; default transparency does not work on ubelix but this one does

(defvar my-transparency-value 85
  "Defines a variable for transparency")

(defun toggle-frame-transparency ()
  "Toggle transparency of Emacs frame."
  (interactive)
  (let ((alpha (frame-parameter nil 'alpha)))
    (set-frame-parameter
     nil 'alpha
     (if (eql (cond ((numberp alpha) alpha)
                    ((numberp (cdr alpha)) (cdr alpha))
                    ;; Also handle undocumented (<active> <inactive>) form.
                    ((numberp (cadr alpha)) (cadr alpha)))
              100)
              '(85 . 85) '(100 . 100)))))

(setq conda-anaconda-home "/storage/workspaces/climate_charibdis/climate_ism/Software/miniconda3")

(setq pyvenv-default-virtual-env-name "/storage/workspaces/climate_charibdis/climate_ism/Software/miniconda3/envs/")

(when (memq window-system '(mac ns x))
  (exec-path-from-shell-initialize))

(setq popper-window-height (floor (* (frame-height) 0.33)))
;; (add-hook 'window-setup-hook #'toggle-frame-maximized)

(defun sbatch-buffer ()
  (interactive)
  (let ((file (buffer-file-name)))
    (when file
      (async-shell-command (concat "sbatch " (shell-quote-argument file))))))
;; (remove-hook 'python-mode-hook 'eglot-ensure)

;;; machine-specific.el ends here


