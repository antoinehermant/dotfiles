;;; anthe-gptel.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Maintainer: anthe <anthe@inspiron>
;; Created: February 15, 2026
;; Modified: February 15, 2026
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/anthe/anthe-gptel
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(use-package! gptel)

(require 'json)

(defvar my-api-keys nil
  "A list to store API keys.")

;; reads my API keys from a JSON file (private) and store then in a list.
(defun load-api-keys (file)
  (interactive)
  (let ((json-data (with-temp-buffer
                     (insert-file-contents file)
                     (goto-char (point-min))
                     (json-read))))
    (setq my-api-keys json-data)))
(load-api-keys "~/.secrets/.my_apis.json")

(add-to-list 'load-path "~/.config/emacs/.local/straight/repos/gptel/")
(require 'gptel)

(setq gptel-default-mode 'org-mode)

(gptel-make-openai "TogetherAI"
   :host "api.together.xyz"
   :key (alist-get 'TOGETHER_AI_API_KEY my-api-keys)
   :stream t
   :models '(
        mistralai/Mistral-7B-Instruct-v0.3
        mistralai/Mistral-7B-v0.1
        mistralai/Mixtral-8x7B-v0.1
        mistralai/Mixtral-8x7B-Instruct-v0.1
        mistralai/Mixtral-8x22B-Instruct-v0.1
        mistralai/Mistral-Small-24B-Instruct-2501
        togethercomputer/m2-bert-80M-32k-retrieval))

(gptel-make-openai "Codestral"
 :host "codestral.mistral.ai"
 :endpoint "/v1/chat/completions"
 :key (alist-get 'CODESTRAL_API_KEY my-api-keys)
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
 :key (alist-get 'MISTRAL_API_KEY my-api-keys)
 :stream t
 :models '(
           mistral-large-latest
           mistral-small
           )))

(map! :leader
      (:prefix ("k g" . "gptel")
      :desc "gptel mode" " m" #'gptel-mode
      :desc "Open gptel" "o" #'gptel
      :desc "Eval region in gptel (gptel-send)" "s" #'gptel-send)

(provide 'anthe-gptel)
;;; anthe-gptel.el ends here
