;;; anthe-vterm.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Maintainer: anthe <anthe@inspiron>
;; Created: February 15, 2026
;; Modified: February 15, 2026
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/anthe/anthe-vterm
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(require 'vterm)
(add-to-list 'load-path "~/.config/emacs/.local/straight/repos/vterm-toggle/")
(use-package! vterm-toggle)
(add-to-list 'load-path "~/.config/emacs/.local/straight/repos/multi-vterm/")
(use-package! multi-vterm)

(defun my-sh-mode-setup ()
  (map! :map sh-mode-map
        :leader
        :desc "Execute region or line in vterm" "v r" #'multi-vterm-execute-region-or-current-line))

(add-hook 'sh-mode-hook #'my-sh-mode-setup)
;; (defun my/vterm-execute-region-or-current-line ()
;;   "Insert text of current line in vterm and execute."
;;   (interactive)
;;   (require 'vterm)
;;   (eval-when-compile (require 'subr-x))
;;   (let ((command (if (region-active-p)
;;                      (string-trim (buffer-substring
;;                                    (save-excursion (region-beginning))
;;                                    (save-excursion (region-end))))
;;                    (string-trim (buffer-substring (save-excursion
;;                                                     (beginning-of-line)
;;                                                     (point))
;;                                                   (save-excursion
;;                                                     (end-of-line)
;;                                                     (point)))))))
;;     (let* ((buf (current-buffer))
;;            (buffer-name (buffer-name buf))
;;            (vterm-buffer-name (concat "*vterm-" buffer-name "*")))
;;       (unless (get-buffer vterm-buffer-name)
;;         (vterm)
;;         (rename-buffer vterm-buffer-name))
;;       (display-buffer vterm-buffer-name t)
;;       (switch-to-buffer-other-window vterm-buffer-name)
;;       (vterm--goto-line -1)
;;       (message command)
;;       (vterm-send-string command)
;;       (vterm-send-return)
;;       (switch-to-buffer-other-window buf)

(setq vterm-max-scrollback 10000)
(setq vterm-kill-buffer-on-exit t)
(setq vterm-visual-flash-delay 0.1)

;; UNSET mouse drag in evil mode
;; (global-unset-key [drag-mouse-1])
;; (global-set-key [drag-mouse-1])

(defun my-vterm-mode-hook ()
  (setq vterm-mouse-mode 0)
  (setq vterm-scroll-on-output t)
  (setq vterm-scroll-on-keystroke t))

(add-hook 'vterm-mode-hook 'my-vterm-mode-hook)

(defun multi-vterm-execute-region-or-current-line ()
  "Insert text of current line in multi-vterm and execute."
  (interactive)
  (require 'multi-vterm)
  (eval-when-compile (require 'subr-x))
  (let ((command (if (region-active-p)
                     (string-trim (buffer-substring
                                   (save-excursion (region-beginning))
                                   (save-excursion (region-end))))
                   (string-trim (buffer-substring (save-excursion
                                                    (beginning-of-line)
                                                    (point))
                                                  (save-excursion
                                                    (end-of-line)
                                                    (point)))))))
    (let* ((buf (current-buffer))
           (buffer-name (buffer-name buf))
           (vterm-buffer-name (concat "*multi-vterm-" buffer-name "*")))
      (unless (get-buffer vterm-buffer-name)
        (multi-vterm)
        (rename-buffer vterm-buffer-name))
      (display-buffer vterm-buffer-name t)
      (switch-to-buffer-other-window vterm-buffer-name)
      (let ((vterm-buffer (get-buffer vterm-buffer-name)))
        (with-current-buffer vterm-buffer
          (vterm-send-string command)
          (vterm-send-return)))
      (switch-to-buffer-other-window buf)
      )))
;;                                         ; Keybindings
;; (map! :leader
;;       :desc "Switch to shell buffer" "b t" #'switch-to-shell-buffer
;;       :desc "New vterm (multi-vterm)" "v" #'multi-vterm
;;       :desc "Next shell buffer" "t n" #'my-next-shell-buffer
;;       :desc "Previous shell buffer" "t p" #'my-previous-shell-buffer)

(defvar my-shell-buffer-list nil
  "List of current shell-like buffers.")

(defun my-shell-buffer-p (buffer)
  "Return t if BUFFER is a shell-like buffer."
  (with-current-buffer buffer
    (or (derived-mode-p 'shell-mode)
        (derived-mode-p 'term-mode)
        (derived-mode-p 'vterm-mode)
        (derived-mode-p 'eshell-mode)
        (derived-mode-p 'comint-mode))))

(defun my-update-shell-buffer-list ()
  "Update the list of shell-like buffers."
  (setq my-shell-buffer-list
        (seq-filter #'my-shell-buffer-p (buffer-list))))

(defun switch-to-shell-buffer ()
  "Switch to a shell-like buffer using minibuffer completion."
  (interactive)
  (my-update-shell-buffer-list)
  (let* ((buffer-names (mapcar #'buffer-name my-shell-buffer-list))
         (selected-buffer (completing-read "Switch to shell: " buffer-names nil t)))
    (when selected-buffer
      (switch-to-buffer selected-buffer))))

(defun my-cycle-shell-buffer (direction)
  "Cycle to the next or previous shell buffer.
DIRECTION should be 1 for next, -1 for previous."
  (my-update-shell-buffer-list)
  (when my-shell-buffer-list
    (let* ((current (current-buffer))
           (pos (seq-position my-shell-buffer-list current))
           (next-pos (mod (+ (or pos -1) direction) (length my-shell-buffer-list))))
      (switch-to-buffer (nth next-pos my-shell-buffer-list)))))

(defun my-next-shell-buffer ()
  "Switch to the next shell buffer."
  (interactive)
  (my-cycle-shell-buffer 1))

(defun my-previous-shell-buffer ()
  "Switch to the previous shell buffer."
  (interactive)
  (my-cycle-shell-buffer -1))

;; (defun switch-to-shell-buffer ()
;;   "Switch to a shell-like buffer using minibuffer completion."
;;   (interactive)
;;   (let* ((shell-buffers (--filter (with-current-buffer it
;;                                     (or (derived-mode-p 'shell-mode)
;;                                         (derived-mode-p 'term-mode)
;;                                         (derived-mode-p 'vterm-mode)
;;                                         (derived-mode-p 'eshell-mode)
;;                                         (derived-mode-p 'comint-mode)))
;;                                   (buffer-list)))
;;          (buffer-names (mapcar #'buffer-name shell-buffers))
;;          (selected-buffer (completing-read "Switch to shell: " buffer-names nil t)))
;;     (when selected-buffer
;;       (switch-to-buffer selected-buffer))))

(map! :leader
      :desc "New vterm (multi-vterm)" "V" #'multi-vterm
      :desc "Next vterm (multi-vterm)" "v n" #'multi-vterm-next
      :desc "Previous vterm (multi-vterm)" "v p" #'multi-vterm-prev
      :desc "Execute region of line in vterm" "v r" #'multi-vterm-execute-region-or-current-line
      :desc "Next shell buffer" "t n" #'my-next-shell-buffer
      :desc "Previous shell buffer" "t p" #'my-previous-shell-buffer
      :desc "Switch to shell buffer" ">" #'switch-to-shell-buffer
      :desc "Switch to Firefox buffer" "b f" #'my/switch-to-firefox-buffer)

(provide 'anthe-vterm)
;;; anthe-vterm.el ends here
