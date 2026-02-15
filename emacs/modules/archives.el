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


;; (setq gc-cons-threshold 100000000)
;; (setq read-process-output-max 10000000)
;; (setq bidi-inhibit-bpa t)



;; (package! eldoc :pin "a233b42b0e32154d2fe00d25a8b89329e81450f2")

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



;; To reproduce 'ENTER' behavior in other editors in evil mode normal node
;; (evil-define-key 'normal 'global (kbd "RET") (kbd "o<escape>"))
;; (evil-define-key 'normal 'global (kbd "<S-return>") (kbd "O<escape>"))



      ;   "Send the current line or region to the Python shell."
;;   (interactive)
;;   (if (use-region-p)
;;       (python-shell-send-region (region-beginning) (region-end))
;;     (python-shell-send-line)))

;; (defun open-ncview (file)
;;   "Open FILE with ncview."
;;   (interactive "fOpen .nc file: ")
;;   (when (y-or-n-p (format "Open '%s' with ncview?" file))
;;     (let ((original-buffer (current-buffer)))  ;; Save the current buffer
;;       (start-process "ncview" nil "ncview" file)  ;; Open with ncview
;;       (kill-buffer original-buffer)                ;; Kill the current buffer
;;       ;; Switch back to the original buffer
;;       (switch-to-buffer original-buffer))))

;; (defun my-find-file-hook ()
;;   "Open .nc files with ncview after confirmation."
;;   (when (and buffer-file-name
;;              (string-equal (file-name-extension buffer-file-name) "nc"))
;;     (open-ncview buffer-file-name)))

;; (add-hook 'find-file-hook 'my-find-file-hook)


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


;; (defvar lawlist-blue (make-face 'lawlist-blue))
;; (set-face-attribute 'lawlist-blue nil
;;   :background nil :foreground "#51afef" :bold t)

;; (defvar lawlist-orange (make-face 'lawlist-orange))
;; (set-face-attribute 'lawlist-orange nil
;;   :background nil :foreground "#ECBE7B" :bold t :italic nil)

;; (defvar lawlist-keywords-01
;;   (concat "\\b\\(?:"
;;     (regexp-opt (list "from" "import" "for" ))
;;   "\\)\\b"))

;; (defvar lawlist-keywords-02
;;   (concat "\\b\\(?:"
;;     (regexp-opt (list "foo" "bar" "def" ))
;;   "\\)\\b"))

;; (add-hook 'window-setup-hook 'toggle-frame-maximized t)
;; (add-hook 'window-setup-hook #'toggle-frame-transparency)
;; (add-hook 'window-setup-hook #'toggle-transparency t)

;; (setq explicit-shell-file-name "/bin/bash")
;; (setq shell-file-name "bash")
;; (setq shell-command-switch "-ic")


;; (use-package lsp-pyright
;;   :ensure t
;;   :hook (python-mode . (lambda ()
;;                          (require 'lsp-pyright)
;;                          (lsp-deferred))))

;; (setq lsp-pyright-langserver-command-args
;;       '("--stdio" "--verbose"))

;; ;; (use-package tree-sitter
;; ;;   :ensure t
;; ;;   :config
;; ;;   (global-tree-sitter-mode)
;; ;;   (add-hook 'python-mode-hook #'tree-sitter-hl-mode))

;; ;; (use-package tree-sitter-langs
;;   ;; :ensure t)
;; ;; Enable elpy for better Python support
;; ;; (elpy-enable)

;; (use-package! jedi
;;   :init
;;   (add-hook 'python-mode-hook 'jedi:setup)
;;   (setq jedi:complete-on-dot t))

(setq treesit-language-source-alist
   '((bash "https://github.com/tree-sitter/tree-sitter-bash")
     (cmake "https://github.com/uyha/tree-sitter-cmake")
     ;; (css "https://github.com/tree-sitter/tree-sitter-css")
     (elisp "https://github.com/Wilfred/tree-sitter-elisp")
     ;; (go "https://github.com/tree-sitter/tree-sitter-go")
     ;; (html "https://github.com/tree-sitter/tree-sitter-html")
     ;; (javascript "https://github.com/tree-sitter/tree-sitter-javascript" "master" "src")
     ;; (json "https://github.com/tree-sitter/tree-sitter-json")
     (make "https://github.com/alemuller/tree-sitter-make")
     ;; (markdown "https://github.com/ikatyang/tree-sitter-markdown")
     (python "https://github.com/tree-sitter/tree-sitter-python")
     ;; (toml "https://github.com/tree-sitter/tree-sitter-toml")
     ;; (tsx "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
     ;; (typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
     ;; (yaml "https://github.com/ikatyang/tree-sitter-yaml")
     ))


;; (use-package tramp
;;   :ensure t
;;   :config
;;   (setq tramp-default-remote-shell "/bin/bash")
;;   (add-to-list 'tramp-remote-path 'tramp-own-remote-path))


(provide 'archives)
;;; archives.el ends here
