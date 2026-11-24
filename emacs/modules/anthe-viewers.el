;;; anthe-viewers.el --- zathura, nsxiv and mpv as Emacs buffers -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  PDFs open in zathura and images in nsxiv (anthe-pdf.el): X windows, shown
;;  as EXWM buffers.  Here they are named "PDF: NAME" and "Image: NAME", and
;;  get a mode whose keys, in Evil's normal state, are pdf-view's, sent on to
;;  the program: j/k scroll, C-j/C-k the next or previous page or image, C-d/C-u
;;  half a page, gg/G, +/-/=, P fit the page, W the width, H the height, / and
;;  ? search, o the outline on the side, q close; SPC s s searches the lines of
;;  the text, SPC s i the outline's titles, showing each page as it goes.  i still passes every key on (exwm-evil), ESC comes back.
;;
;;  A file already shown in a viewer shows in that buffer again, rather than in
;;  a second viewer, and a new viewer shows in the window it was opened from.
;;  Previews while completing (consult's, citar-open's) stay in pdf-view and
;;  image-mode (anthe-pdf.el).
;;
;;  Videos open in mpv, "Video: NAME", driven through its command socket:
;;  p or RET pause, . and , (C-j/C-k) a frame, h/l 5 s, j/k 1 s, H/L a minute,
;;  C-d/C-u 30 s, gg/G, [ ] { } speed, +/- zoom, = back to normal, s a frame
;;  as PNG, a an A-B loop.  Emacs doesn't read a video when visiting it, and
;;  previews it as a frame of it (ffmpegthumbnailer), with its length and size.
;;
;;  SPC k o w opens the file of the buffer, or dired's at point, in another
;;  program, chosen among those for its type (their .desktop files) and Emacs'.
;;
;;; Code:

(declare-function exwm-input--fake-key "exwm-input")
(declare-function exwm-workspace-rename-buffer "exwm-workspace")
(declare-function exwm-workspace-move-window "exwm-workspace")
(declare-function xcb:keysyms:event->keysyms "xcb-keysyms")
(declare-function xcb:keysyms:keysym->keycode "xcb-keysyms")
(declare-function xcb:+request "xcb")
(declare-function xcb:flush "xcb")
(declare-function xcb:marshal "xcb-types")
(declare-function vertico--candidate "vertico")
(declare-function citar-get-files "citar")
(declare-function citar--extract-candidate-citekey "citar")
(defvar exwm-class-name)
(defvar exwm-title)
(defvar exwm--id)
(defvar exwm--frame)
(defvar exwm--connection)
(defvar exwm--root)
(defvar vertico--input)

;;; Opening files

(defvar-local anthe-viewers-file nil
  "The file this viewer's buffer was opened on.")

(defvar anthe-viewers--pending nil
  "The viewers started, not shown yet: (FILE WINDOW PID).")

(defun anthe-viewers--buffer (file)
  "The viewer's buffer showing FILE."
  (seq-find (lambda (buffer) (equal (buffer-local-value 'anthe-viewers-file buffer) file))
            (buffer-list)))

(defun anthe-viewers--show (buffer window)
  "Show the viewer's BUFFER in WINDOW, and only there."
  (when (and (buffer-live-p buffer) (window-live-p window))
    (dolist (other (get-buffer-window-list buffer nil t))
      (unless (eq other window)
        (switch-to-prev-buffer other t)))
    (unless (eq (buffer-local-value 'exwm--frame buffer) (window-frame window))
      (exwm-workspace-move-window (window-frame window) (buffer-local-value 'exwm--id buffer)))
    (set-window-buffer window buffer)))

(defun anthe-viewers-open (file command &optional buffer)
  "Show FILE with COMMAND, a list, the file appended: in the viewer showing it
already, or a new one, in the selected window.  BUFFER, FILE's Emacs buffer,
is killed."
  (let* ((file (expand-file-name file))
         (window (selected-window))
         (pending (assoc file anthe-viewers--pending)))
    (cond ((anthe-viewers--buffer file))
          (pending (setf (nth 1 pending) window))
          (t
           (let ((process (make-process :name (car command) :noquery t
                                        :command (append command (list file)))))
             (push (list file window (process-id process)) anthe-viewers--pending))))
    ;; After the command that opened the buffer has shown it
    (run-at-time 0 nil
                 (lambda ()
                   (let ((windows (and (buffer-live-p buffer) (get-buffer-window-list buffer nil t))))
                     (when (buffer-live-p buffer)
                       (kill-buffer buffer))
                     (when-let* ((viewer (anthe-viewers--buffer file)))
                       (anthe-viewers--show viewer (or (car windows) window))))))))

(defun anthe-viewers--pid ()
  "The process id of the program of this buffer."
  (string-to-number
   (car (last (split-string
               (shell-command-to-string (format "xprop -id %d _NET_WM_PID" exwm--id)))))))

(defun anthe-viewers--process-file ()
  "The file the program of this buffer was started on: its last argument."
  (let* ((pid (anthe-viewers--pid))
         (args (ignore-errors
                 (with-temp-buffer
                   (insert-file-contents (format "/proc/%d/cmdline" pid))
                   (split-string (buffer-string) "\0" t)))))
    (when args
      (expand-file-name (car (last args)) (file-truename (format "/proc/%d/cwd" pid))))))

;;; SPC f on the file shown: D deletes it (and closes the viewer), R moves it,
;;; C copies it, y its path, as in pdf-view.  Doom's commands read
;;; `buffer-file-name', which a viewer's buffer has not: it takes the file
;;; for them.  R moves it itself: `set-visited-file-name' would make the
;;; buffer a file's, out of EXWM's mode.

(defun anthe-viewers--as-file-a (fn &rest args)
  "Call FN with ARGS, the viewer's file as the buffer's."
  (if anthe-viewers-file
      (let ((buffer-file-name anthe-viewers-file))
        (apply fn args))
    (apply fn args)))

(dolist (command '(doom/delete-this-file doom/copy-this-file
                   +default/yank-buffer-path +default/yank-buffer-path-relative-to-project))
  (advice-add command :around #'anthe-viewers--as-file-a))

(defun anthe-viewers--move-a (fn new-path &optional force-p)
  "Move the viewer's file to NEW-PATH; FN, `doom/move-this-file', elsewhere."
  (if-let* ((old-path anthe-viewers-file))
      (let ((new-path (expand-file-name new-path)))
        (when (directory-name-p new-path)
          (setq new-path (concat new-path (file-name-nondirectory old-path))))
        (make-directory (file-name-directory new-path) t)
        (rename-file old-path new-path (or force-p 1))
        (setq anthe-viewers-file new-path)
        (message "File moved to %S" (abbreviate-file-name new-path)))
    (funcall fn new-path force-p)))

(advice-add 'doom/move-this-file :around #'anthe-viewers--move-a)

;;; Keys

(defun anthe-viewers--fake-key (event)
  "Send EVENT to the program of the selected window.  nsxiv gets the key's
press alone: it drops a press whose release is already there, taking it for
a key held down, and `exwm-input--fake-key' sends both at once.  RET, TAB
and ESC go as their keys, not as C-m, C-i and C-[."
  (setq event (pcase event (?\r 'return) (?\t 'tab) (?\e 'escape) (_ event)))
  (if (not (equal exwm-class-name "Nsxiv"))
      (exwm-input--fake-key event)
    (let* ((keysyms (xcb:keysyms:event->keysyms exwm--connection event))
           (keycode (xcb:keysyms:keysym->keycode exwm--connection (caar keysyms))))
      (when (/= 0 keycode)
        (xcb:+request exwm--connection
            (make-instance 'xcb:SendEvent
                           :propagate 0 :destination exwm--id
                           :event-mask xcb:EventMask:NoEvent
                           :event (xcb:marshal
                                   (make-instance 'xcb:KeyPress
                                                  :detail keycode
                                                  :time xcb:Time:CurrentTime
                                                  :root exwm--root :event exwm--id
                                                  :child 0
                                                  :root-x 0 :root-y 0
                                                  :event-x 0 :event-y 0
                                                  :state (cdar keysyms)
                                                  :same-screen 1)
                                   exwm--connection)))
        (xcb:flush exwm--connection)))))

(defun anthe-viewers--send (&rest keys)
  "Send KEYS, strings as for `kbd', to the program of the selected window."
  (dolist (key keys)
    (mapc #'anthe-viewers--fake-key (listify-key-sequence (kbd key)))))

(defun anthe-viewers--type (text)
  "Type TEXT in the program of the selected window."
  (mapc #'anthe-viewers--fake-key (string-to-list text)))

(defmacro anthe-viewers--keys (&rest keys)
  "A command sending KEYS, a count of times."
  `(lambda (count)
     (interactive "p")
     (anthe-viewers--repeat (min (max count 1) 100) (lambda () (anthe-viewers--send ,@keys)))))

(defun anthe-viewers--repeat (count send)
  "Call SEND COUNT times, a moment apart: nsxiv drops a key arriving right
behind the same one."
  (funcall send)
  (let ((window (selected-window)))
    (dotimes (i (1- count))
      (run-at-time (* 0.03 (1+ i)) nil
                   (lambda ()
                     (when (window-live-p window)
                       (with-selected-window window
                         (funcall send))))))))

;;; zathura

(defvar-local anthe-zathura-page nil
  "The page zathura shows, from its title (window-title-page in zathurarc).")

(defun anthe-zathura-search (&optional backward)
  "Search the document, asking for the text in the minibuffer; BACKWARD with ?."
  (interactive)
  (let ((text (read-string (if backward "Search backward: " "Search: ")))
        (window (selected-window)))
    (unless (string-empty-p text)
      (anthe-viewers--send (if backward "?" "/"))
      ;; Its input bar opens with the "/" and puts the cursor after it a moment
      ;; later: typed right away, the text went before it
      (run-at-time 0.15 nil
                   (lambda ()
                     (when (window-live-p window)
                       (with-selected-window window
                         (anthe-viewers--type text)
                         (anthe-viewers--send "RET"))))))))

(defun anthe-zathura-search-backward ()
  "Search the document backward."
  (interactive)
  (anthe-zathura-search t))

(defun anthe-zathura--hint-length ()
  "The length of the link hints zathura shows, 0 if none: a property of its
D-Bus interface added by a patch (rcfiles/zathura/link-hints.patch)."
  (or (ignore-errors
        (dbus-get-property :session (format "org.pwmt.zathura.PID-%d" (anthe-viewers--pid))
                           "/org/pwmt/zathura" "org.pwmt.zathura" "linkhints"))
      0))

(defun anthe-zathura-follow-link ()
  "Label the links shown with letters, as qutebrowser, and follow the one
whose letters are typed: zathura follows it once they all are."
  (interactive)
  (anthe-viewers--send "f")
  (let ((length 0) (typed ""))
    ;; It shows them a moment after
    (dotimes (_ 10)
      (when (zerop length)
        (sleep-for 0.03)
        (setq length (anthe-zathura--hint-length))))
    (if (zerop length)
        (message "No link shown")
      (condition-case nil
          (while (< (length typed) length)
            (let ((key (read-key (format "Link: %s" typed))))
              (cond ((memq key '(escape ?\e ?\C-g))
                     (signal 'quit nil))
                    ((memq key '(backspace ?\d))
                     (unless (string-empty-p typed)
                       (setq typed (substring typed 0 -1))
                       (anthe-viewers--send "<backspace>")))
                    ((characterp key)
                     (setq typed (concat typed (string key)))
                     (anthe-viewers--fake-key key)))))
        (quit (anthe-viewers--send "<escape>"))))))

(defun anthe-zathura-goto-page (page)
  "Go to PAGE."
  (interactive "nPage: ")
  (anthe-viewers--type (number-to-string page))
  (anthe-viewers--send "G"))

(defun anthe-zathura--file ()
  "The PDF zathura shows."
  (or anthe-viewers-file (anthe-viewers--process-file)))

(defconst anthe-zathura--script
  (expand-file-name "anthe-viewers-pdf.js" (file-name-directory (or load-file-name buffer-file-name)))
  "MuPDF's script printing a page's links and text, the outline, or the text.")

(defun anthe-zathura--links (file page)
  "The web addresses on PAGE of FILE: links, and addresses and DOIs in the text."
  (let* ((output (with-temp-buffer
                   (call-process "mutool" nil t nil "run" anthe-zathura--script
                                 "links" file (number-to-string page))
                   (buffer-string)))
         (split (string-search "\nTEXT\n" output))
         (links (and split (substring output 0 split)))
         (text (if split (substring output (+ split 6)) output))
         addresses)
    (dolist (line (split-string (or links "") "\n" t))
      (when (string-prefix-p "LINK " line)
        (push (substring line 5) addresses)))
    (let ((start 0))
      (while (string-match "https?://[^][ \t\n<>\"(){}]+" text start)
        (push (match-string 0 text) addresses)
        (setq start (match-end 0))))
    (let ((start 0))
      (while (string-match "\\_<10\\.[0-9]\\{4,9\\}/[^] \t\n<>\"(){}[]+" text start)
        (push (concat "https://doi.org/" (match-string 0 text)) addresses)
        (setq start (match-end 0))))
    (delete-dups
     (mapcar (lambda (address)
               ;; A sentence's full stop or comma, and dx.doi.org, the old name of doi.org
               (replace-regexp-in-string
                "\\`https?://\\(?:dx\\.\\)?doi\\.org/" "https://doi.org/"
                (replace-regexp-in-string "[.,;:]+\\'" "" address)))
             (nreverse addresses)))))

(defun anthe-zathura-open-link ()
  "Open a web address or DOI of the page shown, in the browser."
  (interactive)
  (let* ((file (anthe-zathura--file))
         (page (string-to-number (or anthe-zathura-page "1")))
         (links (and file (anthe-zathura--links file page))))
    (unless links
      (user-error "No link or DOI on page %d" page))
    (browse-url (if (cdr links)
                    (completing-read "Open: " links nil t)
                  (car links)))))

(defun anthe-zathura-open-in-emacs ()
  "Open this PDF in pdf-tools, at this page, and close zathura."
  (interactive)
  (let ((file (anthe-zathura--file))
        (page (and anthe-zathura-page (string-to-number anthe-zathura-page)))
        (zathura (current-buffer)))
    (unless (and file (file-exists-p file))
      (user-error "Can't find the file zathura shows"))
    (defvar anthe/pdf-viewer)
    (let ((anthe/pdf-viewer 'pdf-tools))
      (find-file file))
    (when (and page (fboundp 'pdf-view-goto-page))
      (pdf-view-goto-page page))
    (kill-buffer zathura)))

;;; The outline and the text, read with MuPDF, as pdf-tools' outline and occur

(declare-function consult--read "consult")

(defvar anthe-zathura--read-cache (make-hash-table :test #'equal)
  "What `anthe-zathura--script' printed, from (COMMAND FILE MODIFIED).")

(defun anthe-zathura--read (command file fields)
  "The lines COMMAND of `anthe-zathura--script' prints for FILE, each split into
FIELDS at its first tabs."
  (let ((key (list command file (file-attribute-modification-time (file-attributes file)))))
    (or (gethash key anthe-zathura--read-cache)
        (puthash key
                 (mapcar (lambda (line) (anthe-zathura--fields line fields))
                         (with-temp-buffer
                           (call-process "mutool" nil '(t nil) nil "run" anthe-zathura--script command file)
                           (split-string (buffer-string) "\n" t)))
                 anthe-zathura--read-cache))))

(defun anthe-zathura--fields (line fields)
  "LINE split at its first FIELDS - 1 tabs."
  (let (parts)
    (dotimes (_ (1- fields))
      (let ((tab (or (string-search "\t" line) (length line))))
        (push (substring line 0 tab) parts)
        (setq line (substring line (min (length line) (1+ tab))))))
    (nreverse (cons line parts))))

(defun anthe-zathura--outline (file)
  "The outline of FILE, as (LEVEL PAGE TITLE), PAGE from 1, 0 for none."
  (mapcar (lambda (entry)
            (list (string-to-number (nth 0 entry)) (string-to-number (nth 1 entry)) (nth 2 entry)))
          (anthe-zathura--read "outline" file 3)))

(defun anthe-zathura--show-page (zathura page)
  "Show PAGE in the window of ZATHURA, its buffer, unless it shows it."
  (when-let* (((> page 0))
              (window (get-buffer-window zathura t))
              ((not (equal (buffer-local-value 'anthe-zathura-page zathura)
                           (number-to-string page)))))
    (with-selected-window window
      (anthe-zathura-goto-page page))))

(defun anthe-zathura--choose-page (prompt candidates)
  "Choose among CANDIDATES, strings with an `anthe-page' property, with PROMPT,
showing the page of each as it is selected; on quitting, the page shown before."
  (require 'consult)
  (let* ((zathura (current-buffer))
         (start (and anthe-zathura-page (string-to-number anthe-zathura-page)))
         (page (lambda (candidate) (and candidate (get-text-property 0 'anthe-page candidate)))))
    (consult--read candidates
                   :prompt prompt
                   :sort nil
                   :require-match t
                   :lookup (lambda (selected candidates &rest _) (car (member selected candidates)))
                   :state (lambda (action candidate)
                            (pcase action
                              ('preview (when candidate
                                          (anthe-zathura--show-page zathura (funcall page candidate))))
                              ('return (if candidate
                                           (anthe-zathura--show-page zathura (funcall page candidate))
                                         (when start (anthe-zathura--show-page zathura start)))))))))

(defun anthe-zathura-outline-search ()
  "Go to a section of the outline, chosen by its title and those it is in."
  (interactive)
  (let* ((file (anthe-zathura--file))
         (entries (and file (anthe-zathura--outline file)))
         path candidates)
    (unless entries (user-error "This PDF has no outline"))
    (pcase-dolist (`(,level ,page ,title) entries)
      (setq path (append (seq-take path (1- level)) (list title)))
      (push (propertize (concat (string-join path " › ")
                                (propertize (format "  %d" page) 'face 'shadow))
                        'anthe-page page)
            candidates))
    (anthe-zathura--choose-page "Section: " (nreverse candidates))))

(defun anthe-zathura-search-lines ()
  "Go to a line of the PDF's text, as `consult-line'."
  (interactive)
  (let ((file (anthe-zathura--file)))
    (unless file (user-error "Can't find the file zathura shows"))
    (anthe-zathura--choose-page
     "Line: "
     (or (mapcar (pcase-lambda (`(,page ,line))
                   (let ((page (string-to-number page)))
                     (propertize (concat (propertize (format "%4d  " page) 'face 'shadow) line)
                                 'anthe-page page)))
                 (anthe-zathura--read "text" file 2))
         (user-error "This PDF has no text")))))

;; The outline on the side, as pdf-tools'

(defvar-local anthe-zathura-outline--zathura nil
  "The zathura buffer the outline is of.")

(defvar-local anthe-zathura-outline-follow t
  "Whether the section the cursor stops on shows in zathura.")

(defvar anthe-zathura-outline--timer nil)

(define-derived-mode anthe-zathura-outline-mode special-mode "Outline"
  "The outline of a PDF shown in zathura.  The section the cursor stops on
shows, RET goes to it and o too, closing the outline; TAB folds, f stops or
starts following the cursor."
  (setq truncate-lines t)
  (setq-local outline-regexp "\\*+ ")
  (outline-minor-mode 1)
  (add-hook 'post-command-hook #'anthe-zathura-outline--follow nil t))

(defun anthe-zathura-outline--page ()
  "The page of the section at point."
  (get-text-property (line-beginning-position) 'anthe-page))

(defun anthe-zathura-outline--follow ()
  "Show the section the cursor stops on, a moment after."
  (when (timerp anthe-zathura-outline--timer)
    (cancel-timer anthe-zathura-outline--timer))
  (when-let* ((anthe-zathura-outline-follow)
              (page (anthe-zathura-outline--page))
              (zathura anthe-zathura-outline--zathura))
    (setq anthe-zathura-outline--timer
          (run-with-idle-timer 0.2 nil (lambda ()
                                         (when (buffer-live-p zathura)
                                           (anthe-zathura--show-page zathura page)))))))

(defun anthe-zathura-outline-goto (&optional quit)
  "Show the section at point and go to zathura; with QUIT, close the outline."
  (interactive)
  (let ((page (anthe-zathura-outline--page))
        (zathura anthe-zathura-outline--zathura)
        (outline (selected-window)))
    (unless (buffer-live-p zathura) (user-error "Its zathura is closed"))
    (when page (anthe-zathura--show-page zathura page))
    (when-let* ((window (get-buffer-window zathura)))
      (select-window window))
    (when quit (quit-window nil outline))))

(defun anthe-zathura-outline-goto-and-quit ()
  "Show the section at point, go to zathura and close the outline."
  (interactive)
  (anthe-zathura-outline-goto t))

(defun anthe-zathura-outline-toggle-follow ()
  "Stop or start showing the section the cursor stops on."
  (interactive)
  (setq anthe-zathura-outline-follow (not anthe-zathura-outline-follow))
  (message "Following the cursor %s" (if anthe-zathura-outline-follow "on" "off")))

(defun anthe-zathura-outline ()
  "Show the PDF's outline on the side, at the section of the page shown."
  (interactive)
  (let* ((zathura (current-buffer))
         (file (anthe-zathura--file))
         (entries (and file (anthe-zathura--outline file)))
         (page (string-to-number (or anthe-zathura-page "1")))
         (buffer (get-buffer-create (format "*Outline: %s*" (file-name-nondirectory file))))
         here)
    (unless entries (user-error "This PDF has no outline"))
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (anthe-zathura-outline-mode)
        (erase-buffer)
        (setq anthe-zathura-outline--zathura zathura)
        (pcase-dolist (`(,level ,entry-page ,title) entries)
          (when (and (> entry-page 0) (<= entry-page page))
            (setq here (point)))
          (insert (propertize
                   (concat (propertize (concat (make-string level ?*) " ")
                                       'display (make-string (* 2 (1- level)) ?\s))
                           (propertize title 'face (intern (format "outline-%d" (1+ (mod (1- level) 8)))))
                           (when (> entry-page 0)
                             (concat (propertize " " 'display `(space :align-to (- right ,(1+ (length (number-to-string entry-page))))))
                                     (propertize (number-to-string entry-page) 'face 'shadow))))
                   'anthe-page (and (> entry-page 0) entry-page))
                  "\n"))
        (goto-char (or here (point-min)))))
    ;; Next to the PDF, splitting its window, whatever is on the frame's left
    (let* ((pdf (get-buffer-window zathura))
           (window (or (get-buffer-window buffer)
                       (display-buffer-in-direction
                        buffer `((direction . left) (window . ,pdf)
                                 (window-width . ,(max 30 (/ (window-total-width pdf) 4))))))))
      (set-window-point window (with-current-buffer buffer (point)))
      (select-window window))))

(with-eval-after-load 'evil
  (evil-set-initial-state 'anthe-zathura-outline-mode 'normal)
  (evil-define-key* 'normal anthe-zathura-outline-mode-map
    (kbd "RET") #'anthe-zathura-outline-goto
    "o" #'anthe-zathura-outline-goto-and-quit
    (kbd "TAB") #'outline-cycle
    (kbd "<backtab>") #'outline-cycle-buffer
    "f" #'anthe-zathura-outline-toggle-follow
    "q" #'quit-window))

(define-minor-mode anthe-zathura-mode
  "Keys for zathura's EXWM buffer, like pdf-view's, sent to it."
  :keymap (make-sparse-keymap))

(evil-define-key* 'normal anthe-zathura-mode-map
  "j" (anthe-viewers--keys "j")
  "k" (anthe-viewers--keys "k")
  "h" (anthe-viewers--keys "h")
  "l" (anthe-viewers--keys "l")
  (kbd "C-j") (anthe-viewers--keys "J")
  (kbd "C-k") (anthe-viewers--keys "K")
  "J" (anthe-viewers--keys "J")
  "K" (anthe-viewers--keys "K")
  (kbd "C-d") (anthe-viewers--keys "C-d")
  (kbd "C-u") (anthe-viewers--keys "C-u")
  (kbd "C-f") (anthe-viewers--keys "C-f")
  (kbd "C-b") (anthe-viewers--keys "C-b")
  "gg" (anthe-viewers--keys "g g")
  "G" (anthe-viewers--keys "G")
  "+" (anthe-viewers--keys "+")
  "-" (anthe-viewers--keys "-")
  "=" (anthe-viewers--keys "=")
  "P" (anthe-viewers--keys "a")         ; the whole page
  "H" (anthe-viewers--keys "a")
  "W" (anthe-viewers--keys "s")         ; the width
  "d" (anthe-viewers--keys "d")         ; two pages side by side
  "r" (anthe-viewers--keys "r")         ; rotate
  "R" (anthe-viewers--keys "R")         ; reload
  "n" (anthe-viewers--keys "n")
  "N" (anthe-viewers--keys "N")
  "/" #'anthe-zathura-search
  "?" #'anthe-zathura-search-backward
  "f" #'anthe-zathura-follow-link
  "o" #'anthe-zathura-outline            ; on the side, as pdf-tools'
  (kbd "C-o") (anthe-viewers--keys "C-o") ; back where a link was followed
  (kbd "TAB") (anthe-viewers--keys "TAB") ; the outline: j/k, l/h unfold, RET
  (kbd "RET") (anthe-viewers--keys "RET")
  "zm" (anthe-viewers--keys "C-r")      ; night or light mode, as pdf-view's
  "q" #'kill-current-buffer)

;; SPC s l, which follows a link elsewhere; SPC s s and SPC s i, which search
;; a buffer's lines and its headings
(define-key anthe-zathura-mode-map [remap link-hint-open-link] #'anthe-zathura-open-link)
(define-key anthe-zathura-mode-map [remap +default/search-buffer] #'anthe-zathura-search-lines)
(define-key anthe-zathura-mode-map [remap imenu] #'anthe-zathura-outline-search)
(define-key anthe-zathura-mode-map [remap consult-imenu] #'anthe-zathura-outline-search)

(map! :map anthe-zathura-mode-map
      :localleader
      :desc "Night mode" "m" (anthe-viewers--keys "C-r")
      :desc "Go to page" "g" #'anthe-zathura-goto-page
      :desc "Outline" "o" #'anthe-zathura-outline
      :desc "Search the outline" "i" #'anthe-zathura-outline-search
      :desc "Search the lines" "s" #'anthe-zathura-search-lines
      :desc "Open a link or DOI" "l" #'anthe-zathura-open-link
      :desc "Open in Emacs (pdf-tools)" "e" #'anthe-zathura-open-in-emacs)

;;; nsxiv

(define-minor-mode anthe-nsxiv-mode
  "Keys for nsxiv's EXWM buffer, like pdf-view's, sent to it."
  :keymap (make-sparse-keymap))

(evil-define-key* 'normal anthe-nsxiv-mode-map
  "j" (anthe-viewers--keys "j")         ; pan
  "k" (anthe-viewers--keys "k")
  "h" (anthe-viewers--keys "h")
  "l" (anthe-viewers--keys "l")
  (kbd "C-j") (anthe-viewers--keys "n") ; the next image
  (kbd "C-k") (anthe-viewers--keys "p")
  "J" (anthe-viewers--keys "n")
  "K" (anthe-viewers--keys "p")
  "n" (anthe-viewers--keys "n")
  "p" (anthe-viewers--keys "p")
  "gg" (anthe-viewers--keys "g")
  "G" (anthe-viewers--keys "G")
  "+" (anthe-viewers--keys "+")
  "-" (anthe-viewers--keys "-")
  "=" (anthe-viewers--keys "=")         ; 100 %
  "P" (anthe-viewers--keys "W")         ; fit the window
  "W" (anthe-viewers--keys "e")         ; its width
  "H" (anthe-viewers--keys "E")         ; its height
  "r" (anthe-viewers--keys ">")         ; rotate
  "R" (anthe-viewers--keys "<")
  (kbd "RET") (anthe-viewers--keys "RET") ; thumbnails
  "q" #'kill-current-buffer)

;;; mpv

(defvar anthe-video-regexp
  "\\.\\(?:mp4\\|m4v\\|mkv\\|webm\\|mov\\|avi\\|mpe?g\\|ogv\\|flv\\|wmv\\)\\'"
  "The files opened in mpv.")

(defvar-local anthe-mpv--ipc nil "The connection to mpv's command socket.")

(defun anthe-mpv--socket (file)
  "The command socket of the mpv showing FILE."
  (expand-file-name (concat "anthe-mpv-" (md5 file))
                    (or (getenv "XDG_RUNTIME_DIR") temporary-file-directory)))

(defun anthe-mpv-command ()
  "The command opening a video in mpv, the file to append."
  (defvar pdf-view-midnight-colors)
  (list "mpv" "--keep-open=yes" "--hr-seek=yes" "--osd-fractions" "--title=${filename}"
        ;; Around the video, the paper of the PDFs and images (anthe-pdf.el)
        "--background=color"
        (concat "--background-color=" (or (cdr-safe (bound-and-true-p pdf-view-midnight-colors)) "#000000"))
        ;; Its socket, for the file appended
        "--input-ipc-server=SOCKET"))

(defun anthe-mpv-open (file &optional buffer)
  "Show FILE in mpv, as an Emacs buffer; BUFFER, FILE's, is killed."
  (let ((file (expand-file-name file)))
    (anthe-viewers-open file (mapcar (lambda (arg)
                                       (string-replace "SOCKET" (anthe-mpv--socket file) arg))
                                     (anthe-mpv-command))
                        buffer)))

(defun anthe-mpv--send (&rest command)
  "Send COMMAND, its name and arguments, to the mpv of this buffer."
  (unless (process-live-p anthe-mpv--ipc)
    (setq anthe-mpv--ipc
          (condition-case nil
              (make-network-process :name "mpv-ipc" :family 'local :noquery t
                                    :service (anthe-mpv--socket (or anthe-viewers-file ""))
                                    :filter #'ignore)
            (file-error (user-error "No connection to mpv (its socket)")))))
  (process-send-string anthe-mpv--ipc
                       (concat (json-encode `((command . ,(vconcat command)))) "\n")))

(defun anthe-mpv--where ()
  "Show the frame and the time on the video."
  (anthe-mpv--send "show-text" "${estimated-frame-number} / ${estimated-frame-count}   ${time-pos/full} / ${duration}${?speed!=1.000:   ×${speed}}" 2000))

(defmacro anthe-mpv--command (doc &rest commands)
  "A command sending COMMANDS, each a list, a count of times, then showing where."
  `(lambda (count)
     ,doc
     (interactive "p")
     (dotimes (_ (min (max count 1) 1000))
       ,@(mapcar (lambda (command) `(anthe-mpv--send ,@command)) commands))
     (anthe-mpv--where)))

(defun anthe-mpv-seek (seconds)
  "Go SECONDS forward, backward if negative, times the count."
  (lambda (count)
    (interactive "p")
    (anthe-mpv--send "seek" (* seconds (max count 1)) "relative+exact")
    (anthe-mpv--where)))

(defun anthe-mpv-goto (time)
  "Go to TIME: seconds, M:SS or H:MM:SS."
  (interactive "sGo to (s, m:ss or h:mm:ss): ")
  (let ((seconds (seq-reduce (lambda (total part) (+ (* 60 total) (string-to-number part)))
                             (split-string time ":") 0)))
    (anthe-mpv--send "seek" seconds "absolute+exact")
    (anthe-mpv--where)))

(defun anthe-mpv-screenshot ()
  "Save the frame shown, as a PNG next to the video."
  (interactive)
  (let ((file (format "%s-%s.png" (file-name-sans-extension anthe-viewers-file)
                      (format-time-string "%Y%m%d-%H%M%S"))))
    (anthe-mpv--send "screenshot-to-file" file "video")
    (message "Frame saved as %s" (abbreviate-file-name file))))

(defun anthe-mpv-pause ()
  "Pause or play."
  (interactive)
  (anthe-mpv--send "cycle" "pause")
  (anthe-mpv--where))

(defun anthe-mpv-reset ()
  "Back to normal: speed 1, no zoom."
  (interactive)
  (anthe-mpv--send "set_property" "speed" 1)
  (anthe-mpv--send "set_property" "video-zoom" 0)
  (anthe-mpv--send "set_property" "video-pan-x" 0)
  (anthe-mpv--send "set_property" "video-pan-y" 0)
  (anthe-mpv--where))

(define-minor-mode anthe-mpv-mode
  "Keys for mpv's EXWM buffer, sent through its command socket."
  :keymap (make-sparse-keymap)
  (unless anthe-mpv-mode
    (when (process-live-p anthe-mpv--ipc) (delete-process anthe-mpv--ipc))))

(evil-define-key* 'normal anthe-mpv-mode-map
  "p" #'anthe-mpv-pause
  (kbd "RET") #'anthe-mpv-pause
  "." (anthe-mpv--command "The next frame." ("frame-step"))
  "," (anthe-mpv--command "The previous frame." ("frame-back-step"))
  (kbd "C-j") (anthe-mpv--command "The next frame." ("frame-step"))
  (kbd "C-k") (anthe-mpv--command "The previous frame." ("frame-back-step"))
  "l" (anthe-mpv-seek 5)
  "h" (anthe-mpv-seek -5)
  "j" (anthe-mpv-seek 1)
  "k" (anthe-mpv-seek -1)
  "L" (anthe-mpv-seek 60)
  "H" (anthe-mpv-seek -60)
  (kbd "C-d") (anthe-mpv-seek 30)
  (kbd "C-u") (anthe-mpv-seek -30)
  "gg" (anthe-mpv--command "The start." ("seek" 0 "absolute+exact"))
  "G" (anthe-mpv--command "The end." ("seek" 100 "absolute-percent+exact"))
  "[" (anthe-mpv--command "Slower." ("multiply" "speed" 0.9))
  "]" (anthe-mpv--command "Faster." ("multiply" "speed" 1.1))
  "{" (anthe-mpv--command "Half as fast." ("multiply" "speed" 0.5))
  "}" (anthe-mpv--command "Twice as fast." ("multiply" "speed" 2.0))
  "+" (anthe-mpv--command "Zoom in." ("add" "video-zoom" 0.1))
  "-" (anthe-mpv--command "Zoom out." ("add" "video-zoom" -0.1))
  "=" #'anthe-mpv-reset
  "r" (anthe-mpv--command "Rotate." ("cycle-values" "video-rotate" "90" "180" "270" "0"))
  "a" (anthe-mpv--command "Set the loop's start, its end, or clear it." ("ab-loop"))
  "m" (anthe-mpv--command "Mute." ("cycle" "mute"))
  "s" #'anthe-mpv-screenshot
  "o" #'anthe-mpv--where
  "q" #'kill-current-buffer)

(map! :map anthe-mpv-mode-map
      :localleader
      :desc "Go to a time" "g" #'anthe-mpv-goto
      :desc "Save the frame" "s" #'anthe-mpv-screenshot
      :desc "Statistics" "i" (anthe-mpv--command "Statistics." ("script-binding" "stats/display-stats-toggle")))

;; Visiting a video reads nothing (it can be gigabytes), and asks nothing
(defun anthe-video--file-handler (operation &rest args)
  "Visit a video without reading it: OPERATION on ARGS, the others as usual."
  (if (and (eq operation 'insert-file-contents) (nth 1 args))
      (let ((file (expand-file-name (car args))))
        (setq buffer-file-name file)
        (set-visited-file-modtime)
        (set-buffer-modified-p nil)
        (list file 0))
    (let ((inhibit-file-name-handlers
           (cons #'anthe-video--file-handler
                 (and (eq inhibit-file-name-operation operation) inhibit-file-name-handlers)))
          (inhibit-file-name-operation operation))
      (apply operation args))))

(add-to-list 'file-name-handler-alist (cons anthe-video-regexp #'anthe-video--file-handler))

(define-advice abort-if-file-too-large (:around (fn size op-type filename &rest args) anthe-video)
  "Not for a video, which isn't read."
  (unless (and filename (string-match-p anthe-video-regexp filename))
    (apply fn size op-type filename args)))


;; Previews: a frame, its length and size
(defun anthe-video--frame (file)
  "A PNG of a frame of FILE, a tenth in, made once, or nil."
  (let ((png (expand-file-name
              (format "anthe-video-%s.png"
                      (md5 (format "%s %s" file (file-attribute-modification-time (file-attributes file)))))
              temporary-file-directory)))
    (when (or (file-exists-p png)
              (zerop (call-process "ffmpegthumbnailer" nil nil nil
                                   "-i" file "-o" png "-s" "1280" "-t" "10%")))
      png)))

(defun anthe-video--about (file)
  "FILE's length, size and frame rate, as a line."
  (when-let* ((json (ignore-errors
                      (with-temp-buffer
                        (call-process "ffprobe" nil t nil "-v" "error" "-select_streams" "v:0"
                                      "-show_entries" "format=duration:stream=width,height,avg_frame_rate"
                                      "-of" "json" file)
                        (goto-char (point-min))
                        (json-parse-buffer :object-type 'alist)))))
    (let* ((stream (and (> (length (alist-get 'streams json)) 0) (aref (alist-get 'streams json) 0)))
           (duration (string-to-number (or (alist-get 'duration (alist-get 'format json)) "0")))
           (rate (alist-get 'avg_frame_rate stream))
           (fps (and rate (string-match "\\`\\([0-9]+\\)/\\([0-9]+\\)\\'" rate)
                     (/= 0 (string-to-number (match-string 2 rate)))
                     (/ (string-to-number (match-string 1 rate)) (float (string-to-number (match-string 2 rate)))))))
      (string-join (delq nil (list (format-seconds (if (>= duration 3600) "%h:%.2m:%.2s" "%m:%.2s") duration)
                                   (and stream (format "%d×%d" (alist-get 'width stream) (alist-get 'height stream)))
                                   (and fps (format "%.4g fps" fps))))
                   "   "))))

(defun anthe-video--insert-preview (file)
  "Insert a frame of FILE, its length and size."
  (let ((frame (anthe-video--frame file))
        (window (or (minibuffer-selected-window) (selected-window)))
        (inhibit-read-only t))
    (erase-buffer)
    (insert "\n")
    (if frame
        (insert-image (create-image frame nil nil
                                    :max-width (- (window-body-width window t) 20)
                                    :max-height (- (window-body-height window t) 80)))
      (insert "(no frame)"))
    (insert "\n\n" (propertize (file-name-nondirectory file) 'face 'bold)
            "   " (propertize (or (anthe-video--about file) "") 'face 'shadow) "\n")
    (set-buffer-modified-p nil)
    (goto-char (point-min))))

(defun anthe-video-preview (file)
  "A buffer showing a frame of FILE, its length and size, for a preview."
  (with-current-buffer (generate-new-buffer (format "Video: %s" (file-name-nondirectory file)))
    (special-mode)
    (anthe-video--insert-preview file)
    (current-buffer)))

(define-derived-mode anthe-video-mode special-mode "Video"
  "A video's buffer: it opens in mpv, as `anthe-mpv-mode'; while completing,
a preview, it shows a frame of it."
  (when buffer-file-name
    (if (active-minibuffer-window)
        (anthe-video--insert-preview buffer-file-name)
      (anthe-mpv-open buffer-file-name (current-buffer)))))

(add-to-list 'auto-mode-alist (cons anthe-video-regexp #'anthe-video-mode))


(define-advice consult--find-file-temporarily (:around (fn name) anthe-video)
  "Preview a video as a frame of it, rather than visiting it (in mpv)."
  (if (string-match-p anthe-video-regexp name)
      (anthe-video-preview (expand-file-name name))
    (funcall fn name)))

;;; Opening with another program

(defvar anthe-open-with-integrated
  '(("application/pdf" ("zathura" . zathura) ("Emacs: pdf-tools" . pdf-tools)
     ("Emacs: emacs-reader" . emureader))
    ("image/" ("nsxiv" . nsxiv) ("Emacs: image-mode" . emacs))
    ("video/" ("mpv" . mpv)))
  "The programs opening a type of file as an Emacs buffer, by the start of its
MIME type: (NAME . VIEWER), VIEWER for `anthe-open-with--integrated'.")

(defvar anthe-open-with-hidden '("org.pwmt.zathura" "nsxiv" "mpv")
  "The .desktop files not offered, the start of their name: the programs
offered as Emacs buffers instead.")

(defun anthe-open-with--file ()
  "The file to open: this buffer's, the viewer's, dired's at point, or one asked."
  (or (and (derived-mode-p 'dired-mode) (dired-get-filename nil t))
      buffer-file-name
      anthe-viewers-file
      (read-file-name "Open: " nil nil t)))

(defun anthe-open-with--mime (file)
  (string-trim (shell-command-to-string
                (concat "xdg-mime query filetype " (shell-quote-argument file) " 2>/dev/null"))))

(defun anthe-open-with--desktop-files ()
  "The .desktop files, the first by each name, in the XDG data directories."
  (let (files)
    (dolist (dir (cons (or (getenv "XDG_DATA_HOME") "~/.local/share")
                       (split-string (or (getenv "XDG_DATA_DIRS") "/usr/local/share:/usr/share") ":" t)))
      (let ((applications (expand-file-name "applications" dir)))
        (when (file-directory-p applications)
          (dolist (file (directory-files-recursively applications "\\.desktop\\'"))
            (let ((id (string-replace "/" "-" (file-relative-name file applications))))
              (unless (assoc id files)
                (push (cons id file) files)))))))
    (nreverse files)))

(defun anthe-open-with--applications (mime)
  "The programs for MIME, from their .desktop files: (NAME . ID), the default
first."
  (let ((default (string-trim (shell-command-to-string
                               (concat "xdg-mime query default " (shell-quote-argument mime) " 2>/dev/null"))))
        (generic (concat (car (split-string mime "/")) "/*"))
        applications)
    (pcase-dolist (`(,id . ,file) (anthe-open-with--desktop-files))
      (with-temp-buffer
        (insert-file-contents file)
        (let ((field (lambda (key)
                       (goto-char (point-min))
                       ;; In its [Desktop Entry] group, before any other
                       (let ((end (save-excursion (if (re-search-forward "^\\[Desktop Action" nil t)
                                                      (match-beginning 0) (point-max)))))
                         (and (re-search-forward (format "^%s=\\(.*\\)$" key) end t)
                              (match-string 1))))))
          (when-let* ((types (funcall field "MimeType"))
                      ((seq-some (lambda (type) (member type (list mime generic)))
                                 (split-string types ";" t)))
                      ((not (equal (funcall field "Hidden") "true")))
                      ((not (seq-some (lambda (hidden) (string-prefix-p hidden id)) anthe-open-with-hidden)))
                      (name (funcall field "Name")))
            (push (cons (if (equal id default) (concat name " (default)") name) id) applications)))))
    ;; A program can have two .desktop files
    (seq-uniq (sort applications :key (lambda (application) (not (equal (cdr application) default))))
              (lambda (a b) (equal (string-remove-suffix " (default)" (car a))
                                   (string-remove-suffix " (default)" (car b)))))))

(defun anthe-open-with--integrated (viewer file)
  "Open FILE with VIEWER, a program as an Emacs buffer, or Emacs itself."
  (defvar anthe/pdf-viewer)
  (defvar anthe/image-viewer)
  (pcase viewer
    ('zathura (anthe-viewers-open file '("zathura")))
    ('nsxiv (anthe-viewers-open file '("nsxiv" "-b")))
    ('mpv (anthe-mpv-open file))
    (_ (let ((buffer (get-file-buffer file)))
         ;; Visited anew, in this viewer
         (when (and buffer (not (buffer-modified-p buffer)))
           (kill-buffer buffer)))
       (let ((anthe/pdf-viewer (if (memq viewer '(pdf-tools emureader)) viewer anthe/pdf-viewer))
             (anthe/image-viewer (if (eq viewer 'emacs) 'emacs anthe/image-viewer)))
         (find-file file)))))

(defun anthe-open-with (file)
  "Open FILE, this buffer's (or dired's at point), in another program: one of
those for its type, or Emacs.  The buffer showing it closes, unless modified."
  (interactive (list (anthe-open-with--file)))
  (let* ((file (expand-file-name file))
         (mime (anthe-open-with--mime file))
         (integrated (seq-mapcat (pcase-lambda (`(,prefix . ,viewers))
                                   (and (string-prefix-p prefix mime) viewers))
                                 anthe-open-with-integrated))
         (applications (anthe-open-with--applications mime))
         (choices (append (mapcar (lambda (viewer) (cons (car viewer) (list 'viewer (cdr viewer)))) integrated)
                          (mapcar (lambda (app) (cons (car app) (list 'desktop (cdr app)))) applications)))
         (choice (or (cdr (assoc (completing-read (format "Open %s (%s) with: " (file-name-nondirectory file) mime)
                                                  (mapcar #'car choices) nil t)
                                 choices))
                     (user-error "No program")))
         (old (current-buffer))
         ;; What shows the file now, if this buffer does
         (current (cond ((equal anthe-viewers-file file)
                         (cond (anthe-zathura-mode 'zathura) (anthe-nsxiv-mode 'nsxiv) (anthe-mpv-mode 'mpv)))
                        ((equal buffer-file-name file)
                         (cond ((derived-mode-p 'pdf-view-mode) 'pdf-tools)
                               ((derived-mode-p 'emureader-mode) 'emureader)
                               ((derived-mode-p 'image-mode) 'emacs)
                               (t 'file))))))
    (pcase choice
      (`(viewer ,viewer) (anthe-open-with--integrated viewer file))
      (`(desktop ,id) (make-process :name id :noquery t :command (list "gtk-launch" id file))))
    ;; Switched: the buffer it was shown in closes, unless it was chosen again
    (when (and current (buffer-live-p old)
               (not (equal choice (list 'viewer current)))
               (not (buffer-modified-p old)))
      (kill-buffer old))))

(map! :leader :desc "Open with another program" "k o w" #'anthe-open-with)

;;; In EXWM

(defun anthe-viewers--rename ()
  "Name zathura's, nsxiv's and mpv's buffers after their file."
  (when (stringp exwm-title)
    (pcase exwm-class-name
      ("Zathura"
       ;; "NAME [PAGE/PAGES]"; "zathura" before a document is open
       (when (string-match "\\`\\(.+?\\)\\(?: \\[\\([0-9]+\\)/[0-9]+\\]\\)?\\'" exwm-title)
         (setq anthe-zathura-page (match-string 2 exwm-title))
         (unless (equal exwm-title "zathura")
           (exwm-workspace-rename-buffer (concat "PDF: " (match-string 1 exwm-title))))))
      ("Nsxiv"
       ;; rcfiles/nsxiv/exec/win-title: "NAME" or "NAME [N/FILES]"
       (unless (equal exwm-title "nsxiv")
         (exwm-workspace-rename-buffer (concat "Image: " exwm-title))))
      ("mpv"
       ;; --title=${filename}; "mpv" before
       (unless (equal exwm-title "mpv")
         (exwm-workspace-rename-buffer (concat "Video: " exwm-title)))))))

(defun anthe-viewers--before-exwm-evil ()
  "Put the viewers' keys before exwm-evil's, which has C-j and C-k too: the
first mode in `minor-mode-map-alist' wins, and exwm-evil, loaded later, came
first."
  (dolist (mode '(anthe-mpv-mode anthe-nsxiv-mode anthe-zathura-mode))
    (when-let* ((entry (assq mode minor-mode-map-alist)))
      (setq minor-mode-map-alist (cons entry (delq entry minor-mode-map-alist))))))

(defun anthe-viewers--setup ()
  "Turn on the keys of zathura's, nsxiv's or mpv's buffer, and show it where it was
opened from."
  (pcase exwm-class-name
    ("Zathura" (anthe-zathura-mode 1))
    ("Nsxiv" (anthe-nsxiv-mode 1))
    ("mpv" (anthe-mpv-mode 1)))
  (when (or anthe-zathura-mode anthe-nsxiv-mode anthe-mpv-mode)
    (anthe-viewers--before-exwm-evil)
    (anthe-viewers--rename)
    (evil-normalize-keymaps)
    (setq anthe-viewers-file (anthe-viewers--process-file))
    (when-let* ((pending (assoc anthe-viewers-file anthe-viewers--pending)))
      (setq anthe-viewers--pending (delq pending anthe-viewers--pending))
      ;; Once EXWM has shown it, should it be elsewhere
      (run-at-time 0 nil #'anthe-viewers--show (current-buffer) (nth 1 pending)))))

(declare-function exwm-manage-get-pid "exwm-manage")
(declare-function exwm--id->buffer "exwm-core")

(define-advice exwm-floating--unset-floating (:around (fn id) anthe-viewers)
  "Show a viewer opened from Emacs in the window it was opened from right away,
rather than in the one selected when it appears."
  (let* ((pid (ignore-errors (exwm-manage-get-pid id)))
         (pending (and pid (seq-find (lambda (pending) (eql (nth 2 pending) pid))
                                     anthe-viewers--pending)))
         (window (nth 1 pending)))
    (if (and (window-live-p window)
             (eq (window-frame window) (buffer-local-value 'exwm--frame (exwm--id->buffer id))))
        (with-selected-window window
          (funcall fn id))
      (funcall fn id))))

(with-eval-after-load 'exwm
  ;; After exwm-desktop.el's, which name buffers after the class, and turn on exwm-evil
  (add-hook 'exwm-update-class-hook #'anthe-viewers--rename 90)
  (add-hook 'exwm-update-title-hook #'anthe-viewers--rename 90)
  (add-hook 'exwm-manage-finish-hook #'anthe-viewers--setup 90))

;;; citar-open previews the first PDF of the reference, in pdf-view

(defvar anthe-viewers--citar-timer nil)

(defvar anthe-viewers--citar-preview nil
  "The window previewed in, the buffer it showed, and the buffers the preview
opened: (WINDOW BUFFER . OPENED).")

(defun anthe-viewers--citar-preview ()
  "Preview the first PDF of the reference selected, if it has one."
  (when-let* (((minibufferp))
              (window (car anthe-viewers--citar-preview))
              ((window-live-p window))
              (candidate (if (bound-and-true-p vertico--input)
                             (vertico--candidate)
                           (car (completion-all-sorted-completions))))
              (key (ignore-errors (citar--extract-candidate-citekey candidate))))
    (let ((pdf (seq-find (lambda (file) (string-suffix-p ".pdf" file t))
                         (gethash key (citar-get-files key)))))
      (if (not (and pdf (file-exists-p pdf)))
          (set-window-buffer window (cadr anthe-viewers--citar-preview))
        (let ((buffer (or (get-file-buffer pdf)
                          ;; In pdf-view, the minibuffer being active (anthe-pdf.el)
                          (car (push (find-file-noselect pdf)
                                     (cddr anthe-viewers--citar-preview))))))
          (set-window-buffer window buffer))))))

(defun anthe-viewers--citar-schedule ()
  "Preview the reference selected a moment after the last key, as consult."
  (when (timerp anthe-viewers--citar-timer)
    (cancel-timer anthe-viewers--citar-timer))
  (let ((minibuffer (current-buffer)))
    (setq anthe-viewers--citar-timer
          (run-with-idle-timer 0.2 nil
                               (lambda ()
                                 (when (buffer-live-p minibuffer)
                                   (with-current-buffer minibuffer
                                     (anthe-viewers--citar-preview))))))))

(defun anthe-viewers--citar-end ()
  "Show the window's buffer again, and close the PDFs the preview opened, so
that the one chosen opens anew, in zathura."
  (when (timerp anthe-viewers--citar-timer)
    (cancel-timer anthe-viewers--citar-timer))
  (pcase-let ((`(,window ,buffer . ,opened) anthe-viewers--citar-preview))
    (when (and (window-live-p window) (buffer-live-p buffer))
      (set-window-buffer window buffer))
    (mapc #'kill-buffer (seq-filter #'buffer-live-p opened)))
  (setq anthe-viewers--citar-preview nil))

(define-advice citar-select-refs (:around (fn &rest args) anthe-preview)
  "Preview the PDFs when citar-open asks for the references."
  (if (memq this-command '(citar-open citar-open-files))
      (let ((window (selected-window)))
        (minibuffer-with-setup-hook
            (lambda ()
              (setq anthe-viewers--citar-preview (list window (window-buffer window)))
              (add-hook 'post-command-hook #'anthe-viewers--citar-schedule nil t)
              (add-hook 'minibuffer-exit-hook #'anthe-viewers--citar-end nil t))
          (apply fn args)))
    (apply fn args)))

(provide 'anthe-viewers)
;;; anthe-viewers.el ends here
