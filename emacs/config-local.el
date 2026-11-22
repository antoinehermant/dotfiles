;;; config-machine --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2025 anthe
;;
;; Author: anthe
;; Maintainer: anthe
;; Created: February 26, 2025
;; Modified: February 26, 2025
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/anthe/config-machine
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(setq package-install-upgrade-built-in t)


(add-to-list 'load-path "~/.dotfiles/emacs/")
(require 'config-core)

(add-to-list 'load-path "~/.dotfiles/emacs/modules")
(add-to-list 'load-path "/home/anthe/.config/emacs/.local/other")
(require 'anthe-agents)
(require 'anthe-bib)
(require 'anthe-citar)
(require 'anthe-control)
(require 'anthe-consult)
(require 'anthe-dap)
(require 'anthe-desktop)
(require 'anthe-dashboard)
(require 'app-launcher)
(require 'anthe-evil)
(require 'anthe-file-manager)
(require 'anthe-latex)
(require 'anthe-lsp)
(require 'anthe-modeline)
(require 'anthe-mu4e)
(require 'anthe-contacts)
;; J.A.R.V.I.S lives in a private repository, outside the dotfiles
(load (expand-file-name "~/jarvis/emacs/jarvis.el") t)
(setenv "NCVIEWBASE" "/home/anthe/software/configs/ncmaps/ncmaps")
(require 'anthe-openwith)
(require 'anthe-org)
(require 'anthe-pdf)
(require 'anthe-popper)
(require 'anthe-python)
(require 'anthe-roam)
(require 'anthe-sysmon)
(require 'anthe-themes)
(require 'anthe-transparency)
(require 'anthe-vterm)
(require 'anthe-windows)
(require 'anthe-workflow)
(require 'anthe-tasks)

(map! :leader
      :desc "App launcher" "\\" #'app-launcher-run-app)

(setq pyvenv-default-virtual-env-name  "/home/anthe/software/miniconda3/envs/")

(setq org-present-startup-folded t)
(setq popper-window-height (floor (* (frame-height) 0.4)))


(defun ubelix-emacs ()
  (interactive)
  (let ((vterm-buffer (vterm "UBELIX-VTERM")))
    (with-current-buffer vterm-buffer
      (vterm-send-string "ssh ubelix3\n")
      (vterm-send-string "em\n")
      ;; (set-buffer-modified-p nil)
      ;; (bury-buffer) ;; Hide the buffer
      ;; )))
      )))

(defun my-open-current-buffer-externally ()
  "Open current buffer's file with appropriate application."
  (interactive)
  (when-let ((file (buffer-file-name)))
    (cond
     ((string-match "\\.pdf\\'" file)
      (start-process "" nil "evince" file))
     ((string-match "\\.png\\'" file)
      (start-process "" nil "eog" file))
     (t
      (start-process "" nil "xdg-open" file)))))

(map! :leader
      :desc "Open visited file externally" "k o d" #'my-open-current-buffer-externally)

;; (add-to-list 'load-path "~/.config/emacs/.local/elpa/inhibit-mouse-20260603.1158/")
;; more elaborate than disable-mouse, like it handles evil better
                                        ; (use-package! inhibit-mouse
                                        ;   :config
                                        ;   (inhibit-mouse-mode 1))

;; (after! persp-mode
;;   (remove-hook 'persp-add-buffer-on-after-change-major-mode-filter-functions
;;                #'doom-unreal-buffer-p))

(defun anthe/set-key-repeat ()
  "Set the keyboard repeat rate."
  (call-process "xset" nil nil nil "r" "rate" "220" "30"))

(defun anthe/keyboard-preferences ()
  "The layout, Caps Lock as Control, and the repeat rate.  X gives a keyboard
that comes its defaults, so this runs again when one connects."
  (interactive)
  (call-process "setxkbmap" nil nil nil "-layout" "us" "-variant" "altgr-intl")
  (call-process "xmodmap" nil nil nil (expand-file-name "~/.dotfiles/.xmodmap"))
  (anthe/set-key-repeat))

(defun anthe/bluetooth-devices (icon)
  "The paired Bluetooth devices whose icon is ICON, as (ADDRESS . CONNECTED)."
  (delq nil
        (mapcar (lambda (object)
                  (let ((device (cadr (assoc "org.bluez.Device1" (cadr object)))))
                    (when (and (cdr (assoc "Paired" device))
                               (equal (cdr (assoc "Icon" device)) icon))
                      (cons (cdr (assoc "Address" device)) (cdr (assoc "Connected" device))))))
                (ignore-errors (dbus-get-all-managed-objects :system "org.bluez" "/")))))

(defun anthe/connect-mice ()
  "Connect the paired Bluetooth mice not connected.  The Ultrathin Touch
Mouse never connects by itself: it waits for the laptop to call it, which
BlueZ stops doing a few minutes after it went to sleep."
  (dolist (mouse (anthe/bluetooth-devices "input-mouse"))
    (unless (cdr mouse)
      ;; Connecting can hang, which must not block Emacs and so the window manager
      (make-process
       :name "bluetooth-connect"
       :command `("timeout" "15" "bluetoothctl" "connect" ,(car mouse))
       :connection-type 'pipe
       :noquery t
       :sentinel (lambda (process _event)
                   (unless (process-live-p process)
                     (pcase (process-exit-status process)
                       (0 (message "Bluetooth mouse connected"))
                       (124 (message "Bluetooth mouse: connection timed out"))
                       (code (message "Bluetooth mouse: connection failed (exit %d)" code)))))))))

(defun anthe/set-keyboard ()
  "Set the keyboard preferences again, and connect the Bluetooth mouse."
  (interactive)
  (anthe/keyboard-preferences)
  (anthe/connect-mice))

(defun anthe/bluetooth-connected (interface changed _invalidated)
  "When a Bluetooth keyboard or mouse connects (the mouse counts as a keyboard
in X too), set the keyboard preferences on it; when a keyboard does, also
connect the mouse, the two being used together."
  (let ((connected (cadr (assoc "Connected" changed))))
    (when (and (equal interface "org.bluez.Device1")
               (equal (if (consp connected) (car connected) connected) t))
      (let ((icon (ignore-errors
                    (dbus-get-property :system "org.bluez" (dbus-event-path-name last-input-event)
                                       "org.bluez.Device1" "Icon"))))
        (when (member icon '("input-keyboard" "input-mouse"))
          ;; X adds the new keyboard a moment after BlueZ connects it
          (run-at-time 2 nil (if (equal icon "input-keyboard") #'anthe/set-keyboard
                               #'anthe/keyboard-preferences)))))))

(defvar anthe/bluetooth-signal nil)
(when anthe/bluetooth-signal (dbus-unregister-object anthe/bluetooth-signal))
(setq anthe/bluetooth-signal
      (ignore-errors
        (dbus-register-signal :system "org.bluez" nil "org.freedesktop.DBus.Properties"
                              "PropertiesChanged" #'anthe/bluetooth-connected
                              :path-namespace "/org/bluez")))

(custom-set-faces!
  '(anthe-bar-current-workspace :background "#C792EA" :foreground "#011627" :weight bold) ; #7e57c2
  '(anthe-bar-workspace :foreground "#8a9ba8")
  '(anthe-bar-clock :weight bold :foreground "#D6DEEB"))

(provide 'config-local)
;;; config-local.el ends here
