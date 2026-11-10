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
shows another buffer there.  It is put back in its window once another
qutebrowser window is previewed, or when the launcher ends with
something else chosen, or nothing."
  (let ((state (consult--buffer-state))
        (others (cl-loop for window in (window-list-1 nil 'nomini 'visible)
                         unless (eq (window-frame window) (selected-frame))
                         collect (cons window (window-buffer window)))))
    (lambda (action cand)
      (let ((buffer (qutebrowser--candidate-buffer cand)))
        (funcall state action buffer)
        ;; Not on a preview of nothing: consult resets the preview so before
        ;; RET, and the chosen window would go back before being switched to
        (when (or (eq action 'return) (and (eq action 'preview) buffer))
          (pcase-dolist (`(,window . ,original) others)
            (when (and (window-live-p window)
                       (buffer-live-p original)
                       (not (eq original buffer))
                       (not (eq (window-buffer window) original))
                       (not (get-buffer-window original 'visible)))
              (set-window-buffer window original))))))))
;; A new connection is only made when not connected: close those left over,
;; as when a connection failed halfway after qutebrowser restarted.  The
;; RPC server answers one connection at a time, so the requests on the new
;; one would wait behind the old one, and time out
(define-advice qutebrowser-rpc--make-network-process (:before () anthe-close-stale)
  "Close the RPC connections left over."
  (dolist (process (process-list))
    (when (string-match-p "\\`qutebrowser-rpc\\(<[0-9]+>\\)?\\'" (process-name process))
      (delete-process process))))

;; The command source asks qutebrowser for its commands, which fails while it is not running
(consult-customize qutebrowser-consult--command-source
                   :enabled #'qutebrowser-rpc-connected-p)

;;;; Quickmarks and bookmarks
;; Quickmarks are the named places visited often, named by a prefix like
;; "gh pism" or "mail unibe": typing "gh" lists the GitHub ones. Bookmarks
;; (M in qutebrowser) are pages kept to read later, under their title.
;; Both stay in qutebrowser's files, where its own :open completion finds them.

(defun anthe/qutebrowser--marks-file (name)
  "Return the path of qutebrowser's marks file NAME."
  (expand-file-name name "~/.config/qutebrowser/"))

(defun anthe/qutebrowser--read-marks (name url-last)
  "Return the marks of qutebrowser's file NAME, as (LABEL . URL) pairs.
Quickmarks lines are \"name url\" (URL-LAST), bookmarks lines \"url title\"."
  (let ((file (anthe/qutebrowser--marks-file name)))
    (when (file-exists-p file)
      (with-temp-buffer
        (insert-file-contents file)
        (cl-loop for line in (split-string (buffer-string) "\n" t)
                 unless (string-prefix-p "#" line)
                 collect (if url-last
                             (let ((space (string-match " [^ ]+\\'" line)))
                               (cons (substring line 0 space) (substring line (1+ space))))
                           (let ((space (string-search " " line)))
                             (cons (if space (substring line (1+ space)) line)
                                   (substring line 0 space)))))))))

(defun anthe/qutebrowser--mark-candidates (marks)
  "Return the completion candidates for MARKS, (LABEL . URL) pairs.
The URL is matched too, but shown as the annotation."
  (mapcar (pcase-lambda (`(,label . ,url))
            (propertize (concat label (propertize (concat " " url) 'invisible t))
                        :qutebrowser-url url))
          marks))

(defun anthe/qutebrowser--mark-annotate (cand)
  "Annotate CAND with its URL."
  (concat (propertize " " 'display '(space :align-to 40))
          (propertize (get-text-property 0 :qutebrowser-url cand)
                      'face 'completions-annotations)))

(defun anthe/qutebrowser--mark-open (cand)
  "Open the URL of the mark CAND."
  (qutebrowser-open-url (get-text-property 0 :qutebrowser-url cand)))

(defvar anthe/qutebrowser--quickmark-source
  (list :name "Quickmarks"
        :narrow ?m
        :category 'url
        :history nil
        :action #'anthe/qutebrowser--mark-open
        :annotate #'anthe/qutebrowser--mark-annotate
        :items (lambda () (anthe/qutebrowser--mark-candidates
                           (anthe/qutebrowser--read-marks "quickmarks" t))))
  "Launcher source for qutebrowser quickmarks.")

(defvar anthe/qutebrowser--bookmark-source
  (list :name "Bookmarks (read later)"
        :narrow ?b
        :category 'url
        :history nil
        :action #'anthe/qutebrowser--mark-open
        :annotate #'anthe/qutebrowser--mark-annotate
        :items (lambda () (anthe/qutebrowser--mark-candidates
                           (anthe/qutebrowser--read-marks "bookmarks/urls" nil))))
  "Launcher source for qutebrowser bookmarks.")

(setq qutebrowser-consult-launcher-sources
      '(qutebrowser-consult--exwm-buffer-source
        anthe/qutebrowser--quickmark-source
        anthe/qutebrowser--bookmark-source
        qutebrowser-consult--history-source
        qutebrowser-consult--command-source))

;; TAB completes the input with the selected candidate, for RET to open it.
;; Consult makes TAB go to the next group, as the history is searched anew
;; for each input: a minor mode map comes before its remap
(defun anthe/qutebrowser--visible-text (string)
  "Return STRING without its invisible parts, such as the URL of a mark."
  (let ((pos 0) parts)
    (while (< pos (length string))
      (let ((next (next-single-property-change pos 'invisible string (length string))))
        (unless (get-text-property pos 'invisible string)
          (push (substring-no-properties string pos next) parts))
        (setq pos next)))
    (consult--tofu-strip (apply #'concat (nreverse parts)))))

(defun anthe/qutebrowser-launcher-complete ()
  "Put the selected candidate in the input, and keep it selected."
  (interactive)
  (when-let* ((cand (and (>= vertico--index 0) (nth vertico--index vertico--candidates))))
    (delete-minibuffer-contents)
    (insert (anthe/qutebrowser--visible-text cand))
    (vertico--exhibit)
    ;; Other candidates may match the input too, and come first
    (when-let* ((index (seq-position vertico--candidates cand)))
      (vertico--goto index)
      (vertico--exhibit))))

(define-minor-mode anthe/qutebrowser-launcher-mode
  "Keys of the qutebrowser launcher, in its minibuffer."
  :keymap (define-keymap "TAB" #'anthe/qutebrowser-launcher-complete
                         "<tab>" #'anthe/qutebrowser-launcher-complete))

(define-advice qutebrowser-consult-launcher (:around (fn &rest args) anthe-complete)
  "Complete with TAB in the launcher."
  (minibuffer-with-setup-hook (lambda () (anthe/qutebrowser-launcher-mode))
    (apply fn args)))

(defun anthe/qutebrowser--marks-eval (code)
  "Run CODE on qutebrowser's quickmark and bookmark managers, bound to `q' and `b'."
  (qutebrowser-rpc-request
   :eval (list :code (format "(lambda o: (lambda q, b: %s)(o.get('quickmark-manager'), o.get('bookmark-manager')))(__import__('qutebrowser.utils.objreg', fromlist=['objreg']))"
                             code))))

(defun anthe/qutebrowser--window-url ()
  "Return the URL of this qutebrowser window, asked from qutebrowser.
`qutebrowser-exwm-buffer-url' is only set once the page reports a change,
so it is nil for windows opened before qutebrowser restarted."
  (unless (qutebrowser-exwm-p)
    (user-error "Not a qutebrowser window"))
  (let ((url (qutebrowser-rpc-request
              :eval (list :code (format "find_window(%d).tabbed_browser.current_url().toString()"
                                        exwm--id)))))
    (if (string-empty-p url) (user-error "This window has no URL") url)))

(defun anthe/qutebrowser-quickmark-save (name)
  "Save the page of this qutebrowser window as the quickmark NAME.
The existing names are offered, to reuse their prefix."
  (interactive
   (list (completing-read "Quickmark name: "
                          (mapcar #'car (anthe/qutebrowser--read-marks "quickmarks" t)))))
  (let ((url (anthe/qutebrowser--window-url)))
    (when (string-empty-p (string-trim name))
      (user-error "Empty quickmark name"))
    ;; qutebrowser keeps the marks in memory and writes the file itself, so it adds the mark
    (anthe/qutebrowser--marks-eval
     (format "q.quickmark_add(%S, %S)" url (string-trim name)))
    (message "Quickmark %s: %s" (string-trim name) url)))

(defun anthe/qutebrowser--marks-reload ()
  "Make qutebrowser read the marks files again, after editing them."
  (when (qutebrowser-rpc-connected-p)
    (anthe/qutebrowser--marks-eval "(q.reload(), b.reload())")
    (message "qutebrowser reloaded its quickmarks and bookmarks")))

(defun anthe/qutebrowser-marks-edit (&optional bookmarks)
  "Edit the qutebrowser quickmarks, or the BOOKMARKS with a prefix argument.
qutebrowser first writes the marks it has in memory, then reads the file
again on each save. Sort, rename and delete there."
  (interactive "P")
  (when (qutebrowser-rpc-connected-p)
    (anthe/qutebrowser--marks-eval "(q.save(), b.save())"))
  (find-file (anthe/qutebrowser--marks-file (if bookmarks "bookmarks/urls" "quickmarks")))
  (add-hook 'after-save-hook #'anthe/qutebrowser--marks-reload nil t))

(map! :leader :desc "Browser marks (C-u: bookmarks)" "k b" #'anthe/qutebrowser-marks-edit)
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
      ;; Prompts in Emacs, offering the existing names for their prefix
      :n "m" #'anthe/qutebrowser-quickmark-save
      :n "o" #'anthe/qutebrowser-open
      :n "O" #'anthe/qutebrowser-open-tab
      :n "i" #'anthe/qutebrowser-insert
      :i "<escape>" #'anthe/qutebrowser-normal)

;; Qutebrowser's own bindings starting with these keys, like gi, ;y or pp
(dolist (key '("g" ";" "y" "p" "P" "w" "x" "t" "s" "S" "[" "]" "{" "}"
               "a" "c" "M" "b" "B" "u" "U" "v" "V" "R" "." "?"))
  (evil-define-key* 'normal qutebrowser-exwm-mode-map (kbd key) #'anthe/qutebrowser-key-chain))

(custom-set-faces!
  '(vertico-group-title :foreground "#51afef")
  '(completions-annotations :foreground "#d2a6ff" :slant italic)
  )

(provide 'anthe-qutebrowser)
;;; anthe-qutebrowser.el ends here
