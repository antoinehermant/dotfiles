;;; anthe-qutebrowser.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Maintainer: anthe <anthe@inspiron>
;; Created: May 30, 2026
;; Modified: May 30, 2026
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/anthe/anthe-qutebrowser
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(add-to-list 'load-path "/home/anthe/.config/emacs/.local/other/qutebrowser.el/")

;; Define a simple function to send commands to qutebrowser via commandline
;; This doesn't depend on any qutebrowser.el internals
(defun anthe/qutebrowser-send-command (command)
  "Send COMMAND to qutebrowser via commandline."
  (interactive "MCommand: ")
  (start-process "qutebrowser-cmd" nil "qutebrowser" (concat ":" command)))

(require 'qutebrowser)
(require 'qutebrowser-consult)
(require 'qutebrowser-evil)
(require 'qutebrowser-doom-modeline)

;; Add key bindings to qutebrowser-exwm-mode-map
;; Use our simple command sender to avoid dependency issues
;; We use C-c z prefix to avoid conflicts with global bindings like text-scale-increase
;; (define-key qutebrowser-exwm-mode-map (kbd "C-c z i") 
;;             (lambda () (interactive) (anthe/qutebrowser-send-command "zoom-in") (message "Zoom in")))
;; (define-key qutebrowser-exwm-mode-map (kbd "C-c z o") 
;;             (lambda () (interactive) (anthe/qutebrowser-send-command "zoom-out") (message "Zoom out")))

;; To override the global C-= binding, we need to set it in the local keymap
;; We do this by advising the qutebrowser-exwm-mode function
;; (defun anthe/qutebrowser-exwm-mode-advice (orig-fun &rest args)
;;   "Advice to add local key bindings for zoom when qutebrowser-exwm-mode is enabled."
;;   (apply orig-fun args)
;;   (when qutebrowser-exwm-mode
;;     (local-set-key (kbd "C-=") 
;;                    (lambda () (interactive) (anthe/qutebrowser-send-command "zoom-in") (message "Zoom in")))
;;     (local-set-key (kbd "C-+") 
;;                    (lambda () (interactive) (anthe/qutebrowser-send-command "zoom-in") (message "Zoom in")))
;;     (local-set-key (kbd "C--") 
;;                    (lambda () (interactive) (anthe/qutebrowser-send-command "zoom-out") (message "Zoom out")))))

;; (advice-add 'qutebrowser-exwm-mode :after-while #'anthe/qutebrowser-exwm-mode-advice)

;; (defun qutebrowser-commandline-send (commands &optional start)
;;   "Send COMMANDS to Qutebrowser via commandline."
;;   (let ((running (qutebrowser-is-running-p)))
;;     (if (or start running)
;;         (progn
;;           (unless running
;;             (message "Starting new Qutebrowser instance."))
;;           (apply #'start-process "qutebrowser" nil
;;                  "/home/anthe/software/qutebrowser/.venv/bin/python3" "-m" "qutebrowser" commands))
;;       (message "Qutebrowser is not running, not going to send commands via commandline."))))

(defun anthe-switch-to-qutebrowser-buffers (&optional sources)
  (interactive)
  (let ((selected (consult--multi (or sources consult-buffer-sources)
                                  :require-match
                                  (confirm-nonexistent-file-or-buffer)
                                  :prompt "Switch to Qute: "
                                  :initial "qutebrowser^ "
                                  :history 'consult--buffer-history
                                  :sort nil)))
    ;; For non-matching candidates, fall back to buffer creation.
    (unless (plist-get (cdr selected) :match)
      (consult--buffer-action (car selected)))))

(global-qutebrowser-exwm-mode)

;; Its buffer source previews the selected window, and ESC restores the previous one
(setq qutebrowser-launcher-backend #'qutebrowser-consult-launcher)
(consult-customize qutebrowser-consult--exwm-buffer-source
                   :preview-key '(:debounce 0.3 any)
                   :state #'anthe/qutebrowser--exwm-buffer-state)

(defun anthe/qutebrowser--exwm-buffer-state ()
  "Preview qutebrowser windows, then give back the ones taken from other monitors.
Previewing a window shown on another workspace moves it here, and EXWM
shows another buffer there.  Once it is no longer previewed or chosen,
it is put back in its window."
  (let ((state (consult--buffer-state))
        (others (cl-loop for window in (window-list-1 nil 'nomini 'visible)
                         unless (eq (window-frame window) (selected-frame))
                         collect (cons window (window-buffer window)))))
    (lambda (action cand)
      (let ((buffer (qutebrowser--candidate-buffer cand)))
        (funcall state action buffer)
        (when (memq action '(preview return))
          (pcase-dolist (`(,window . ,original) others)
            (when (and (window-live-p window)
                       (buffer-live-p original)
                       (not (eq original buffer))
                       (not (eq (window-buffer window) original))
                       (not (get-buffer-window original 'visible)))
              (set-window-buffer window original))))))))
;; The command source asks qutebrowser for its commands, which fails while it is not running
(consult-customize qutebrowser-consult--command-source
                   :enabled #'qutebrowser-rpc-connected-p)
(global-qutebrowser-doom-modeline-mode)
(qutebrowser-theme-export-mode)

;; (map! :leader
;;       (:prefix ("k q" . "qutebrowser")
;;        :desc "Qutebrowser launcher" "l" #'qutebrowser-launcher
;;        :desc "Qutebrowser switch (tabs and bookmarks)" "s" #'anthe-switch-to-qutebrowser-buffers))

;; The launcher also lists open windows, bookmarks and history
(map! :leader
      :desc "Browser" "j" #'qutebrowser-launcher
      :desc "Browser in new window" "J" #'qutebrowser-launcher-window)

(defun anthe/qutebrowser-insert ()
  "Enter insert mode in both Evil and qutebrowser."
  (interactive)
  (exwm-evil-insert)
  (exwm-evil-send-key 1 ?i))

(defun anthe/qutebrowser-normal ()
  "Leave insert mode in both Evil and qutebrowser."
  (interactive)
  (exwm-evil-normal-state)
  (exwm-evil-send-key 1 'escape))

(defun anthe/qutebrowser--command-line (text)
  "Open the qutebrowser command line with TEXT, and send it the typed keys."
  (exwm-evil-insert)
  (qutebrowser-send-commands (concat ":cmd-set-text -s " text)))

(defun anthe/qutebrowser-command ()
  "Open the qutebrowser command line."
  (interactive)
  (exwm-evil-insert)
  (qutebrowser-send-commands ":cmd-set-text :"))

(defun anthe/qutebrowser-search ()
  "Search the page from the qutebrowser command line."
  (interactive)
  (exwm-evil-insert)
  (qutebrowser-send-commands ":cmd-set-text /"))

(defun anthe/qutebrowser-open ()
  "Prompt for a URL to open in the qutebrowser command line."
  (interactive)
  (anthe/qutebrowser--command-line ":open"))

(defun anthe/qutebrowser-open-tab ()
  "Prompt for a URL to open in a new tab in the qutebrowser command line."
  (interactive)
  (anthe/qutebrowser--command-line ":open -t"))

(defun anthe/qutebrowser--bindings (prefix)
  "Return the qutebrowser normal mode bindings starting with PREFIX.
They are read from the running qutebrowser, as (KEYS . COMMAND) pairs."
  (let ((code (format "chr(10).join(str(k) + chr(9) + c for k, c in __import__('qutebrowser.config.config', fromlist=['config']).key_instance.get_bindings_for('normal').items() if str(k).startswith(%S))"
                      prefix)))
    (mapcar (lambda (line) (let ((fields (split-string line "\t")))
                             (cons (car fields) (cadr fields))))
            (split-string (qutebrowser-rpc-request :eval (list :code code)) "\n" t))))

(defun anthe/qutebrowser--show-key-hints (keys candidates)
  "Show CANDIDATES, the bindings starting with KEYS, below the windows.
Like qutebrowser's key hints, the typed KEYS are dimmed."
  (let ((buffer (get-buffer-create " *qutebrowser keys*"))
        (width (apply #'max (mapcar (lambda (b) (length (car b))) candidates))))
    (with-current-buffer buffer
      (setq-local truncate-lines t
                  mode-line-format nil
                  cursor-type nil)
      (erase-buffer)
      (dolist (binding candidates)
        (insert (propertize keys 'face 'shadow)
                (propertize (string-pad (substring (car binding) (length keys))
                                        (+ 3 (- width (length keys))))
                            'face 'font-lock-keyword-face)
                (cdr binding) "\n"))
      (delete-char -1)
      (goto-char (point-min)))
    (display-buffer buffer '(display-buffer-in-side-window
                             (side . bottom)
                             (window-height . fit-window-to-buffer)))))

(defun anthe/qutebrowser-key-chain ()
  "Read a qutebrowser key chain starting with the pressed key, and run it.
This is for qutebrowser's own bindings like \"gi\" or \",d\", which
Emacs would otherwise read in Evil normal state. ESC or C-g aborts."
  (interactive)
  (let* ((keys (string last-command-event))
         (bindings (anthe/qutebrowser--bindings keys))
         (candidates bindings))
    (unwind-protect
        (while (and keys candidates (not (assoc keys bindings)))
          (anthe/qutebrowser--show-key-hints keys candidates)
          (let ((key (read-event (format "%s-" keys))))
            (setq keys (and (characterp key) (not (memq key '(?\e ?\C-g)))
                            (concat keys (string key)))
                  candidates (seq-filter (lambda (b) (string-prefix-p (or keys "") (car b)))
                                         candidates))))
      (when-let* ((window (get-buffer-window " *qutebrowser keys*")))
        (delete-window window))
      (message nil))
    (cond ((null keys))
          ((assoc keys bindings)
           (qutebrowser-send-commands (concat ":fake-key -g " keys)))
          (t (message "No qutebrowser binding for %s" keys)))))

(defconst anthe/qutebrowser--typing-modes
  '("KeyMode.insert" "KeyMode.passthrough" "KeyMode.command" "KeyMode.hint"
    "KeyMode.caret" "KeyMode.set_mark" "KeyMode.jump_mark" "KeyMode.prompt"
    "KeyMode.yesno")
  "Qutebrowser modes that read typed keys, so Evil must let them through.")

(defun anthe/qutebrowser--entered-typing-mode (info)
  "Send the keys to qutebrowser while it reads typed keys.
INFO is the plist of the `entered-mode' signal."
  (when-let* (((member (plist-get info :mode) anthe/qutebrowser--typing-modes))
              (buffer (exwm--id->buffer (plist-get info :x11-win-id))))
    (with-current-buffer buffer
      (exwm-evil-insert))))

(defun anthe/qutebrowser--left-typing-mode (info)
  "Return to Evil normal state when qutebrowser stops reading typed keys.
INFO is the plist of the `left-mode' signal."
  (when-let* (((member (plist-get info :left-mode) anthe/qutebrowser--typing-modes))
              (buffer (exwm--id->buffer (plist-get info :x11-win-id))))
    (with-current-buffer buffer
      (exwm-evil-normal-state))))

(add-hook 'qutebrowser-on-entered-mode-functions #'anthe/qutebrowser--entered-typing-mode)
(add-hook 'qutebrowser-on-left-mode-functions #'anthe/qutebrowser--left-typing-mode)

(defun anthe/qutebrowser--sibling (step)
  "Return the qutebrowser buffer STEP windows away from the current one.
Windows are in opening order, as tabs would be. Buffers shown in another
window are skipped, as EXWM can show an X window in only one place."
  (let* ((buffers (seq-filter (lambda (b) (or (eq b (current-buffer))
                                              (not (get-buffer-window b 'visible))))
                              (qutebrowser-exwm-buffer-list)))
         (buffers (sort buffers :key (lambda (b) (buffer-local-value 'exwm--id b))))
         (index (seq-position buffers (current-buffer))))
    (when (and index (cdr buffers))
      (nth (mod (+ index step) (length buffers)) buffers))))

(defun anthe/qutebrowser-next-window ()
  "Show the next qutebrowser window, like the next tab."
  (interactive)
  (when-let* ((buffer (anthe/qutebrowser--sibling 1)))
    (switch-to-buffer buffer)))

(defun anthe/qutebrowser-previous-window ()
  "Show the previous qutebrowser window, like the previous tab."
  (interactive)
  (when-let* ((buffer (anthe/qutebrowser--sibling -1)))
    (switch-to-buffer buffer)))

;; The commands are sent directly, not through the qutebrowser-cmd-* functions: those are only
;; made once the RPC lists the commands, which can fail when connecting, and the keys then give
;; "Wrong type argument: commandp"
;; :localleader would also apply to the keys after it, so it needs its own form
(map! :map qutebrowser-exwm-mode-map
      :localleader "z" (cmd! (qutebrowser-send-commands ":zoom-in")))

(map! :map qutebrowser-exwm-mode-map
      ;; exwm-evil sends C-+, C-- and C-= here, which qutebrowser does not bind
      :n "+" (cmd! (qutebrowser-send-commands ":zoom-in"))
      :n "-" (cmd! (qutebrowser-send-commands ":zoom-out"))
      :n "=" (cmd! (qutebrowser-send-commands ":zoom"))
      :n "r" (cmd! (qutebrowser-send-commands ":reload"))
      :n "f" (cmd! (qutebrowser-send-commands ":hint"))
      :n "H" (cmd! (qutebrowser-send-commands ":back"))
      :n "L" (cmd! (qutebrowser-send-commands ":forward"))
      :n ":" #'anthe/qutebrowser-command
      :n "/" #'anthe/qutebrowser-search
      :n "n" (cmd! (qutebrowser-send-commands ":search-next"))
      :n "N" (cmd! (qutebrowser-send-commands ":search-prev"))
      ;; Scroll the page, not the Emacs buffer as in `anthe-evil'
      :n "C-d" (cmd! (qutebrowser-send-commands ":scroll-page 0 0.5"))
      :n "C-u" (cmd! (qutebrowser-send-commands ":scroll-page 0 -0.5"))
      :n "C-f" (cmd! (qutebrowser-send-commands ":scroll-page 0 1"))
      :n "C-b" (cmd! (qutebrowser-send-commands ":scroll-page 0 -1"))
      :n "," #'anthe/qutebrowser-key-chain
      ;; Tabs are EXWM windows here, see `qutebrowser-exwm-buffer-list'
      :n "J" #'anthe/qutebrowser-next-window
      :n "K" #'anthe/qutebrowser-previous-window
      ;; Text selected with the mouse
      :n "Y" (cmd! (qutebrowser-send-commands ":yank selection"))
      :n "o" #'anthe/qutebrowser-open
      :n "O" #'anthe/qutebrowser-open-tab
      :n "i" #'anthe/qutebrowser-insert
      :i "<escape>" #'anthe/qutebrowser-normal)

;; Qutebrowser's own bindings starting with these keys, like gi, ;y or pp
(dolist (key '("g" ";" "y" "p" "P" "w" "x" "t" "s" "S" "[" "]" "{" "}"
               "a" "c" "m" "M" "b" "B" "u" "U" "v" "V" "R" "." "?"))
  (evil-define-key* 'normal qutebrowser-exwm-mode-map (kbd key) #'anthe/qutebrowser-key-chain))

(custom-set-faces!
  '(vertico-group-title :foreground "#51afef")
  '(completions-annotations :foreground "#d2a6ff" :slant italic)
  )

(provide 'anthe-qutebrowser)
;;; anthe-qutebrowser.el ends here
