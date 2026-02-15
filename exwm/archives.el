;;; archives.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Maintainer: anthe <anthe@inspiron>
;; Created: February 15, 2026
;; Modified: February 15, 2026
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/anthe/archives
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(defvar exwm-local-mode t "Whether EXWM is in local mode.")

(defun exwm-toggle-local-mode ()
  "Toggle between local and remote mode in EXWM and update prefix keys."
  (interactive)
  (setq exwm-local-mode (not exwm-local-mode))
  (if exwm-local-mode
      (progn
        (setq exwm-input-prefix-keys
              '(?\C-x
                ?\C-c
                ;; ?\C-u
                ?\C-h
                ?\M-x
                ?\M-`
                ?\M-&
                ?\M-:
                ?\C-\M-j  ;; Buffer list
                ?\C-`
                ?\C-\ ))  ;; Ctrl+Space
        (message "EXWM local mode"))
    (progn
      (setq exwm-input-prefix-keys '())  ;; Clear prefix keys for remote mode
      (message "EXWM remote mode"))))



;; Function to set transparency
(defun set-window-transparency (transparency)
  "Set the transparency of the current window."
  (let ((win-id (window-id (selected-window))))
    (call-process "xprop" nil nil nil
                  "-id" (number-to-string win-id)
                  "-f" "_NET_WM_WINDOW_OPACITY" "32c"
                  "-set" "_NET_WM_WINDOW_OPACITY" (number-to-string transparency))))
;; Hook to set transparency based on workspace
(defun my-exwm-workspace-transparency ()
  "Set transparency based on the current workspace."
  (let ((workspace (exwm-workspace-number (exwm-get-workspace))))
    (cond
     ((= workspace 1) (set-window-transparency 255)) ; No transparency for workspace 1
     ((= workspace 2) (set-window-transparency 200)) ; Some transparency for workspace 2
     ((= workspace 3) (set-window-transparency 150)) ; More transparency for workspace 3
     ;; Add more conditions for other workspaces as needed
     )))

(provide 'archives)
;;; archives.el ends here
