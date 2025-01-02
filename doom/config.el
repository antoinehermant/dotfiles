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
(add-to-list 'default-frame-alist '(alpha-background . 95))

(set-face-attribute 'default nil :height 115)

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
              '(95 . 95) '(100 . 100)))))

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



;; ------------------------- Functions ------------------------------

(defun toggle-frame-all ()
  "Toggle my frame for my workflow."
  (interactive)
  (if (not (frame-parameter nil 'fullscreen))  ; Check if not in fullscreen
      (set-frame-parameter nil 'alpha-background 95)
      ())
  (toggle-frame-fullscreen)
  (toggle-frame-transparency)
  ;; (toggle-frame-transparency)
  )

;; -------------------------- Keybindings ---------------------------
;; (global-set-key (kbd "KEY_SEQUENCE") 'command)
;; (global-unset-key (kbd "KEY_SEQUENCE"))
;; (add-hook 'mode-hook
;;           (lambda ()
;;             (local-set-key (kbd "KEY_SEQUENCE") 'command)))

(global-set-key (kbd "<f9>") 'toggle-frame-all)



;; ------------------------ Python ----------------------------------
;;

(require 'python)

;; Enable elpy for better Python support
(elpy-enable)

(use-package! elpy
  :init
  (elpy-enable))

(use-package! jupyter)
(setq jupyter-repl-echo-eval-p t) ; send to repl instead of minibuffer
(use-package! python-mode
  :hook (python-mode . lsp-deferred))

(add-hook 'python-mode-hook 'code-cells-mode-maybe)

(use-package! company
  :hook (python-mode . company-mode))

(use-package! flycheck
  :hook (python-mode . flycheck-mode))

(use-package! jedi
  :init
  (add-hook 'python-mode-hook 'jedi:setup)
  (setq jedi:complete-on-dot t))
