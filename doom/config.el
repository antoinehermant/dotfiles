;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.


;; ---------------------------- GUI configuration -------------------------------------
;; (set-frame-parameter (selected-frame) 'alpha '(90 . 90))  ; Adjust transparency

;; (set-frame-parameter nil 'alpha-background 95)
;; (add-to-list 'default-frame-alist '(alpha-background . 95))

(add-hook 'server-switch-hook #'raise-frame)
(add-hook 'server-switch-hook (lambda () (select-frame-set-input-focus (selected-frame))))

(set-face-attribute 'default nil :height 109)

(use-package! disable-mouse
   :ensure t
   :config
   (global-disable-mouse-mode t))

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
              '(90 . 90) '(100 . 100)))))

;; (add-to-list 'initial-frame-alist '(fullscreen . fullboth))
;;(add-to-list 'default-frame-alist '(fullscreen . maximized))
;; (add-hook 'server-after-make-frame-hook
;;           (lambda ()
;;             (select-frame-set-input-focus (selected-frame))))

(add-hook 'window-setup-hook #'toggle-frame-maximized)
;; (add-hook 'window-setup-hook #'toggle-frame-fullscreen)
;; (add-hook 'window-setup-hook 'toggle-frame-maximized t)
;; (add-hook 'window-setup-hook #'toggle-frame-transparency)
(add-hook 'window-setup-hook #'toggle-transparency t)



;; (setq +popup--display-buffer-alist
;;       (append +popup--display-buffer-alist
;;               '(("^\\*vterminal"  ; Match all multi-vterm instances
;;                  (+popup-buffer)
;;                  (actions)
;;                  (side . bottom)
;;                  (size . 0.25)
;;                  (window-width . 40)
;;                  (window-height . 0.25)
;;                  (slot)
;;                  (vslot . -4)
;;                  (window-parameters
;;                   (ttl . 0)
;;                   (quit)
;;                   (select . t)
;;                   (modeline)
;;                   (autosave)
;;                   (transient . t)
;;                   (no-other-window . t))))))


;; (defun my-update-system-stats ()
;;   "Update the mode line with CPU and RAM usage."
;;   (let* ((cpu (string-trim (shell-command-to-string "mpstat 1 1 | tail -1 | awk '{print 100 - $12}'")))
;;          (mem (string-trim (shell-command-to-string "free | awk '/^Mem/ {print $3 / $2 * 100 }'"))))
;;     (setq my-system-stats-string
;;           (format "CPU: %s%% RAM: %s" cpu mem))))

;; (defun my-display-system-stats ()
;;   "Display system stats in the mode line."
;;   (my-update-system-stats)
;;   (setq global-mode-string '(:eval my-system-stats-string))

;;   ;; (setq global-mode-string my-system-stats-string))

;; ;; Update every 5 seconds
;; (run-with-timer 0 5 'my-display-system-stats)

;; ;; Initialize the variable
;; (setq my-system-stats-string "")





(use-package! popper
  :ensure t ; or :straight t
  :bind (("C-`"   . popper-toggle)
         ("M-`"   . popper-cycle)
         ("C-M-`" . popper-toggle-type))
  :init
  (setq popper-reference-buffers
        '("^\\*Messages\\*"
          "^Output\\*$"
          "^\\*Async Shell Command\\*"
          "^\\*vterm"
          ;; "^\\*vterminal<\\([0-9]+\\)>\\*"  ; Match all vterminal instances
          "^*compilation"
          help-mode
          compilation-mode))   ; Add closing parenthesis here
  (popper-mode +1)
  (popper-echo-mode +1))                ; For echo area

(setq popper-window-height (floor (* (frame-height) 0.25)))

;; Define global variables to store state
(defvar vterm-popper-original-height nil
  "Stores the original height of the vterm popup window.")
(defvar vterm-popper-expanded nil
  "Boolean flag to track if the vterm popup is expanded.")
(defvar vterm-popper-original-height nil
  "Stores the original height of the vterm popup window.")
(defvar vterm-popper-expanded nil
  "Boolean flag to track if the vterm popup is expanded.")

(defun toggle-vterm-popper-size ()
  "Toggle vterm popup window size between default and 3/4 of the screen height."
  (interactive)
  (let* ((vterm-window (seq-find (lambda (window)
                                   (string-match-p "^\\*vterm" (buffer-name (window-buffer window))))
                                 (window-list)))
         (frame-height (frame-height))
         (expanded-height (floor (* frame-height 0.80))))
    (when vterm-window
      (if vterm-popper-expanded
          (progn
            (window-resize vterm-window
                           (- vterm-popper-original-height (window-height vterm-window)))
            (setq vterm-popper-expanded nil))
        (setq vterm-popper-original-height (window-height vterm-window))
        (window-resize vterm-window
                       (- expanded-height (window-height vterm-window)))
        (setq vterm-popper-expanded t)))))

;; Bind the function to a key
(global-set-key (kbd "C-c `") 'toggle-vterm-popper-size)

;; ;; Match eshell, shell, term and/or vterm buffers
;; (setq popper-reference-buffers
;;       (append popper-reference-buffers
;;               '("\\*eshell*\\*$" eshell-mode ;eshell as a popup
;;                 "\\*shell*\\*$"  shell-mode  ;shell as a popup
;;                 "\\*term*\\*$"   term-mode   ;term as a popup
;;                 "\\*vterm*\\*$"  vterm-mode  ;vterm as a popup
;;                 )))


;; (after! vterm
;;   (set-popup-rule! "*doom:vterm-popup:main" :size 0.3 :vslot -4 :select t :quit nil :ttl 0)
;;   (defadvice! +vterm-init-popup (&rest _)
;;     :after 'popups-init
;;     (display-buffer (vterm-get-buffer-create "*doom:vterm-popup:main*"))))


;; ------------------------- Functions ------------------------------

(defun toggle-frame-all ()
  "Toggle my frame for my workflow."
  (interactive)
  (if (not (frame-parameter nil 'fullscreen))  ; Check if not in fullscreen
      ;; (set-frame-parameter nil 'alpha-background 95)
      ())
  (toggle-frame-fullscreen)
  ;; (toggle-frame-transparency)
  ;; (toggle-frame-transparency)
  )

;; -------------------------- Keybindings ---------------------------
;; (global-set-key (kbd "KEY_SEQUENCE") 'command)
;; (global-unset-key (kbd "KEY_SEQUENCE"))
;; (add-hook 'mode-hook
;;           (lambda ()
;;             (local-set-key (kbd "KEY_SEQUENCE") 'command)))

(global-set-key (kbd "<f9>") 'toggle-frame-all)


(global-set-key (kbd "M-n") #'scroll-up-line)
(global-set-key (kbd "M-p") #'scroll-down-line)
;(define-key repeat-map (kbd "M-n") #'scroll-up-line)
;(define-key repeat-map (kbd "M-p") #'scroll-down-line)

(defun open-ncview (file)
  "Open FILE with ncview."
  (interactive "fOpen .nc file: ")
  (when (y-or-n-p (format "Open '%s' with ncview?" file))
    (let ((original-buffer (current-buffer)))  ;; Save the current buffer
      (start-process "ncview" nil "ncview" file)  ;; Open with ncview
      (kill-buffer original-buffer)                ;; Kill the current buffer
      ;; Switch back to the original buffer
      (switch-to-buffer original-buffer))))

(defun my-find-file-hook ()
  "Open .nc files with ncview after confirmation."
  (when (and buffer-file-name
             (string-equal (file-name-extension buffer-file-name) "nc"))
    (open-ncview buffer-file-name)))

(add-hook 'find-file-hook 'my-find-file-hook)


;; ;; Define global variables to store state
;; (defvar vterm-popup-original-height nil
;;   "Stores the original height of the vterm popup window.")
;; (defvar vterm-popup-expanded nil
;;   "Boolean flag to track if the vterm popup is expanded.")

;; (defun toggle-vterm-popup-size ()
;;   "Toggle vterm popup window size between default and 3/4 of the screen height."
;;   (interactive)
;;   (let* ((vterm-window (get-buffer-window "*vterm*"))
;;          (frame-height (frame-height))
;;          (expanded-height (floor (* frame-height 0.80))))
;;     (when vterm-window
;;       (if vterm-popup-expanded
;;           (progn
;;             (window-resize vterm-window
;;                            (- vterm-popup-original-height (window-height vterm-window)))
;;             (setq vterm-popup-expanded nil))
;;         (setq vterm-popup-original-height (window-height vterm-window))
;;         (window-resize vterm-window
;;                        (- expanded-height (window-height vterm-window)))
;;         (setq vterm-popup-expanded t)))))

;; ;; Bind the function to a key
;; (global-set-key (kbd "C-c `") 'toggle-vterm-popup-size)



;; ------------------------ Python ----------------------------------
;;

(require 'python)

;; Enable elpy for better Python support
;; (elpy-enable)

;; (use-package! elpy
;;   :init
;;   (elpy-enable))

(use-package! jupyter)
(setq jupyter-repl-echo-eval-p t) ; send to repl instead of minibuffer
;; (use-package! python-mode
;;   :hook (python-mode . lsp-deferred))

(add-hook 'python-mode-hook 'code-cells-mode-maybe)

;; (use-package! company
;;   :hook (python-mode . company-mode))

(use-package! flycheck
  :hook (python-mode . flycheck-mode))

;; (use-package! jedi
;;   :init
;;   (add-hook 'python-mode-hook 'jedi:setup)
;;   (setq jedi:complete-on-dot t))


;; -----------------------------audio --------------------------------

(require 'emms-setup)
(emms-all)
(setq emms-player-list '(emms-player-vlc))

;; (defun open-mp3-in-vlc ()
;;   "Open MP3 file in VLC, starting VLC if necessary."
;;   (interactive)
;;   ;; (vlc-start)
;;   (vlc-add (buffer-file-name)))
;; (add-to-list 'auto-mode-alist '("\\.mp3\\'" . open-mp3-in-vlc))

(defun open-mp3-in-vlc ()
  "Open MP3 file in VLC, starting VLC if necessary."
  (interactive)
  (let ((original-buffer (previous-buffer))
        (file (buffer-file-name)))
 ;; (unless (shell-command-to-string "pgrep vlc")
  (kill-buffer (current-buffer))
  (switch-to-buffer original-buffer)
  (vlc-start)
  (sleep-for 1)
  (vlc-add file)))

(add-to-list 'auto-mode-alist '("\\.mp3\\'" . open-mp3-in-vlc))


;; (org-add-link-type "mp3" 'open-mp3-in-vlc) ; add the function to org file type


;; ------------------------- terminals ----------------------------
;;
(use-package multi-vterm :ensure t)

;; -------------------------- TRAMP ------------------------------

;; (require 'tramp)
;; (setq tramp-default-remote-shell "/bin/bash")
;; (add-to-list 'tramp-remote-path 'tramp-own-remote-path)

;; (use-package tramp
;;   :ensure t
;;   :config
;;   (setq tramp-default-remote-shell "/bin/bash")
;;   (add-to-list 'tramp-remote-path 'tramp-own-remote-path))


;; ------------------------ Specifics -----------------------------
;; An extra file next to config.el in case there are specific configuration
;; for a particular system such as a HPC

(when (file-exists-p (expand-file-name "specifics.el" doom-user-dir))
  (load (expand-file-name "specifics.el" doom-user-dir)))
