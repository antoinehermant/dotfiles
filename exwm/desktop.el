;;; desktop --- Description -*- lexical-binding: t; -*-
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



(provide 'desktop)

(display-battery-mode)
(display-time-mode)

;; (use-package! exec-path-from-shell
;;   :config
;;   (exec-path-from-shell-initialize)
;;   (exec-path-from-shell-copy-env '("PATH")))

;; (let ((bashrc-path (expand-file-name "~/.bashrc")))
;;   (unless (file-exists-p bashrc-path)
;;     (error "No .bashrc file found at %s" bashrc-path))
;;   (shell-command (concat "source " bashrc-path " && env")))

;; ---------------------- EXWM -----------------------------------
;;
;;

;; (add-to-list 'load-path "~/.config/emacs/.local/elpa/exwm-0.34/")
;; (add-to-list 'load-path "~/.config/emacs/.local/elpa/xelb-0.21/")
(require 'exwm)
;; (require 'exwm-config)


(defun efs/exwm-init-hook ()
  (exwm-workspace-switch-create 1))

(defun efs/set-wallpaper ()
  (interactive)
  (start-process-shell-command
   ;; "feh" nil  "feh --bg-scale /usr/share/backgrounds/Einsamer_Raum_by_Orbite_Lambda.jpg")
   "feh" nil "feh --bg-scale /usr/share/backgrounds/wallhaven-x8z9yo.jpg")
  (toggle-frame-transparency))


;; (defun toggle-frame-transparency ()
;;  "Toggle transparency of Emacs frame."
;;   (interactive)
;;   (let ((alpha (frame-parameter nil 'alpha)))
;;     (set-frame-parameter
;;      nil 'alpha
;;      (if (eql (cond ((numberp alpha) alpha)
;;                     ((numberp (cdr alpha)) (cdr alpha))
;;                     ;; Also handle undocumented (<active> <inactive>) form.
;;                     ((numberp (cadr alpha)) (cadr alpha)))
;;               100)
;;               '(90 . 90) '(100 . 100)))))


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
;; (defun efs/configure-window-by-class ()
;;   "Configure window properties based on the class name."
;;   (interactive)
;;   (when (string-match-p "\\`Ncview\\(?:<2>\\)?\\'" exwm-class-name)
;;     (exwm-floating-toggle-floating))
;;   (when (string-match-p "\\`Matplotlib\\(?:<2>\\)?\\'" exwm-class-name)
;;     (exwm-floating-toggle-floating)))
;;
;;
;; (defun efs/configure-window-by-class ()
;;   (interactive)
;;   (pcase exwm-class-name
;;     ("Ncview" (exwm-floating-toggle-floating)
;;            (exwm-layout-toggle-mode-line))))



(defvar saved-current-buffer-for-floating nil)
(setq saved-current-buffer-for-floating nil)

(defun efs/get-previous-buffer ()
  (interactive)
  (let ((original-buffer (previous-buffer)))
   (setq saved-current-buffer-for-floating original-buffer)))



(defvar exwm-frame-toggle nil
  "Save the state of exwm-frame")
(setq exwm-frame-toggle nil)


(defun efs/configure-window-by-class ()
  (interactive)
  (unless (find-ncview-buffer)
  (when (string-match-p "Matplotlib" exwm-class-name)
           (exwm-floating-toggle-floating))
      ;; (switch-to-buffer (nth 1 (buffer-list)))
      ;; (switch-to-buffer (nth 1 (buffer-list)))
    (setq exwm-frame-toggle nil))
  (when (string-match-p "Ncview" exwm-class-name)
         (unless exwm-frame-toggle nil
             (progn
           (exwm-floating-toggle-floating)
      ;; (switch-to-buffer (nth 1 (buffer-list)))
      ;; (switch-to-buffer (nth 1 (buffer-list)))
           (setq exwm-frame-toggle t))))
  (pcase exwm-class-name
  ("Emacs" (exwm-workspace-move-window 2))))

(defun find-ncview-buffers ()
  "Returns t if an Ncview buffer exists, nil otherwise."
  (interactive)
  (save-excursion
    (let ((found-buffer-p nil))
      (dolist (b (buffer-list))
        (when (string-match "Ncview<" (buffer-name b))
          (setq found-buffer-p t)))
      found-buffer-p)))

(defun find-ncview-buffer ()
  "Returns t if an Ncview buffer exists, nil otherwise."
  (interactive)
  (save-excursion
    (let ((found-buffer-p nil))
      (dolist (b (buffer-list))
        (when (string-match "Ncview" (buffer-name b))
          (setq found-buffer-p t)))
      found-buffer-p)))

(defun efs/reset-frame-toggle-on-kill ()
  "Reset exwm-frame-toggle when the last Ncview instance is killed."
  (interactive)
  (unless (find-ncview-buffers)
      (setq exwm-frame-toggle nil)))


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

(defun efs/run-in-background (command)
  (let ((command-parts (split-string command "[ ]+")))
    (apply #'call-process `(,(car command-parts) nil 0 nil ,@(cdr command-parts)))))

(defun efs/update-displays ()
  (efs/run-in-background "autorandr --change --force")
  (efs/set-wallpaper)
  (message "Display config: %s"
           (virgin-delete-whitespace
            (shell-command-to-string "autorandr --current"))))

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
;; Bind the toggle function to the Super key
(defun efs/exwm-update-title ()
  (when (string-match-p "firefox" exwm-class-name)
    (exwm-workspace-rename-buffer (format "Firefox: %s" exwm-title))))

(defun my-toggle-mouse ()
  "Toggle mouse inhibition by calling several functions"
  (interactive)
  (if (and inhibit-mouse-mode disable-mouse-mode)
      ;; If both modes are active, deactivate them
      (progn
        (inhibit-mouse-mode -1)
        (disable-mouse-mode -1))
    ;; If either mode is inactive, activate them
    (progn
      (inhibit-mouse-mode 1)
      (disable-mouse-mode 1))))

(global-set-key (kbd "s-t m") 'my-toggle-mouse)

(require 'evil)
(require 'exwm)

(evil-define-state exwm
  "`exwm state' interfacing exwm mode."
  :tag " <X> "
  :enable (motion)
  :message "-- EXWM --"
  :intput-method f
  :entry-hook (evil-exwm-state/enter-exwm))

(evil-define-state exwm-insert
  "Replace insert state in `exwm state'."
  :tag " <X> "
  :enable (motion)
  :message "-- EXWM-INSERT --"
  :input-method t
  :entry-hook (evil-exwm-state/enter-exwm-insert))

(defun evil-exwm-state/escape-exwm ()
  "Quit `evil-exwm-insert-state'."
  (interactive)
  (evil-exwm-state))

(defun evil-exwm-state/enter-exwm-insert ()
  "Quit `evil-exwm-insert-state'."
  (call-interactively 'exwm-input-release-keyboard))

(defun evil-exwm-state/enter-exwm ()
  "Quit `evil-exwm-insert-state'."
  (call-interactively 'exwm-input-grab-keyboard))

(define-key evil-exwm-state-map "i" 'evil-exwm-insert-state)

;; Ensure initial state is char mode / exwm-insert
(setq exwm-manage-configurations '((t char-mode t)))
(evil-set-initial-state 'exwm-mode 'exwm-insert)


(use-package exwm
  :config

  (add-hook 'exwm-init-hook #'efs/exwm-init-hook)
  ;; Set the default number of workspaces
  (setq exwm-workspace-number 10)

  ;; This is needed to switch between char and line mode (with evil in line mode)
  (setq exwm-input-line-mode-passthrough t)

  ;; When window "class" updates, use it to set the buffer name
  (add-hook 'exwm-update-class-hook #'efs/exwm-update-class)


  ;; (add-hook 'exwm-manage-finish-hook #'efs/set-ncview-floating)
  (add-hook 'exwm-manage-finish-hook #'efs/configure-window-by-class)

  (add-hook 'kill-buffer-hook 'efs/reset-frame-toggle-on-kill)
;;   (add-hook 'exwm-manage-force-tiling-hook #'efs/configure-window-by-class)
(add-hook 'exwm-update-title-hook #'efs/exwm-update-title)
;; (add-hook 'exwm-input-focus-in-hook 'efs/configure-window-by-class)

  (setq exwm-layout-show-all-buffers t)
  (setq exwm-workspace-show-all-buffers t)
  (setq exwm-workspace-warp-cursor t)
  ;; (setq mouse-autoselect-window t
  ;;       focus-follows-mouse t)

  ;; (setq exwm-workspace-minibuffer-position 'bottom)
  ;; (add-hook 'exwm-randr-screen-change-hook #'my-exwm-workspace-transparency)
  ;; (add-hook 'exwm-manage-finish-hook #'my-exwm-workspace-transparency)


  ;; These keys should always pass through to Emacs
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
      ?\C-\ ;; Ctrl+Space
      ?\i
      ?\\
      ?\M-m))

        ;; (push ?\i exwm-input-prefix-keys)
        ;; (push (kbd "C-SPC") exwm-input-prefix-keys)
        ;; (push (kbd "M-m") exwm-input-prefix-keys)
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

          ([?\s-v] . evil-window-vsplit)
          ([?\s-s] . evil-window-split)
          ([?\s-c] . evil-window-delete)

          ([?\s-,] . switch-to-buffer)
          ([?\s-.] . find-file)
          ([?\s-`] . (lambda () (interactive) (exwm-workspace-switch-create 0)))
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

        ;; Execute shell commands to set keyboard repeat rate
        (shell-command "xset r rate 220 30")

        ;; (add-to-list 'load-path "/home/anthe/.config/emacs/.local/elpa/exwm-0.33")
        (require 'exwm-randr)
        (exwm-randr-mode)
        ;; disable this after having saved your config with autorandr --save <name-of-confg>
        (shell-command "xrandr" nil "xrandr --output eDP-1 --primary --mode 1920x1200 --pos 0x0 --rotate normal --output HDMI-1 --off --output DP-1 --mode 2560x1440 --pos 0x0 --rotate normal --output DP-2 --off")

        (setq exwm-randr-workspace-monitor-plist '(2 "DP-1" 3 "DP-1"))
        ;; (setq exwm-randr-workspace-monitor-plist '(2 "HDMI-1" 3 "DP-1"))

        ;; FIXME: check whether this works
        ;; (add-hook 'exwm-randr-screen-change-hook #'efs/update-displays)
        ;; (efs/update-displays)

        (efs/set-wallpaper)
        ;; Function to configure touchpad settings
        ;; (defun configure-touchpad ()
        ;; "Configure touchpad settings using xinput."
        ;; (let ((touchpad-id
        ;;         (shell-command-to-string "xinput | rg Touchpad | awk -F'id=' '{print $2}' | awk '{print $1}'")))
        ;; (shell-command (format "xinput set-prop %s \"libinput Tapping Enabled\" 1" touchpad-id))
        ;; (shell-command (format "xinput set-prop %s \"libinput Natural Scrolling Enabled\" 1" touchpad-id))))

        ;; ;; Call the function to configure touchpad
        ;; (configure-touchpad)

        ;; (defun brightness-up ()
        ;;   "Increase brightness by 10%"
        ;; (interactive)
        ;; (shell-command "brightnessctl set +5%"))

        ;; (defun brightness-down ()
        ;;   "Decrease brightness by 10%"
        ;; (interactive)
        ;; (shell-command "brightnessctl set 5%-"))

        ;; (global-set-key (kbd "<XF86MonBrightnessUp>") 'brightness-up)
        ;; (global-set-key (kbd "<XF86MonBrightnessDown>") 'brightness-down)

        (defun redshift-down ()
          "Increase brightness by 10%"
        (interactive)
        (start-process-shell-command "redshift" nil "redshift -O 6000"))

        (defun redshift-up ()
          "Decrease brightness by 10%"
        (interactive)
        (start-process-shell-command "redshift" nil "redshift -x"))

        (exwm-input-set-key  (kbd "M-<XF86MonBrightnessUp>") 'redshift-up)
        (exwm-input-set-key  (kbd "M-<XF86MonBrightnessDown>") 'redshift-down)

        (defun flameshot-gui ()
        "Take a screen shot with flameshot (gui version)"
        (interactive)
        (start-process-shell-command "flameshot" nil "flameshot gui"))

        (exwm-input-set-key (kbd "<print>") 'flameshot-gui)

        (setq desktop-environment-screenshot-directory "~/documents/pictures/Screenshots")

        (exwm-input-set-key (kbd "s-m") 'exwm-toggle-local-mode)
        (exwm-input-set-key (kbd "s-o c") 'citar-open)
        (exwm-input-set-key (kbd "s-o v") 'multi-vterm)
        (exwm-input-set-key (kbd "s-o g") 'gptel)
        ;; (exwm-input-set-key (kbd "s-.") 'find-file)
        (exwm-input-set-key (kbd "s-b k") 'kill-current-buffer)
        (exwm-input-set-key (kbd "s-b R") 'rename-buffer)
        (exwm-input-set-key (kbd "s-f r") 'consult-recent-file)
        (exwm-input-set-key (kbd "s--") (lambda () (interactive) (exwm-layout-shrink-window-horizontally 50)))
        (exwm-input-set-key (kbd "s-=") (lambda () (interactive) (exwm-layout-enlarge-window-horizontally 50)))
        (exwm-input-set-key (kbd "s-_") (lambda () (interactive) (exwm-layout-shrink-window 50)))
        (exwm-input-set-key (kbd "s-+") (lambda () (interactive) (exwm-layout-enlarge-window 50)))
        (exwm-input-set-key (kbd "s-<right>") (lambda () (interactive) (exwm-floating-move 20 0)))
        (exwm-input-set-key (kbd "s-<left>") (lambda () (interactive) (exwm-floating-move -20 0)))
        (exwm-input-set-key (kbd "s-<down>") (lambda () (interactive) (exwm-floating-move 0 20)))
        (exwm-input-set-key (kbd "s-<up>") (lambda () (interactive) (exwm-floating-move 0 -20)))
        (shell-command "bash ~/.dotfiles/.config-touchpad.sh")
        (exwm-input-set-key  (kbd "s-h") 'windmove-left-or-hide-floating)
        (exwm-input-set-key (kbd "s-t f") 'exwm-floating-toggle-floating)

        (exwm-input-set-key (kbd "s-`") '(lambda () (interactive) (exwm-workspace-switch-create 0)))
        (exwm-input-set-key (kbd "s-0") '(lambda () (interactive) (exwm-workspace-switch-create 10)))

        (add-hook 'exwm-manage-finish-hook (lambda () (call-interactively #'exwm-input-release-keyboard)))
        (advice-add #'exwm-input-grab-keyboard :after (lambda (&optional id) (evil-normal-state)))
        (advice-add #'exwm-input-release-keyboard :after (lambda (&optional id) (evil-insert-state)))
        (general-define-key
        :keymaps 'exwm-mode-map
        :states 'normal
        "i" #'exwm-input-release-keyboard)

        ;; (exwm-input-set-key (kbd "s-<escape>") #'exwm-input-toggle-keyboard)
        (exwm-input-set-key (kbd "<f9>") #'exwm-input-toggle-keyboard)

        ;; ("matplotlib" (exwm-floating-toggle-floating))

  (exwm-wm-mode))

(add-to-list 'load-path "/home/anthe/.config/emacs/.local/elpa/desktop-environment-20230903.1229/")
(use-package desktop-environment
  :after exwm
  :config (desktop-environment-mode)
  :custom
  (desktop-environment-brightness-small-increment "2%+")
  (desktop-environment-brightness-small-decrement "2%-")
  (desktop-environment-brightness-normal-increment "5%+")
  (desktop-environment-brightness-normal-decrement "5%-"))

(add-to-list 'load-path "/home/anthe/.config/emacs/.local/evil-exwm-state.el")

;; NOTE: not a solution yet, because I couldn't remap ESC which I really need in some ewxm windows (such as remote Emacs)
;; (use-package! exwm-evil
;;   :after exwm
;;   :config
;;   (add-hook 'exwm-manage-finish-hook #'enable-exwm-evil-mode)
;;   ;; (cl-pushnew 'escape exwm-input-prefix-keys)

;;   ;; If you want to force enable exwm-evil-mode in any buffer, use:
;;   ;; (exwm-evil-enable-unconditionally)

;;   ;; We will disable `C-c' in insert state.
;;   (define-key exwm-mode-map (kbd "C-c") nil)
;;   (define-key exwm-mode-map (kbd "ESC") nil)

;;   (map! :map exwm-mode-map
;;         :localleader
;;         (:prefix ("d" . "debug")
;;          :desc "Clear debug buffer" "l" #'xcb-debug:clear
;;          :desc "Insert mark into the debug buffer" "m" #'xcb-debug:mark
;;          :desc "Enable debug logging" "t" #'exwm-debug)
;;         :desc "Toggle fullscreen" "f" #'exwm-layout-toggle-fullscreen
;;         :desc "Hide floating window" "h" #'exwm-floating-hide
;;         :desc "Send next key" "q" #'exwm-input-send-next-key
;;         :desc "Toggle floating" "SPC" #'exwm-floating-toggle-floating
;;         :desc "Send escape" "e e" (cmd! (exwm-evil-send-key 1 'escape))
;;         :desc "Toggle modeline" "m" #'exwm-layout-toggle-mode-line))

(defun my-exwm-workspace-switch-to-buffer (orig-func buffer-or-name &rest args)
(when buffer-or-name
(if (or exwm--floating-frame
        (with-current-buffer buffer-or-name exwm--floating-frame))
    (exwm-workspace-switch-to-buffer buffer-or-name)
    (apply orig-func buffer-or-name args))))
        (derived-mode-p 'exwm-mode)

(advice-add 'switch-to-buffer :around 'my-exwm-workspace-switch-to-buffer)
(advice-add 'ivy--switch-buffer-action :around 'my-exwm-workspace-switch-to-buffer)
;; (advice-add 'exwm-floating-toggle-floating :before 'delete-other-windows)

;; remap capslock to ctrl
(shell-command "xmodmap ~/.dotfiles/doom/Xmodmap")



(global-set-key (kbd "s-l") 'windmove-right)
(global-set-key (kbd "s-x") 'evil-window-exchange)

(defvar is-window-floating nil
  "is the current buffer floating?")

(defun windmove-left-or-hide-floating ()
  (interactive)
  (if (eq exwm--floating-frame nil)
      (progn
        (setq is-window-floating nil))
      (progn
        (setq is-window-floating t)))
  (if is-window-floating
      (exwm-floating-hide)
    (windmove-left)))


;; (add-to-list 'load-path "/home/anthe/.config/emacs/.local/elpa/desktop-environment-/")
;; (require 'desktop-environment)
;; (use-package desktop-environment
;;   :after exwm
;;   :config (desktop-environment-mode)
;;   :custom
;;   (desktop-environment-brightness-small-increment "2%+")
;;   (desktop-environment-brightness-small-decrement "2%-")
;;   (desktop-environment-brightness-normal-increment "5%+")
;;   (desktop-environment-brightness-normal-decrement "5%-")

(add-to-list 'load-path "/home/anthe/.config/emacs/.local/other")

;; ---------- ivy and counsel -------------------
;; Customize the appearance of the ivy-current-match face
(custom-set-faces!
  '(ivy-current-match :background "#21242b"))

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

(require 'counsel)
;; Configure counsel
(use-package counsel
:custom
(counsel-linux-app-format-function #'counsel-linux-app-format-function-name-only))

;; (setq vertico-multiform-mode nil)

;;; desktop.el ends here
