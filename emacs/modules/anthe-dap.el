;;; anthe-dap.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Maintainer: anthe <anthe@inspiron>
;; Created: February 15, 2026
;; Modified: February 15, 2026
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/anthe/anthe-dap
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:


(require 'dape)

(defun dape-cwd-file ()
  (or (buffer-file-name) default-directory))

(defun dape-file-name ()
  (let ((file-path (buffer-file-name)))
    (if file-path
        (file-name-nondirectory file-path)
      (message "No file is associated with the current buffer"))))

(defun dape-cwd ()
  (let ((file-path (or (buffer-file-name) default-directory)))
    (if (file-directory-p file-path)
        file-path
      (file-name-directory file-path))))

(add-to-list 'dape-configs
             `(debugpy
               modes (python-mode jinja2-mode)
               command "python"
               command-args ["-m" "debugpy.adapter" "--host" "0.0.0.0" "--port" :autoport]
               port :autoport
               :type "python"
               :request "launch"
               :args ["--app" "src" "run" "--no-debugger" "--no-reload"]
               :console "integratedTerminal"
               :showReturnValue t
               :justMyCode nil
               :jinja t
               :cwd (lambda () (dape-cwd))
               :program (lambda () (dape-file-name))))

;; (use-package dap-mode
;;   :commands dap-mode)

;; (use-package dap-python
;;   :commands dap-python-debug-buffer)
;; (use-package elpy
;;   :ensure t
;;   :init
;;   (elpy-enable))

;; (use-package dap-python
;;      :ensure t
;;      :config
;;      (dap-python-setup))
;; (use-package ein
;;   :ensure t
;;   :config
;;   (require 'ein)
;;   ;; Automatically start Jupyter server when opening a notebook
;;   (add-hook 'ein:notebook-mode-hook 'ein:notebook-start-server)
;;   ;; Optional: Split window when opening notebooks
;;   (setq ein:notebook-split-window t)
;;   ;; Set the default kernel to use
;;   (setq ein:jupyter-kernel "python3" ;; Change this to "myenv" if needed
;;         ein:jupyter-python-path "/storage/workspaces/climate_charibdis/climate_ism/Software/miniconda/envs/charibdis/bin/jupyter")) ;; Adjust the path accordingly
;; Enable tree-sitter for Python
;; (use-package treesit
;;   :config
;;   (add-to-list 'treesit-language-source-alist '(python "https://github.com/tree-sitter/tree-sitter-python"))
;;   (add-to-list 'major-mode-remap-alist '(python-mode . python-ts-mode)))
;; (use-package treesit
;;   :config
;;   (add-to-list 'treesit-language-source-alist '(python "https://github.com/tree-sitter/tree-sitter-python"))
;;   (add-to-list 'major-mode-remap-alist '(python-mode . python-ts-mode)))
;; (tree-sitter-hl-add-patterns 'python
;;   [((import_statement
;;      name: (dotted_name (identifier) @module))
;;     (import_from_statement
;;      module_name: (dotted_name (identifier) @module)))

;;    ((call
;;      function: (attribute
;;                 object: (identifier) @module
;;                 attribute: (identifier) @function))
;;     (.match? @module "^xr$"))])

;; (dap-python-executable "python3")
;; (dap-python-debugger 'debugpy))
;; :config
;; (require 'dap-python)
;;
(provide 'anthe-dap)
;;; anthe-dap.el ends here
