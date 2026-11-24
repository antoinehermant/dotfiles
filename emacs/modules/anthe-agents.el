;;; anthe-agents.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Maintainer: anthe <anthe@inspiron>
;; Created: June 04, 2026
;; Modified: June 04, 2026
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/anthe/anthe-agents
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:


(require 'json)

;; (add-to-list 'load-path "~/.config/emacs/.local/elpa/agent-shell-20260604.855")
;; (add-to-list 'load-path "~/.config/emacs/.local/elpa/acp-20260527.2132/")
;; (add-to-list 'load-path "~/.config/emacs/.local/elpa/shell-maker-20260601.1034/")

;; agent-shell loads with its first shell (a third of a second at startup)
(use-package agent-shell
  :defer t
  :config
  ;; Only C-c C-c sends a prompt, in the shell and in the compose buffer: RET is a newline
  ;; (insert state) or moves (normal state). C-c C-k interrupts the agent instead of C-c C-c.
  ;; A permission prompt keeps its own C-c C-c (reject), on the prompt's text.
  (keymap-set agent-shell-mode-map "RET" #'newline)
  (keymap-set agent-shell-mode-map "C-c C-c" #'shell-maker-submit)
  (keymap-set agent-shell-mode-map "C-c C-k" #'agent-shell-interrupt)
  (evil-define-key 'insert agent-shell-mode-map (kbd "RET") #'newline)
  (evil-define-key 'normal agent-shell-mode-map (kbd "RET") #'evil-ret)
  (with-eval-after-load 'agent-shell-viewport
    ;; evil-collection sends the compose buffer on RET in normal state
    (evil-define-key 'normal agent-shell-viewport-edit-mode-map [remap evil-ret] nil))

  ;; Configure *agent-shell-diff* buffers to start in Emacs state
  (add-hook 'diff-mode-hook
	    (lambda ()
	      (when (string-match-p "\\*agent-shell-diff\\*" (buffer-name))
		(evil-emacs-state))))

  (evil-define-key 'normal agent-shell-mode-map (kbd "gC") #'anthe/agent-shell-compose-beside))

(defvar-local anthe/agent-shell--compose-window nil
  "The window `anthe/agent-shell-compose-beside' opened for this buffer.")

(defun anthe/agent-shell-compose-beside ()
  "Like `agent-shell-prompt-compose', but beside the shell to keep it in view.
Sending or cancelling closes the compose window again."
  (interactive)
  (let ((agent-shell-display-action
         '((display-buffer-reuse-window display-buffer-in-direction)
           (direction . right)
           (window-width . 0.4))))
    (agent-shell-prompt-compose))
  (when (derived-mode-p 'agent-shell-viewport-edit-mode)
    (setq-local anthe/agent-shell--compose-window (selected-window))))

(defun anthe/agent-shell--close-compose-window (fn &rest args)
  "Call FN with ARGS, then close the window of the compose buffer beside the shell.
Sending kills the compose buffer, but its window would show the shell."
  (let ((window anthe/agent-shell--compose-window)
        (shell-buffer (ignore-errors (agent-shell-viewport--shell-buffer))))
    (apply fn args)
    ;; Unless the compose goes on (a discard not confirmed)
    (when (and (window-live-p window)
               (not (one-window-p))
               (not (with-current-buffer (window-buffer window)
                      (derived-mode-p 'agent-shell-viewport-edit-mode))))
      (delete-window window)
      (when-let* ((shell-window (and (buffer-live-p shell-buffer)
                                     (get-buffer-window shell-buffer))))
        (select-window shell-window)))))

(dolist (command '(agent-shell-viewport-compose-send agent-shell-viewport-compose-cancel))
  (advice-add command :around #'anthe/agent-shell--close-compose-window))

;; Mistral, where its key is (not on the HPC)
(with-eval-after-load 'agent-shell
  (when-let* ((key (getenv "MISTRAL_VIBE_API_KEY_STUDENT")))
    (setq agent-shell-mistral-authentication
          (agent-shell-mistral-make-authentication :api-key key)))

  (setopt agent-shell-persistent-prompt-enabled t))
(setq agent-shell-session-restore-verbosity 'last)

;; Killing a shell with a session asks first, not to lose it by accident.
;; Not when agent-shell kills one itself: a shell still starting, or one
;; restarted or closed with its viewport, which ask already.
(defvar anthe/agent-shell--killing nil
  "Non-nil while agent-shell kills a shell after asking itself.")

(defun anthe/agent-shell--confirm-kill ()
  "Ask before killing a shell with a session."
  (or anthe/agent-shell--killing
      (not (derived-mode-p 'agent-shell-mode))
      (not (map-nested-elt agent-shell--state '(:session :id)))
      (y-or-n-p (format "Kill the shell %s? " (buffer-name)))))

(defun anthe/agent-shell--killing-asked (fn &rest args)
  (let ((anthe/agent-shell--killing t))
    (apply fn args)))

(add-hook 'kill-buffer-query-functions #'anthe/agent-shell--confirm-kill)
(with-eval-after-load 'agent-shell
  (advice-add 'agent-shell-restart :around #'anthe/agent-shell--killing-asked))
(with-eval-after-load 'agent-shell-viewport
  (advice-add 'agent-shell-viewport--clean-up :around #'anthe/agent-shell--killing-asked))

;;; A project's agent, in one step
;; `SPC o c': choose a project, the ones with a shell first; its shell shows
;; in the project's workspace, made if missing. With no shell yet, Claude
;; starts there and resumes the project's last session. `C-u': in the
;; current workspace.

(defun anthe/agent-shell--project-shell (root)
  "The most recent agent shell working in ROOT, or nil."
  (require 'agent-shell)
  (seq-find (lambda (buffer)
              (equal (file-name-as-directory (expand-file-name root))
                     (file-name-as-directory
                      (expand-file-name (buffer-local-value 'default-directory buffer)))))
            (agent-shell-buffers)))

(defun anthe/agent-shell-project (root &optional here)
  "Show the agent of the project ROOT in its workspace, HERE in the current one.
An existing shell of the project, or Claude resuming the last session."
  (interactive
   (let* ((projects (projectile-relevant-known-projects))
          (running (seq-filter #'anthe/agent-shell--project-shell projects))
          (completion-extra-properties
           `(:annotation-function
             ,(lambda (root)
                (when (member root running)
                  (propertize "  ● agent" 'face 'success))))))
     (list (completing-read "Agent of project: "
                            (lambda (string predicate action)
                              (if (eq action 'metadata)
                                  '(metadata (display-sort-function . identity))
                                (complete-with-action
                                 action (append running (seq-difference projects running))
                                 string predicate)))
                            nil t)
           current-prefix-arg)))
  (let ((root (file-name-as-directory (expand-file-name root))))
    ;; As `projectile-switch-project' does, without asking for a file
    (unless here
      (let ((+workspaces-switch-project-function #'ignore)
            (current-prefix-arg nil))
        (+workspaces-switch-to-project-h root)))
    (if-let* ((shell (anthe/agent-shell--project-shell root)))
        (switch-to-buffer shell)
      (let ((default-directory root))
        (agent-shell--start :config (agent-shell-anthropic-make-claude-code-config)
                            :session-strategy 'latest
                            :new-session t)))
    ;; Doom's workspaces keep their own buffers: the agent's, not the
    ;; dashboard the agent was started from while it starts
    (when (and (bound-and-true-p persp-mode) (derived-mode-p 'agent-shell-mode))
      (persp-add-buffer (current-buffer)))))

(map! :leader :desc "Agent of a project" "o c" #'anthe/agent-shell-project)

;;; Claude's plan limits: the 5-hour session and the week, as /usage
;; Each reply brings them: in agent-shell, with the usage the ACP adapter
;; sends (its `_claude/rateLimit'); in a terminal, to the status line
;; (bin/claude-statusline), which keeps them in a file. They show in Claude
;; shells' header, after the context, and in the top bar (anthe-bar.el).

(defvar anthe/claude-limits nil
  "Claude's plan limits at the last reply: a plist of :time, when they came,
and :five-hour and :seven-day, each (PERCENT . RESETS-AT), in seconds.")

(defvar anthe/claude-limits-file
  (expand-file-name "claude-limits.json" (or (getenv "XDG_STATE_HOME") "~/.local/state"))
  "Where bin/claude-statusline keeps the limits.")

(defun anthe/claude-limits--set (time window)
  "Keep the limits that came at TIME, WINDOW giving each (PERCENT . RESETS-AT)
from its name, `five_hour' or `seven_day', nil if it didn't come."
  (setq anthe/claude-limits
        (list :time time
              :five-hour (or (funcall window 'five_hour) (plist-get anthe/claude-limits :five-hour))
              :seven-day (or (funcall window 'seven_day) (plist-get anthe/claude-limits :seven-day)))))

(defun anthe/claude-limits ()
  "The limits known, taking the status line's if they came later."
  (when-let* ((attributes (file-attributes anthe/claude-limits-file))
              (time (float-time (file-attribute-modification-time attributes)))
              ((> time (or (plist-get anthe/claude-limits :time) 0)))
              (limits (ignore-errors (json-read-file anthe/claude-limits-file))))
    (anthe/claude-limits--set
     time (lambda (name)
            (when-let* ((window (alist-get name limits))
                        (percent (alist-get 'used_percentage window)))
              (cons percent (alist-get 'resets_at window))))))
  anthe/claude-limits)

(defun anthe/claude-limits--percent (window)
  "WINDOW's percentage used, nil once it reset."
  (let ((limit (plist-get (anthe/claude-limits) window)))
    (when (and limit (> (cdr limit) (float-time)))
      (round (car limit)))))

(defun anthe/claude-limits-string ()
  "Like \"5h 49% until 12:50 · 7d 75%\", coloured as they near 100%, nil
if unknown: the session's renewal time, not the week's."
  (let ((parts (delq nil
                     (mapcar (pcase-lambda (`(,window . ,label))
                               (when-let* ((percent (anthe/claude-limits--percent window)))
                                 (concat
                                  (propertize (format "%s %d%%" label percent)
                                              'face (cond ((>= percent 90) 'error)
                                                          ((>= percent 75) 'warning)))
                                  (when (eq window :five-hour)
                                    (format-time-string
                                     " until %H:%M" (cdr (plist-get anthe/claude-limits window)))))))
                             '((:five-hour . "5h") (:seven-day . "7d"))))))
    (when parts (string-join parts " · "))))

(defun anthe/claude-limits-help ()
  "The limits in words, with when they reset."
  (mapconcat (pcase-lambda (`(,window . ,label))
               (let ((limit (plist-get (anthe/claude-limits) window)))
                 (format "%s: %s" label
                         (if-let* ((percent (anthe/claude-limits--percent window)))
                             (format "%d%% used, resets %s" percent
                                     (format-time-string "%a %-d %b %H:%M" (cdr limit)))
                           "unknown"))))
             '((:five-hour . "Claude session") (:seven-day . "Claude week"))
             "\n"))

(defun anthe/claude-limits--from-agent-shell (&rest args)
  "Keep the limits a Claude shell's usage update brings, and show them in
the other Claude shells too (this one redraws its header after)."
  (when-let* ((windows (map-nested-elt (plist-get args :acp-update)
                                       '(_meta _claude/rateLimit unifiedWindows))))
    (anthe/claude-limits--set
     (float-time)
     (lambda (name)
       (when-let* ((window (alist-get name windows))
                   (utilization (alist-get 'utilization window)))
         (cons (* 100 utilization) (alist-get 'resetsAt window)))))
    (let ((current (current-buffer)))
      (dolist (buffer (buffer-list))
        (unless (eq buffer current)
          (with-current-buffer buffer
            (when (derived-mode-p 'agent-shell-mode)
              (ignore-errors (agent-shell--update-header-and-mode-line)))))))))

(defun anthe/agent-shell-with-limits (indicator)
  "The context INDICATOR, then the limits in Claude shells.  It goes through
`format-mode-line', hence the doubled %."
  (if-let* (((eq (map-nested-elt (agent-shell--state) '(:agent-config :identifier)) 'claude-code))
            (limits (anthe/claude-limits-string)))
      (let ((limits (string-replace "%" "%%" limits)))
        (if indicator (concat indicator " · " limits) limits))
    indicator))

(with-eval-after-load 'agent-shell-usage
  (advice-add 'agent-shell--update-usage-from-notification :after
              #'anthe/claude-limits--from-agent-shell)
  (advice-add 'agent-shell--context-usage-indicator :filter-return
              #'anthe/agent-shell-with-limits))
;; ;; With function (reusing the API key configured in vibe)
;; (setq agent-shell-mistral-authentication
;;       (agent-shell-mistral-make-authentication
;;        :api-key (lambda ()
;; 	          (string-trim
;; 		   (shell-command-to-string "source ~/.vibe/.env; echo $MISTRAL_VIBE_API_KEY")))))

;; (add-to-list 'load-path "~/.config/emacs/.local/elpa/gptel-20260426.2347/")
;; (require 'gptel)
;; (eval-and-compile (require 'gptel-openai-extras))
;; (eval-and-compile (require 'gptel-rewrite))

;; gptel only where Doom's llm module is (not on the HPC)
(when (require 'gptel nil t)
  (setq gptel-default-mode 'org-mode)

  (gptel-make-openai "TogetherAI"
    :host "api.together.xyz"
    :key (getenv "TOGETHER_AI_API_KEY")
    :stream t
    :models '(
              mistralai/Mistral-7B-Instruct-v0.3
              mistralai/Mistral-7B-v0.1
              mistralai/Mixtral-8x7B-v0.1
              mistralai/Mixtral-8x7B-Instruct-v0.1
              mistralai/Mixtral-8x22B-Instruct-v0.1
              mistralai/Mistral-Small-24B-Instruct-2501
              nim/nv-mistralai/mistral-nemo-12b-instruct
              togethercomputer/m2-bert-80M-32k-retrieval))

  (gptel-make-openai "Codestral"
    :host "codestral.mistral.ai"
    :endpoint "/v1/chat/completions"
    :key (getenv "CODESTRAL_API_KEY")
    :stream t
    :models '(
              codestral-latest
              ))

  (setq
   gptel-model   'mistral-large-latest
   gptel-backend
   (gptel-make-openai "Mistral"
     :host "api.mistral.ai"
     :endpoint "/v1/chat/completions"
     :key (getenv "MISTRAL_API_KEY")
     :stream t
     :models '(
               mistral-large-latest
               mistral-small
               )))


  (gptel-make-openai "Infomaniak"
    :host "api.infomaniak.com"
    :endpoint "/2/ai/108286/openai/v1/chat/completions"
    :key (getenv "INFOMANIAK_API_KEY")
    :stream t
    :models '(
              mistral3
              mistralai/Ministral-3-14B-Instruct-2512
              swiss-ai/Apertus-70B-Instruct-2509
              ))

  (map! :leader
        (:prefix ("k g" . "gptel")
         :desc "gptel mode" " m" #'gptel-mode
         :desc "Open gptel" "o" #'gptel
         :desc "gptel rewrite" "r" #'gptel-rewrite
         ;; :desc "Eval region in gptel (gptel-send)" "s" #'gptel-send)
         )))

(provide 'anthe-agents)
;;; anthe-agents.el ends here
