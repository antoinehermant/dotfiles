;;; anthe-company.el --- Completion as you type -*- lexical-binding: t; -*-
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Company, in Doom's child frame (company-box), from two characters typed.
;;
;;  What it offers, first to answer winning:
;;  - a path, anywhere, from ./ ~/ ../ or /: company-files; TAB after one
;;    opens it, as on a single /;
;;  - in code: the language's completion (LSP or the mode's), then snippets,
;;    then the words of the buffer in code;
;;  - in org: org-roam's titles (a title chosen becomes a link) with the
;;    words of the buffer, from 4 letters, together; org's own too (links in
;;    [[, tags, #+ keywords);
;;  - in text: the words of the buffer.
;;  The titles match where one of their words starts as typed ("git": "Git",
;;  "GitHub", "PISM git"; not "digital"), not anywhere as in the minibuffer
;;  (orderless), which offered long lists.  Dropped: the
;;  dictionary's words (ispell), and jedi outside Python.
;;
;;  The popup takes the bar's colours, its corners rounded (anthe-windows.el).
;;
;;; Code:

(use-package! company
  :init
  (global-company-mode)
  :hook (lsp-mode . company-mode)
  :bind (:map company-active-map
              ("<tab>" . 'company-complete-selection)
              ("C-l" . 'company-complete-selection)
              ("C-j" . 'company-select-next)
              ("C-k" . 'company-select-previous)
              ("C-h" . 'company-abort))
  :custom
  (company-minimum-prefix-length 2)
  (company-tooltip-align-annotations t)
  (company-require-match 'never)
  (company-idle-delay 0.2)
  (company-tooltip-idle-delay 0)
  (company-show-quick-access t)
  (company-dabbrev-minimum-length 4)
  (company-dabbrev-downcase nil))

;; RET is a new line, TAB completes
(with-eval-after-load 'company
  (define-key company-active-map (kbd "<return>") nil)
  (define-key company-active-map (kbd "RET") nil))

;;; What it offers

;; Each mode's backends come before these (Doom's `set-company-backend!')
(setq-default company-backends '(company-capf company-dabbrev-code))

;; Text and org: the words of the buffer only, no snippets nor dictionary
(set-company-backend! 'text-mode 'company-dabbrev)
(setq text-mode-ispell-word-completion nil)

;; Org: org's and org-roam's completion with the buffer's words, together
(set-company-backend! 'org-mode '(company-capf company-dabbrev))

(defun anthe/company-word-start (component)
  "An orderless matching style: COMPONENT at the start of a word."
  (rx-to-string `(seq word-start ,component)))

(defun anthe/company-org-matching-h ()
  "In org, company's completions match at the start of any word, the case
ignored while typed in lower case: orderless only (Doom's
`+vertico-company-completion-styles' tried the whole start first, then
anywhere), at a word's start; the minibuffer, its own buffer, keeps it as is."
  (setq-local +vertico-company-completion-styles '(orderless)
              orderless-matching-styles '(anthe/company-word-start)))

(add-hook 'org-mode-hook #'anthe/company-org-matching-h)

(defun anthe/company-roam-titles-a (fn)
  "Org-roam's titles after a word: offered when one of their words starts
as it, else not at all, the next completion answering."
  (when-let* ((result (funcall fn))
              (regexp (anthe/company-word-start
                       (buffer-substring-no-properties (nth 0 result) (nth 1 result))))
              ((let ((case-fold-search t))
                 (seq-some (lambda (title) (string-match-p regexp title)) (nth 2 result)))))
    ;; Not :exclusive no, which needs a title starting as the word
    (append (take 3 result) (map-delete (copy-sequence (nthcdr 3 result)) :exclusive))))

(after! org-roam
  (advice-add 'org-roam-complete-everywhere :around #'anthe/company-roam-titles-a))

(defun anthe/company-files-first (&rest _)
  "Paths before anything else: company-files answers only on one."
  (setq-local company-backends
              (cons 'company-files (remove 'company-files company-backends))))

(add-hook 'company-mode-hook #'anthe/company-files-first 90)
(advice-add '+company-init-backends-h :after #'anthe/company-files-first)
(with-eval-after-load 'lsp-completion
  (add-hook 'lsp-completion-mode-hook #'anthe/company-files-first 90))

(defun anthe/company-path-p ()
  "Whether a path is before point, no popup open."
  (and (not company-candidates)
       (company-files 'prefix)))

(defun anthe/company-files ()
  "Complete the path before point."
  (interactive)
  (company-begin-backend 'company-files))

;; TAB after a path opens it; elsewhere TAB does as before (the filter
;; giving nothing, evil's insert state map answers)
(map! :map company-mode-map
      :i [tab] `(menu-item "" anthe/company-files :filter
                        ,(lambda (cmd) (when (anthe/company-path-p) cmd)))
      :i "TAB" `(menu-item "" anthe/company-files :filter
                        ,(lambda (cmd) (when (anthe/company-path-p) cmd))))

;;; The popup

(defun anthe/company-colours (&rest _)
  "The popup in the bar's colours, the selection as in the minibuffer."
  (let ((background (face-background 'mode-line nil t))
        (selection (face-background 'region nil t))
        (match (face-foreground 'font-lock-function-name-face nil t))
        (dim (face-foreground 'shadow nil t)))
    (pcase-dolist (`(,face . ,attributes)
                   `((company-tooltip :background ,background)
                     (company-tooltip-selection :background ,selection :weight bold)
                     (company-tooltip-common :foreground ,match :weight bold)
                     (company-tooltip-common-selection :foreground ,match :weight bold)
                     (company-tooltip-annotation :foreground ,dim :background unspecified)
                     (company-tooltip-annotation-selection :foreground ,dim :background unspecified)
                     (company-tooltip-quick-access :foreground ,dim)
                     (company-tooltip-quick-access-selection :foreground ,dim)
                     (company-box-background :background ,background)
                     (company-box-selection :background ,selection :weight bold)
                     (company-box-annotation :foreground ,dim)
                     (company-box-scrollbar
                      :background ,(face-background (if (facep 'anthe-bar-current-workspace)
                                                        'anthe-bar-current-workspace
                                                      'highlight)
                                                    nil t))))
      (when (facep face)
        (apply #'set-face-attribute face nil attributes)))
    ;; The popups' frames, past the lines' ends
    (dolist (frame (frame-list))
      (when (string-prefix-p " *company-box"
                             (buffer-name (window-buffer (frame-root-window frame))))
        (set-frame-parameter frame 'background-color background)))))

(add-hook 'doom-load-theme-hook #'anthe/company-colours)
(with-eval-after-load 'company (anthe/company-colours))

(after! company-box
  (anthe/company-colours)
  ;; No border: the corners are rounded instead
  (setf (alist-get 'internal-border-width company-box-frame-parameters) 0)
  ;; Opaque, as the text in it: not see-through as the frames
  (setf (alist-get 'alpha-background company-box-frame-parameters) 100)
  (with-eval-after-load 'company-box-doc
    (setf (alist-get 'alpha-background company-box-doc-frame-parameters) 100))
  ;; The frame's shape follows the popup
  (when (fboundp 'anthe/window-gaps--update)
    (advice-add 'company-box--display :after #'anthe/window-gaps--update)))

(provide 'anthe-company)
;;; anthe-company.el ends here
