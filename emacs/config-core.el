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
;;

;; Removes the background color that was set in the early init (which turns the annoying white splash screen from vanilla emacs to a color)
(setq default-frame-alist (assq-delete-all 'background-color default-frame-alist))
(setq default-frame-alist (assq-delete-all 'foreground-color default-frame-alist))

(setq doom-theme 'doom-ayu-dark)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
;; (setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!


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

;; FIXME: not sure if this does anything usefull, need to check. Or at least it does not allow to retrieve environment variables (set in .bashrc) 
;; (use-package! exec-path-from-shell
;;   :ensure t
;;   :config
;;   (when (memq window-system '(mac ns x))
;;   (exec-path-from-shell-initialize)))
(require 'package)
(add-to-list 'package-archives
             '("melpa" . "http://melpa.org/packages/") t)

(when (memq window-system '(mac ns x))
  (exec-path-from-shell-initialize))

(setq doom-scratch-initial-major-mode 'org-mode)

(set-face-attribute 'default nil :height 109)
;; (set-face-attribute 'default nil :height 200)

(display-battery-mode)
(display-time-mode)
(display-line-numbers-mode)

(setq display-line-numbers-type 'relative)

(custom-set-faces!
  '(line-number :foreground "#ffffff")
  '(line-number-current-line :weight bold :foreground "#51afef" :slant normal) ; Explicitly set slant
  '(font-lock-keyword-face :foreground "#51afef")
)

(setq image-use-external-converter t)
(setq image-converter 'imagemagick)

(setq large-file-warning-threshold 100000000)

;; Keybindings
(map! :leader
      :desc "Find file at point" "f f" #'find-file-at-point
      :desc "Wrap lines" "t w" #'toggle-truncate-lines
      :desc "async shell" "&" #'async-shell-command)

(global-set-key (kbd "C-<left>") 'shrink-window-horizontally)
(global-set-key (kbd "C-<right>") 'enlarge-window-horizontally)
(global-set-key (kbd "C-<up>") 'enlarge-window)
(global-set-key (kbd "C-<down>") 'shrink-window)

(provide 'config-core)
;;; config-core.el ends here
