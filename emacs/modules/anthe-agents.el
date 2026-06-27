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

(add-to-list 'load-path "~/.config/emacs/.local/elpa/agent-shell-20260604.855")
(add-to-list 'load-path "~/.config/emacs/.local/elpa/acp-20260527.2132/")
(add-to-list 'load-path "~/.config/emacs/.local/elpa/shell-maker-20260601.1034/")

(use-package agent-shell
  :config
  ;; Evil state-specific RET behavior: insert mode = newline, normal mode = send
  (evil-define-key 'insert agent-shell-mode-map (kbd "RET") #'newline)
  (evil-define-key 'normal agent-shell-mode-map (kbd "RET") #'comint-send-input)

  ;; Configure *agent-shell-diff* buffers to start in Emacs state
  (add-hook 'diff-mode-hook
	    (lambda ()
	      (when (string-match-p "\\*agent-shell-diff\\*" (buffer-name))
		(evil-emacs-state)))))

;; ;; With string
(setq agent-shell-mistral-authentication
      (agent-shell-mistral-make-authentication :api-key (getenv "MISTRAL_VIBE_API_KEY")))

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

(require 'gptel)

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
       :desc "Eval region in gptel (gptel-send)" "s" #'gptel-send))

(provide 'anthe-agents)
;;; anthe-agents.el ends here
