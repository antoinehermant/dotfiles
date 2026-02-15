;;; anthe-control.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Maintainer: anthe <anthe@inspiron>
;; Created: February 15, 2026
;; Modified: February 15, 2026
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/anthe/anthe-control
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(defun my-switch-laptop-charger ()
  (interactive)
  (let ((output (shell-command-to-string "/home/anthe/projects/personal/scripts/home/switch_devices.py laptop_charger")))
    (message "%s" output)))

(defun my-switch-sound-system ()
  (interactive)
  (let ((output (shell-command-to-string "/home/anthe/projects/personal/scripts/home/switch_devices.py sound_system")))
    (message "%s" output)))

(defun my-switch-drive-1 ()
  (interactive)
  (let ((output (shell-command-to-string "/home/anthe/projects/personal/scripts/home/switch_devices.py drive_1")))
    (message "%s" output)))

(defun my-switch-desk-lamp ()
  (interactive)
  (let ((output (shell-command-to-string "/home/anthe/projects/personal/scripts/home/switch_lights.py desk_lamp")))
    (message "%s" output)))

(defun my-sync-pi-nas ()
  (interactive)
  (let ((output (async-shell-command "/home/anthe/projects/personal/scripts/system/sync_nas.sh")))
    (message "%s" output)))

(map! :leader
      :desc "Backup files to my NAS" "k b" #'my-sync-pi-nas
      :desc "Switch desk lamp" "k t l" #'my-switch-desk-lamp
      :desc "Switch sound system" "k t s" #'my-switch-sound-system
      :desc "Switch drive" "k t d" #'my-switch-drive-1
      :desc "Switch laptop charger" "k t c" #'my-switch-laptop-charger)


(provide 'anthe-control)
;;; anthe-control.el ends here
