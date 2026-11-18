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
  (let ((output (shell-command-to-string "/home/anthe/projects/perso/python/python-utils/python_utils/home/switch_devices.py laptop_charger")))
    (message "%s" output)))

(defun my-switch-sound-system ()
  (interactive)
  (let ((output (shell-command-to-string "/home/anthe/projects/perso/python/python-utils/python_utils/home/switch_devices.py sound_system")))
    (message "%s" output)))

(defun my-switch-drive-1 ()
  (interactive)
  (let ((output (shell-command-to-string "/home/anthe/projects/perso/python/python-utils/python_utils/home/switch_devices.py drive_1")))
    (message "%s" output)))

(defun my-switch-desk-lamp ()
  (interactive)
  (let ((output (shell-command-to-string "/home/anthe/projects/perso/python/python-utils/python_utils/home/switch_lights.py desk_lamp")))
    (message "%s" output)))

;; Tapo lamps and scenes (light_scene.py: ambiance, coding, small), also
;; said to J.A.R.V.I.S. Run in the background: a lamp that doesn't answer
;; takes a few seconds.
(defvar anthe/light-scripts "/home/anthe/projects/perso/python/python-utils/python_utils/home/")

(defun anthe/light-run (script &rest args)
  "Run the light SCRIPT with ARGS in the background, its output in the echo area."
  (let ((buffer (generate-new-buffer " *light*")))
    (make-process
     :name "light" :buffer buffer :noquery t
     :command (cons (concat anthe/light-scripts script) args)
     :sentinel (lambda (process _event)
                 (unless (process-live-p process)
                   (message "%s" (with-current-buffer buffer (string-trim (buffer-string))))
                   (kill-buffer buffer))))))

(defun anthe/light-switch (lamp)
  "Toggle LAMP, its name in ~/.secrets/.tapo.profile."
  (anthe/light-run "switch_lights.py" lamp))

(defun anthe/light-scene (scene)
  "Set the lights to SCENE, from light_scene.py."
  (anthe/light-run "light_scene.py" scene))

(defun my-sync-pi-nas ()
  (interactive)
  (let ((output (async-shell-command "/home/anthe/projects/perso/scripts/system/sync_nas.sh")))
    (message "%s" output)))

(defun anthe/pivpn-toggle ()
  (interactive)
  (let ((output (shell-command-to-string "/home/anthe/projects/perso/scripts/system/toggle_pivpn.sh")))
    (message "%s" output)))

(map! :leader
      :desc "Backup files to my NAS" "k r b" #'my-sync-pi-nas
      :desc "Switch desk lamp" "k t l" #'my-switch-desk-lamp
      :desc "Switch sound system" "k t s" #'my-switch-sound-system
      :desc "Switch drive" "k t d" #'my-switch-drive-1
      :desc "Switch pi VPN" "k t v" #'anthe/pivpn-toggle
      :desc "Switch laptop charger" "k t c" #'my-switch-laptop-charger
      :desc "Switch armchair lamp" "k t a" (cmd! (anthe/light-switch "armchair_lamp"))
      :desc "Switch ceiling lamp" "k t p" (cmd! (anthe/light-switch "ceiling_lamp"))
      (:prefix ("k t m" . "light scenes")
       :desc "Ambiance" "a" (cmd! (anthe/light-scene "ambiance"))
       :desc "Coding (dark blue)" "c" (cmd! (anthe/light-scene "coding"))
       :desc "Small lights on/off" "s" (cmd! (anthe/light-scene "small"))))

;; Notifications (dunst, see rcfiles/dunstrc)
(defun anthe/dunstctl (&rest args)
  "Run dunstctl with ARGS."
  (apply #'call-process "dunstctl" nil 0 nil args))

(map! :leader
      (:prefix ("z" . "notifications")
       :desc "Dismiss" "z" (cmd! (anthe/dunstctl "close"))
       :desc "Dismiss all" "a" (cmd! (anthe/dunstctl "close-all"))
       :desc "Open" "o" (cmd! (anthe/dunstctl "action"))
       :desc "Bring back the last" "h" (cmd! (anthe/dunstctl "history-pop"))))


(provide 'anthe-control)
;;; anthe-control.el ends here
