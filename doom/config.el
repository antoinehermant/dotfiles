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
;; (setq doom-theme 'doom-one)
;; (setq doom-theme 'doom-nord)
;; (setq doom-theme 'doom-palenight)
(setq doom-theme 'doom-outrun-electric)
;; (setq doom-theme 'doom-challenger-deep)
;; (load-theme 'night-owl)
;; (load-theme 'doom-outrun-electric)
;; (setq doom-theme 'night-owl)


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

;; (setq explicit-shell-file-name "/bin/bash")
;; (setq shell-file-name "bash")
;; (setq shell-command-switch "-ic")

;; NOTE: forgot what this does
(setq inhibit-x-resources t)
(setq-default inhibit-redisplay t)
(add-hook 'window-setup-hook
          (lambda ()
            (setq-default inhibit-redisplay nil)
            (redisplay))
          100)

(add-hook 'server-switch-hook #'raise-frame)
(add-hook 'server-switch-hook (lambda () (select-frame-set-input-focus (selected-frame))))

(set-face-attribute 'default nil :height 109)

(use-package! disable-mouse
   :config
   (global-disable-mouse-mode t))
;; more elaborate than disable-mouse, like it handles evil better
(use-package inhibit-mouse
  :config
  (inhibit-mouse-mode))

(setq dired-kill-when-opening-new-dired-buffer t)

(require 'dirvish)
(setq dirvish-preview-disabled-exts '("bin" "exe" "gpg" "elc" "eln" "xcf" "ncap2.temp" "pid*"))

(dirvish-define-preview nc (file ext)
 "Preview netcdf file info with cdo sinfon
 Require: `cdo' (executable)"
 :require ("cdo" )
 (cond ((equal ext "nc") `(shell . ("cdo" "-sinfon" ,file)))))
 (add-to-list 'dirvish-preview-dispatchers 'nc)

(display-line-numbers-mode)
(setq display-line-numbers-type 'relative)
(custom-set-faces!
  '(line-number :foreground "#ffffff")  ;; #FF9E3B
  '(line-number-current-line :weight bold :foreground "#51afef")
  '(font-lock-keyword-face :foreground "#51afef")  ;; #FF9E3B
  )

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

(setq image-use-external-converter t)
(setq image-converter 'imagemagick)


;; (setq gc-cons-threshold 100000000)
;; (setq read-process-output-max 10000000)
;; (setq bidi-inhibit-bpa t)

;; UNSET mouse drag in evil mode
(global-unset-key [drag-mouse-1]) 


(setq ibuffer-formats
        '((mark modified read-only locked " "
                (name 40 40 :left :elide)
                " "
                (size 7 -1 :right)
                " "
                (mode 12 12 :left :elide)
                " "
                (vc-status 9 :left)
                " " filename-and-process)
        (mark " "
                (name 10 -1)
                " " filename)))
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





(use-package popper
  :bind (("C-`"   . popper-toggle)
         ("M-`"   . popper-cycle)
         ("C-M-`" . popper-toggle-type)
         ("C-<down>" . 'shrink-window)
         ("C-<up>" . 'enlarge-window))
  :init
  (setq popper-reference-buffers
        '("^\\*Messages\\*"
          "^Output\\*$"
          "^\\*Async Shell Command\\*"
          "^\\*vterm"
          ;; "^\\*vterminal<\\([0-9]+\\)>\\*"  ; Match all vterminal instances
          "^*compilation"
          help-mode
          compilation-mode))   ; Add closing parenthesis here
  (popper-mode +1)
  (popper-echo-mode +1))                ; For echo area

(setq popper-window-height (floor (* (frame-height) 0.3)))

;; Define global variables to store state
(defvar vterm-popper-original-height nil
  "Stores the original height of the vterm popup window.")
(defvar vterm-popper-expanded nil
  "Boolean flag to track if the vterm popup is expanded.")
(defvar vterm-popper-original-height nil
  "Stores the original height of the vterm popup window.")
(defvar vterm-popper-expanded nil
  "Boolean flag to track if the vterm popup is expanded.")

(defun toggle-vterm-popper-size ()
  "Toggle vterm popup window size between default and 3/4 of the screen height."
  (interactive)
  (let* ((vterm-window (seq-find (lambda (window)
                                   (string-match-p "^\\*vterm" (buffer-name (window-buffer window))))
                                 (window-list)))
         (frame-height (frame-height))
         (expanded-height (floor (* frame-height 0.80))))
    (when vterm-window
      (if vterm-popper-expanded
          (progn
            (window-resize vterm-window
                           (- vterm-popper-original-height (window-height vterm-window)))
            (setq vterm-popper-expanded nil))
        (setq vterm-popper-original-height (window-height vterm-window))
        (window-resize vterm-window
                       (- expanded-height (window-height vterm-window)))
        (setq vterm-popper-expanded t)))))

;; Bind the function to a key
(global-set-key (kbd "C-c `") 'toggle-vterm-popper-size)

(defvar frame-transparency-toggle-state nil
  "State of frame transparency toggle.")

;; Defining a variable for transparency so it can depend on certain conditions such as which theme loaded or which system we are on
;; (defvar my-transparency-value 90
;;   "Defines a variable for transparency")

(defun toggle-frame-transparency ()
  "Toggle frame transparency between 100% and 95%."
  (interactive)
  (if frame-transparency-toggle-state
      (progn
        (set-frame-parameter nil 'alpha-background 100)
        (add-to-list 'default-frame-alist '(alpha-background . 100))
        (setq frame-transparency-toggle-state nil))
    (progn
      (set-frame-parameter nil 'alpha-background 85)
      (add-to-list 'default-frame-alist '(alpha-background . 85))
      (setq frame-transparency-toggle-state t)))
  (message "Frame transparency toggled to %s%%"
           (if frame-transparency-toggle-state 85 100)))


(defvar frame-transparency-toggle-state-100 nil
  "State of frame transparency toggle.")

(defun toggle-frame-transparency-100 ()
  "Toggle frame transparency between 100% and 95%."
  (interactive)
  (if frame-transparency-toggle-state-100
      (progn
        (set-frame-parameter nil 'alpha-background 100)
        (add-to-list 'default-frame-alist '(alpha-background . 100))
        (setq frame-transparency-toggle-state-100 nil))
    (progn
      (set-frame-parameter nil 'alpha-background 10)
      (add-to-list 'default-frame-alist '(alpha-background . 10))
      (setq frame-transparency-toggle-state-100 t)))
  (message "Frame transparency toggled to %s%%"
           (if frame-transparency-toggle-state-100 10 100)))
;
; (setq popper-reference-buffers
;;       (append popper-reference-buffers
;;               '("\\*eshell*\\*$" eshell-mode ;eshell as a popup
;;                 "\\*shell*\\*$"  shell-mode  ;shell as a popup
;;                 "\\*term*\\*$"   term-mode   ;term as a popup
;;                 "\\*vterm*\\*$"  vterm-mode  ;vterm as a popup
;;                 )))


;; (after! vterm
;;   (set-popup-rule! "*doom:vterm-popup:main" :size 0.3 :vslot -4 :select t :quit nil :ttl 0)
;;   (defadvice! +vterm-init-popup (&rest _)
;;     :after 'popups-init
;;     (display-buffer (vterm-get-buffer-create "*doom:vterm-popup:main*"))))


;; ------------------------- Functions ------------------------------

;; -------------------------- Keybindings ---------------------------
;; (global-set-key (kbd "KEY_SEQUENCE") 'command)
;; (global-unset-key (kbd "KEY_SEQUENCE"))
;; (add-hook 'mode-hook
;;           (lambda ()
;;             (local-set-key (kbd "KEY_SEQUENCE") 'command)))


;; (after! python
;;   (map! :leader
;;         :desc "Send line or region to Python shell" "r r" #'python-shell-send-region))

(defun python-shell-send-region-or-current-line ()
  "Send the current region or line to the Python shell and execute."
  (interactive)
  (let* ((region-active (region-active-p))
         (start (if (region-active-p)
                   (region-beginning)
                 (line-beginning-position)))
        (end (if (region-active-p)
                 (region-end)
               (line-end-position))))
    (python-shell-send-region start end)
    ;; (deactivate-mark)  ; Quit visual mode
    (unless region-active
      (forward-line 1))
    (back-to-indentation)))

;; Define python keybindings. NOTE: I moved them to global map so they are always active. (they were always active anyways after first python hook call)
(defun my-python-mode-setup ()
  "Setup keybindings for Python mode."
  (map! :map python-mode-map
        :leader
        :desc "Run region or line in Python shell" "r j" #'python-shell-send-region-or-current-line
        :desc "Run current cell in Python shell" "r [" #'code-cells-eval
        :desc "Activate pyvenv" "r a" #'pyvenv-activate
        :desc "Run python" "r p" #'run-python
        :desc "Forward to next cell" "]" #'code-cells-forward-cell
        :desc "Backward to previous cell" "[" #'code-cells-backward-cell
        :desc "Jupyter run REPL" "r J" #'jupyter-run-repl))

(add-hook 'python-mode-hook #'my-python-mode-setup)
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

;; Keybindings
(map! :leader
        :desc "Switch to shell buffer" ">" #'switch-to-shell-buffer
        :desc "Next shell buffer" "t n" #'my-next-shell-buffer
        :desc "Previous shell buffer" "t p" #'my-previous-shell-buffer
        :desc "Toggle transparency" "t t" #'toggle-frame-transparency
        :desc "Toggle 100% transparency" "t T" #'toggle-frame-transparency-100
        :desc "Wrap lines" "t w" #'toggle-truncate-lines
        :desc "Find file at point" "f f" #'find-file-at-point
        :desc "consult-ripgrep" "r g" #'consult-ripgrep
        :desc "consult-find" "r f" #'consult-find
        :desc "linux apps" "\\" #'counsel-linux-app
        :desc "popper" "`" #'popper-toggle
        ;; vterm
        :desc "New vterm (multi-vterm)" "V" #'multi-vterm
        :desc "Next vterm (multi-vterm)" "v n" #'multi-vterm-next
        :desc "Previous vterm (multi-vterm)" "v p" #'multi-vterm-prev
        :desc "Execute region of line in vterm" "v r" #'multi-vterm-execute-region-or-current-line
        :desc "Open citar" "o c" #'citar-open
        :desc "Run region or line in Python shell" "r j" #'python-shell-send-region-or-current-line
        :desc "Run current cell in Python shell" "r [" #'code-cells-eval
        :desc "Activate pyvenv" "r a" #'pyvenv-activate
        :desc "Run python" "r p" #'run-python
        :desc "Forward to next cell" "]" #'code-cells-forward-cell
        :desc "Backward to previous cell" "[" #'code-cells-backward-cell
        :desc "Jupyter run REPL" "r J" #'jupyter-run-repl)

(global-set-key (kbd "C-<left>") 'shrink-window-horizontally)
(global-set-key (kbd "C-<right>") 'enlarge-window-horizontally)
(global-set-key (kbd "C-<up>") 'enlarge-window)
(global-set-key (kbd "C-<down>") 'shrink-window)

(defun my-sh-mode-setup ()
  "Setup keybindings for Python mode."
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
(require 'vterm)
(setq vterm-max-scrollback 10000)
(setq vterm-kill-buffer-on-exit t)
(setq vterm-visual-flash-delay 0.1)

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

(use-package openwith
  :config
  (setq openwith-associations
        `(,(list (openwith-make-extension-regexp '("nc"))
                 "ncview"
                 '(file))
          ,(list (openwith-make-extension-regexp '("mp4"))
                 "mpv"
                 '(file))
          ,(list (openwith-make-extension-regexp '("ods"))
                 "libreoffice --calc"
                 '(file))))
  (openwith-mode t))
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



;; ------------------------ Python ----------------------------------

;; (setq dap-auto-configure-mode t)


(require 'python)

(use-package python
  :custom
  (python-indent-offset 4)
  (python-shell-interpreter "python3"))
  ;; (dap-python-executable "python3")
  ;; (dap-python-debugger 'debugpy))
  ;; :config
  ;; (require 'dap-python)
;; (use-package lsp-mode
;;   :ensure t
;;   :hook ((python-mode . lsp-deferred)
;;          (lsp-mode . lsp-enable-which-key-integration))
;;   :commands lsp)
(require 'dape)
;; Dape configs
;;
;;
;;
;;

;; I had to create those functions, because the default dape-cwd functions do not work with me
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
             `(debugpy-flask
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

;; (setq elpy-rpc-virtualenv-path 'current)

(add-hook 'python-mode-hook 'flymake-mode)

(use-package eglot
  :config
  (add-to-list 'eglot-server-programs '(python-mode . ("pyright-langserver" "--stdio"))))
(add-hook 'python-mode-hook 'eglot-ensure)

(use-package yasnippet
  :hook (python-mode . yas-minor-mode))

(use-package pyvenv
  :config
  (pyvenv-mode 1))

(use-package conda)
(setq conda-anaconda-home "/home/anthe/software/miniconda3")
(conda-mode-line-setup)

(use-package! jupyter)
(setq jupyter-repl-echo-eval-p t)

(add-hook 'python-mode-hook 'code-cells-mode-maybe)

(use-package flycheck
  :hook (python-mode . flycheck-mode))



(setq consult-ripgrep-args "rg --null --line-buffered --color=never --max-columns=1000 --path-separator /   --smart-case --no-heading --with-filename --line-number --search-zip --.") ;added --hidden to default


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

(add-to-list 'auto-mode-alist '("\\.py\\'" . python-mode))

;; disable corfu at start to avoid overlapping with company for example FIXME
(setq! global-corfu-mode 'nil)
(global-corfu-mode -1)
(yas-global-mode -1)

(setq dired-kill-when-opening-new-dired-buffer t)


(use-package org-bullets
  ;; :after org
  :hook (org-mode . org-bullets-mode)
  :custom
  (org-bullets-bullet-list '("◉" "○" "●" "○" "●" "○" "●")))



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


;; -----------------------------audio --------------------------------

;;(require 'emms-setup)
;;(emms-all)
;;(setq emms-player-list '(emms-player-vlc))

;; (defun open-mp3-in-vlc ()
;;   "Open MP3 file in VLC, starting VLC if necessary."
;;   (interactive)
;;   ;; (vlc-start)
;;   (vlc-add (buffer-file-name)))
;; (add-to-list 'auto-mode-alist '("\\.mp3\\'" . open-mp3-in-vlc))

(defun open-mp3-in-vlc ()
  "Open MP3 file in VLC, starting VLC if necessary."
  (interactive)
  (let ((original-buffer (previous-buffer))
        (file (buffer-file-name)))
 ;; (unless (shell-command-to-string "pgrep vlc")
  (kill-buffer (current-buffer))
  (switch-to-buffer original-buffer)
  (vlc-start)
  (sleep-for 1)
  (vlc-add file)))

(add-to-list 'auto-mode-alist '("\\.mp3\\'" . open-mp3-in-vlc))

(setq large-file-warning-threshold 100000000)
(use-package pdf-tools
  :defer t
  ;; :commands (pdf-view-mode pdf-tools-install)
  :mode ("\\.pdf\\'" . pdf-view-mode)
  :config
  (pdf-tools-install)
  (setq-default pdf-view-display-size 'fit-height)
  :hook (pdf-view-mode . pdf-view-midnight-minor-mode))

;; ------------------------- terminals ----------------------------
;;
(use-package multi-vterm)
(use-package org-inline-pdf)

;; -------------------------- TRAMP ------------------------------

;; (use-package tramp
;;   :ensure t
;;   :config
;;   (setq tramp-default-remote-shell "/bin/bash")
;;   (add-to-list 'tramp-remote-path 'tramp-own-remote-path))

;; ---------------------- treesitter languages -------------------

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


;; Org-Ref
;; (use-package org-ref
;;   :ensure t
;;   :config
;;   (setq org-ref-cite-on-exit t)
;;   (setq org-ref-prettify-keywords '("href" "label" "bibliography" "bibliographystyle" "printbibliography" "nobibliography" "cite")))

;; RefTeX
;; (use-package reftex
;;   :ensure t
;;   :config
;;   (setq bibtex-completion-pdf-field "file")
;;   (setq bibtex-completion-notes-field nil))
(setq! bibtex-completion-bibliography '("~/kup/bib/kup.bib"))
(setq! citar-bibliography '("~/kup/bib/kup.bib"))

(setq! citar-notes-paths '("~/kup/bib/notes"))

(defvar citar-indicator-notes-icons
  (citar-indicator-create
   :symbol (nerd-icons-mdicon
            "nf-md-notebook"
            :face 'nerd-icons-blue
            :v-adjust -0.3)
   :function #'citar-has-notes
   :padding "  "
   :tag "has:notes"))

(defvar citar-indicator-links-icons
  (citar-indicator-create
   :symbol (nerd-icons-octicon
            "nf-oct-link"
            :face 'nerd-icons-orange
            :v-adjust -0.1)
   :function #'citar-has-links
   :padding "  "
   :tag "has:links"))

(defvar citar-indicator-files-icons
  (citar-indicator-create
   :symbol (nerd-icons-faicon
            "nf-fa-file"
            :face 'nerd-icons-purple
            :v-adjust -0.1)
   :function #'citar-has-files
   :padding "  "
   :tag "has:files"))

(setq citar-indicators
  (list citar-indicator-files-icons
        citar-indicator-notes-icons
        citar-indicator-links-icons))

(setq citar-templates
      '((main . "${author editor:30%sn}   ${date year issued:4}   ${title:80}   ${journal:16}")
        (suffix . "     ${=type=:10}  ${tags keywords:*}") ;; ${=key= id:15}
        (preview . "${author editor:%etal} (${year issued date}) ${title}, ${journal journaltitle publisher container-title collection-title}.\n")
        (note . "Notes on ${author editor:%etal}, ${title}")))

(defun clean-bibtex-entry()
  "Format the current BibTeX entry without wrapping lines."
  (interactive)
  (save-excursion
    (bibtex-beginning-of-entry)
    (let ((bibtex-align-at-equal-sign t)
          (bibtex-text-indentation 2)
          (bibtex-comma-after-last-field t)
          (bibtex-entry-format '(opts-or-alts required-fields numerical-fields
                                 page-dashes delimiters last-comma
                                 unify-case sort-fields))
          (bibtex-field-delimiters 'braces)
          (fill-column 100000)  ; Set a very large fill-column to prevent wrapping
          (max-field-width 0))
      (bibtex-clean-entry)
      (let ((end (save-excursion (bibtex-end-of-entry) (point))))
        ;; First pass: find the maximum field name width
        (save-excursion
          (while (re-search-forward "^\\s-*\\(\\w+\\)\\s-*=" end t)
            (setq max-field-width (max max-field-width (length (match-string 1))))))
        ;; Second pass: format entries FIXME: commneted out because format does not work
        ;; (while (re-search-forward "^\\s-*\\(\\w+\\)\\s-*=" end t)
        ;;   (replace-match (format "  %-*s = " max-field-width (match-string 1))))
        ))))

;; --------------------------- LATEX -----------------------------

(defun add-file-entry ()
  "Add a file entry to the BibTeX entry at point using the citation key."
  (interactive)
  (let ((key (get-citation-key)))
    (when key
      (save-excursion
        ;; (search-forward (concat "}") nil t)
        ;; (beginning-of-line)
        ;; (forward-line 1)
        (newline)
        (insert (format "  file = {:papers/%s.pdf:PDF},\n" key))
        (insert (format "  keywords = {},\n")))))
  (re-search-forward "keywords = {"))

(require 'url-http)
(defun insert-bibtex-from-doi ()
  (interactive)
  (let* ((doi (string-trim (gui-get-primary-selection)))
         (url (if (string-prefix-p "https://doi.org/" doi)
                  doi
                (concat "https://doi.org/" doi)))
         (url-request-method "GET")
         (url-mime-accept-string "application/x-bibtex"))
    (insert
     (with-current-buffer (url-retrieve-synchronously url t)
        (goto-char (point-min))
        (while (not (looking-at "\n"))
          (forward-line 1))
        (let ((string (buffer-substring-no-properties (point) (point-max))))
          (kill-buffer)
          (decode-coding-string (string-trim string) 'utf-8))))
    (clean-bibtex-entry)
    (add-file-entry)))

(defun get-citation-key ()
  "Extract the citation key from the BibTeX entry at point."
  (interactive)
  (save-excursion
    (re-search-backward "^@\\(Article\\|Book\\|InProceedings\\|PhdThesis\\|TechReport\\|Misc\\){\\([^,]*\\)," nil t)
    (match-string 2)))

(defvar default-bib "~/kup/bib/kup.bib")
(defun add-doi-to-my-bib ()
  (interactive)

  (popper-toggle)

  (let ((buffer (find-file default-bib)))
    (with-current-buffer buffer
      (goto-char (point-max))
      (insert "\n")
      (insert-bibtex-from-doi)
      (save-buffer)))
  (save-buffer))


(setq org-latex-pdf-process
      '("pdflatex -interaction nonstopmode -output-directory %o %f"
        "biber %b"
        "pdflatex -interaction nonstopmode -output-directory %o %f"
        "pdflatex -interaction nonstopmode -output-directory %o %f"))

(require 'tex-site)
(add-to-list 'auto-mode-alist '("\\.tex\\'" . LaTeX-mode))
(add-hook 'org-mode-hook 'org-fragtog-mode)

;; (use-package org-latex-impatient
;;   :defer t
;;   :hook (org-mode . org-latex-impatient-mode)
;;   :init
;;   (setq org-latex-impatient-tex2svg-bin
;;         ;; location of tex2svg executable
;;         "~/node_modules/mathjax-node-cli/bin/tex2svg"))

;; --------------- gptel config ---------------------------

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
(load-api-keys "~/.my_apis.json")

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
           )))

(defun my-gptel-mode-setup ()
  "Setup keybindings for gptel mode."
  (map! :map gptel-mode
        :leader
        :desc "gptel send" "e" #'gptel-send))

(add-hook 'gptel-mode-hook #'my-gptel-mode-setup)

(map! :leader
      :desc "Open gptel" "o g" #'gptel
      :desc "Eval region in gptel (gptel-send)" "m e g" #'gptel-send)

;; ------------------------ Machine specific configuration -----------------------------
;; An extra file next to config.el in case there are specific configuration for a particular machine such as a HPC

(when (file-exists-p (expand-file-name "config-machine.el" doom-user-dir))
  (load (expand-file-name "config-machine.el" doom-user-dir)))

