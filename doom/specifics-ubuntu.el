;;; specifics-ubuntu.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2025 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Maintainer: anthe <anthe@inspiron>
;; Created: February 26, 2025
;; Modified: February 26, 2025
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/anthe/specifics-ubuntu
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:



(provide 'specifics)
;;; specifics-ubuntu.el ends here

(display-battery-mode)
;; ---------------------- EXWM -----------------------------------
;;
;;

;; (require 'exwm)
;; (require 'exwm-config)

(defun efs/exwm-init-hook ()
  (exwm-workspace-switch-create 1)

  (efs/run-in-background "nm-applet"))

(defun efs/exwm-update-class ()
  (exwm-workspace-rename-buffer exwm-class-name))
;; (defun efs/configure-window-by-class ()
;;   (interactive)
;;   (when (string-match-p "^Ncview" exwm-class-name)
;;     (exwm-floating-toggle-floating)
;;     (exwm-layout-toggle-mode-line)))
;; (defun efs/configure-window-by-class ()
;;   (interactive)
;;   (pcase exwm-class-name
;;   ("Ncview" (exwm-floating-toggle-floating))))
(defun efs/configure-window-by-class ()
  "Configure window properties based on the class name."
  (interactive)
  (when (string-match-p "\\`Ncview\\(?:<2>\\)?\\'" exwm-class-name)
    (exwm-floating-toggle-floating)))

;; (defun efs/set-ncview-floating ()
;;   "Configure windows as they're created based on their class name."
;;   (interactive)
;;   (when (string-match-p "^Ncview<" exwm-class-name)
;;     (exwm-floating-toggle-floating)))

;; (defun efs/configure-window-by-class ()
;;   (interactive)
;;   (when (or (string= exwm-class-name "Ncview")
;;             (string-match-p "^Ncview<[0-9]+>$" exwm-class-name))
;;     (exwm-floating-toggle-floating)))
;; (defun efs/set-ncview-floating ()
;;   (interactive)
;;   (when (string-match-p "^Ncview" exwm-class-name)
;;     (unless (frame-parameter exwm--frame 'exwm-floating)
;;       (exwm-floating-toggle-floating))
;;     (exwm-layout-toggle-mode-line))
;;   (message "Window class: %s, Floating: %s"
;;            exwm-class-name
;;            (frame-parameter exwm--frame 'exwm-floating)))
(defvar exwm-local-mode t "Whether EXWM is in local mode.")

(defun exwm-toggle-local-mode ()
  "Toggle between local and remote mode in EXWM and update prefix keys."
  (interactive)
  (setq exwm-local-mode (not exwm-local-mode))
  (if exwm-local-mode
      (progn
        (setq exwm-input-prefix-keys
              '(?\C-x
                ?\C-u
                ?\C-h
                ?\M-x
                ?\M-`
                ?\M-&
                ?\M-:
                ?\C-\M-j  ;; Buffer list
                ?\C-\ ))  ;; Ctrl+Space
        (message "EXWM local mode"))
    (progn
      (setq exwm-input-prefix-keys '())  ;; Clear prefix keys for remote mode
      (message "EXWM remote mode"))))

;; Bind the toggle function to the Super key
(global-set-key (kbd "s-m") 'exwm-toggle-local-mode)

(use-package exwm
  :config

  ;; (add-hook 'exwm-init-hook #'efs/exwm-init-hook)
  ;; Set the default number of workspaces
  (setq exwm-workspace-number 5)

  ;; When window "class" updates, use it to set the buffer name
  (add-hook 'exwm-update-class-hook #'efs/exwm-update-class)


  ;; (add-hook 'exwm-manage-finish-hook #'efs/set-ncview-floating)
  (add-hook 'exwm-manage-finish-hook #'efs/configure-window-by-class)

  ;; These keys should always pass through to Emacs
  (setq exwm-input-prefix-keys
    '(?\C-x
      ?\C-u
      ?\C-h
      ?\M-x
      ?\M-`
      ?\M-&
      ?\M-:
      ?\C-\M-j  ;; Buffer list
      ?\C-\ ))  ;; Ctrl+Space

  ;; Ctrl+Q will enable the next key to be sent directly
  (define-key exwm-mode-map [?\C-q] 'exwm-input-send-next-key)
  ;; (global-set-key (kbd "s-/") 'counsel-linux-app)
  ;; (global-set-key (kbd "s-,") 'switch-to-buffer)
;; (setq exwm-manage-configurations
;;       '(((equal exwm-class-name "ncview")
;;          floating t)))
  ;; Set up global key bindings.  These always work, no matter the input state!
  ;; Keep in mind that changing this list after EXWM initializes has no effect.
  (setq exwm-input-global-keys
        `(
          ;; Reset to line-mode (C-c C-k switches to char-mode via exwm-input-release-keyboard)
          ([?\s-r] . exwm-reset)

          ;; Move between windows
          ([?\s-h] . windmove-left)
          ([?\s-l] . windmove-right)
          ([?\s-k] . windmove-up)
          ([?\s-j] . windmove-down)

          ([?\s-,] . switch-to-buffer)
          ([?\s-/] . counsel-linux-app)
          ([?\s-m] . exwm-toggle-local-mode)
          ;; Launch applications via shell command
          ([?\s-&] . (lambda (command)
                       (interactive (list (read-shell-command "$ ")))
                       (start-process-shell-command command nil command)))

          ;; Switch workspace
          ([?\s-w] . exwm-workspace-switch)
          ;; 's-N': Switch to certain workspace with Super (Win) plus a number key (0 - 9)
          ,@(mapcar (lambda (i)
                      `(,(kbd (format "s-%d" i)) .
                        (lambda ()
                          (interactive)
                          (exwm-workspace-switch-create ,i))))
                    (number-sequence 0 9))))

  (defun set-trackpad-behavior ()
    "Set natural scrolling and double pad touch"
    (interactive)
    (shell-command "xinput set-prop 9 328 1")
    (shell-command "xinput set-prop 9 320 1"))
  (set-trackpad-behavior)

        (defun brightness-up ()
          "Increase brightness by 10%"
        (interactive)
        (shell-command "brightnessctl set +10%"))

        (defun brightness-down ()
          "Decrease brightness by 10%"
        (interactive)
        (shell-command "brightnessctl set 10%-"))

        (global-set-key (kbd "<XF86MonBrightnessUp>") 'brightness-up)
        (global-set-key (kbd "<XF86MonBrightnessDown>") 'brightness-down)

  (exwm-enable))

;; ---------- ivy and counsel -------------------

;; Bind s-SPC to counsel-linux-app globally

;; (require 'ivy)
;; (use-package ivy
;;   :diminish
;;   :bind (("C-s" . swiper)
;;          :map ivy-minibuffer-map
;;          ("TAB" . ivy-alt-done)
;;          ("C-l" . ivy-alt-done)
;;          ("C-j" . ivy-next-line)
;;          ("C-k" . ivy-previous-line)
;;          :map ivy-switch-buffer-map
;;          ("C-k" . ivy-previous-line)
;;          ("C-l" . ivy-done)
;;          ("C-d" . ivy-switch-buffer-kill)
;;          :map ivy-reverse-i-search-map
;;          ("C-k" . ivy-previous-line)
;;          ("C-d" . ivy-reverse-i-search-kill))
;;   :config
;;   (ivy-mode 1))

;; (use-package ivy-rich
;;   :init
;;   (ivy-rich-mode 1))

;; (use-package counsel
;;   :bind (("C-M-j" . 'counsel-switch-buffer)
;;          :map minibuffer-local-map
;;          ("C-r" . 'counsel-minibuffer-history))
;;   :config

;;   (counsel-mode 1))

;; (require 'counsel)
;; ;; Configure counsel
;; (use-package counsel
;;   :ensure t)

;; (setq vertico-multiform-mode nil)

;; ----------------------- GPtel ----------------------------------
;; (require 'gptel)

;; ;; Configurer le backend Mistral
;; (setq gptel-model 'mistral-7b-openorca.Q4_0.gguf
;;       gptel-backend (gptel-make-gpt4all "GPT4All"
;;                                       :protocol "http"
;;                                       :host "localhost:4891"
;;                                       :models '(mistral-7b-openorca.Q4_0.gguf)))

;; Optionnel : Augmenter la taille des tokens de réponse
;; (setq gptel-max-tokens 500)

;; MwAi1ONwTlLUD2Dh5fQOy58hqQmDKyYP
