;;; anthe-dashboard.el --- The dashboard -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Created: May 17, 2026
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;; emacs-dashboard gives the buffer, its mode and the startup; this draws
;; everything in it (`anthe-dashboard-insert'), as cards with round corners:
;; - the header: the planet, a greeting, and a status strip (the next event,
;;   tasks due, unread mail, Syncthing, Claude's limits);
;; - the week and the tasks, side by side when the window is wide enough;
;; - the Cryolist and research news, side by side;
;; - a footer: a quote and the keys.
;; Text is in Ubuntu Sans, the week's grid in the fixed font.  Columns are
;; display spaces aligned from the centre of the window, so the variable
;; pitch keeps them aligned; text is wrapped and cut by its pixel width.
;;
;; Keys: `c' the calendar, `t' the tasks, `m' the Cryolist (mailing list),
;; `r' research news; `C-j'/`C-k' the next or previous item (an event, a
;; task, an article), on to the next card.  RET on a heading opens what the
;; card shows, on an item the item.  TAB on a list shows all of it or cuts
;; it again.  On the week `]'/`[' the next and previous week, `.' this one;
;; on the tasks `p' cycles all, work, personal (`anthe-dashboard-task-contexts'),
;; `,' sets the priority (`+'/`-' up and down), `s' schedules, `D' sets the
;; deadline, `T' the state; `d' the agenda, `w' the PhD agenda.
;;
;;; Code:

(require 'cl-lib)
(require 'seq)
(require 'text-property-search)
(require 'anthe-week)

(use-package dashboard
  :ensure t
  :config
  (dashboard-setup-startup-hook))

(setq dashboard-display-icons-p t
      dashboard-icon-type 'nerd-icons
      dashboard-center-content nil
      dashboard-vertically-center-content t
      dashboard-show-shortcuts nil
      dashboard-items nil
      dashboard-startupify-list '(anthe-dashboard-insert))

;;; Layout

(defvar anthe-dashboard-max-width 240
  "The widest the dashboard is, in columns.")

(defvar anthe-dashboard-two-columns-width 200
  "From this width, in columns, the week and the tasks are side by side.")

(defvar anthe-dashboard-gap 3
  "Columns between two cards side by side.")

(defvar anthe-dashboard-list-height 8
  "The lines of a list (the tasks, the digest), until TAB shows all.")

(defvar anthe-dashboard-font "Ubuntu Sans"
  "The font of the dashboard's text; the week's grid keeps the fixed one.")

(defvar anthe-dashboard-banner (expand-file-name "~/documents/pictures/logo-ascii.txt")
  "The picture of the header, in characters.")

(defvar anthe-dashboard--half 0
  "Half the dashboard's width, in columns, while drawing.")

(defvar anthe-dashboard--origin 0
  "The column of the card's text being drawn, from the dashboard's left.")

(defvar anthe-dashboard--expanded nil
  "The lists shown in full.")

(defun anthe-dashboard--at (column &optional face)
  "A space reaching COLUMN of the card being drawn, in FACE."
  (propertize " " 'face face
              'display `(space :align-to (+ (- center ,anthe-dashboard--half)
                                            ,(+ anthe-dashboard--origin column)))))

(defun anthe-dashboard--px (string) (string-pixel-width string))

(defun anthe-dashboard--columns (string)
  "The columns STRING takes, rounded up."
  (ceiling (anthe-dashboard--px string) (float (frame-char-width))))

(defun anthe-dashboard--truncate (string columns)
  "STRING cut with an ellipsis to fit COLUMNS."
  (let ((px (* columns (frame-char-width))))
    (if (<= (anthe-dashboard--px string) px)
        string
      (let ((low 0) (high (length string)))
        (while (< low high)
          (let ((mid (/ (+ low high 1) 2)))
            (if (<= (anthe-dashboard--px (concat (substring string 0 mid) "…")) px)
                (setq low mid)
              (setq high (1- mid)))))
        (concat (substring string 0 low) (propertize "…" 'face (get-text-property 0 'face string)))))))

(defun anthe-dashboard--face (&rest faces)
  "FACES in the dashboard's font."
  `((:family ,anthe-dashboard-font) ,@faces))

(defun anthe-dashboard--fg (face)
  "FACE's foreground only, not its height or weight."
  `(:foreground ,(face-foreground face nil 'default)))

(defun anthe-dashboard--blend (alpha)
  (anthe-week--blend (face-foreground 'default nil t) alpha))

(defun anthe-dashboard--text (string &rest faces)
  "STRING in FACES and the dashboard's font, without its own properties (an
Org heading's prefixes)."
  (propertize (substring-no-properties string) 'face (apply #'anthe-dashboard--face faces)))

;;; Actions, items, headings

(defun anthe-dashboard-act (&optional event)
  "Do what the thing at point (or clicked) does: its `anthe-dashboard-action'."
  (interactive (list last-nonmenu-event))
  (when (mouse-event-p event) (posn-set-point (event-start event)))
  (if-let* ((action (get-text-property (point) 'anthe-dashboard-action)))
      (funcall action)
    (user-error "Nothing to open here")))

(defun anthe-dashboard--action (string action &optional help)
  "STRING doing ACTION on RET or a click, HELP on hover."
  (propertize string 'anthe-dashboard-action action 'mouse-face 'highlight 'help-echo help))

(defun anthe-dashboard--button (string action &optional help)
  "STRING doing ACTION on RET or a click, and a button, for link-hint (SPC s l)."
  (propertize (anthe-dashboard--action string action help)
              'button t 'category 'default-button 'follow-link t
              'action (lambda (_) (funcall action))))

(defun anthe-dashboard--item (string)
  "STRING as an item, for C-j and C-k."
  (propertize string 'anthe-dashboard-item (list 'item)))

(defun anthe-dashboard--heading (width icon title &optional subtitle hint action)
  "A card's heading, WIDTH columns: ICON (a nerd-icons octicon name), TITLE,
SUBTITLE dimmed, HINT (its keys) at the right; RET on it ACTION."
  (let* ((left (concat (if (fboundp 'nerd-icons-octicon)
                           (concat (nerd-icons-octicon icon :face 'dashboard-heading) "  ")
                         "")
                       (anthe-dashboard--text title 'dashboard-heading '(:weight bold))
                       (if subtitle (anthe-dashboard--text (concat "   " subtitle) 'shadow) "")))
         (hint (if hint (anthe-dashboard--text hint 'shadow '(:slant italic)) ""))
         (line (concat (if action (anthe-dashboard--action left action "RET: open") left)
                       (anthe-dashboard--at (- width (anthe-dashboard--columns hint)))
                       hint)))
    (propertize line 'anthe-dashboard-heading t)))

(defun anthe-dashboard--fit (lines name)
  "LINES cut to `anthe-dashboard-list-height' unless NAME is expanded, with
how many more."
  (let ((height anthe-dashboard-list-height)
        (more (lambda (text) (anthe-dashboard--text text 'shadow '(:slant italic)))))
    (cond ((null lines) (list (funcall more "Nothing here")))
          ((<= (length lines) height) lines)
          ((memq name anthe-dashboard--expanded)
           (append lines (list (funcall more "TAB: less"))))
          (t (append (seq-take lines (1- height))
                     (list (funcall more (format "+ %d more · TAB" (- (length lines) height -1)))))))))

(defun anthe-dashboard--wrap (number segments width)
  "NUMBER then SEGMENTS (strings with their faces), in lines of WIDTH
columns, the lines after the first aligned after NUMBER."
  (let* ((indent (1+ (anthe-dashboard--columns number)))
         (px (* (- width indent) (frame-char-width)))
         (words (mapcan (lambda (segment)
                          (let ((props (text-properties-at 0 segment)))
                            (mapcar (lambda (word) (apply #'propertize word props))
                                    (split-string segment " " t))))
                        segments))
         lines line)
    (dolist (word words)
      (let ((next (if line (concat line " " word) word)))
        (if (or (null line) (<= (anthe-dashboard--px next) px))
            (setq line next)
          (push line lines)
          (setq line word))))
    (when line (push line lines))
    (setq lines (nreverse lines))
    (cons (concat number (anthe-dashboard--at indent) (car lines))
          (mapcar (lambda (l) (concat (anthe-dashboard--at indent) l)) (cdr lines)))))

(defun anthe-dashboard--numbered (entries width action)
  "Lines of ENTRIES, each a list of segments, numbered and wrapped to WIDTH;
RET on a number (an item, and a button) does (ACTION INDEX)."
  (let ((n 0))
    (mapcan (lambda (segments)
              (let* ((i n)
                     (number (anthe-dashboard--text (format "%d." (setq n (1+ n)))
                                                    (anthe-dashboard--fg 'org-list-dt) '(:weight bold)))
                     (number (anthe-dashboard--item
                              (anthe-dashboard--button number (lambda () (funcall action i)) "RET: open"))))
                (anthe-dashboard--wrap number segments width)))
            entries)))

;;; Cards

(defun anthe-dashboard--card (name column width lines)
  "The lines of the card NAME at COLUMN, WIDTH columns wide, around LINES
\(each made by a function of nothing, `anthe-dashboard--origin' set)."
  (let* ((border `(:foreground ,(anthe-dashboard--blend 0.2)))
         (background `(:background ,(anthe-dashboard--blend 0.025)))
         (rule (lambda (left right)
                 (let ((anthe-dashboard--origin column))
                   (concat (anthe-dashboard--at 0)
                           (propertize (concat left (make-string (- width 2) ?─) right) 'face border))))))
    (mapcar
     (lambda (line) (anthe-dashboard--mark name line))
     (append
      (list (funcall rule "╭" "╮"))
      (mapcar (lambda (line)
                (let* ((anthe-dashboard--origin column)
                       (text (copy-sequence (or line ""))))
                  (add-face-text-property 0 (length text) background t text)
                  (concat (anthe-dashboard--at 0)
                          (propertize "│" 'face border)
                          (propertize " " 'face background)
                          text
                          (anthe-dashboard--at (- width 1) background)
                          (propertize "│" 'face border))))
              lines)
      (list (funcall rule "╰" "╯"))))))

(defun anthe-dashboard--row (&rest cards)
  "The lines of CARDS side by side, each (NAME COLUMN WIDTH LINES-FUNCTION),
LINES-FUNCTION giving the lines of its text, `anthe-dashboard--origin' set
to its column, then made as high as the highest."
  (let* ((texts (mapcar (pcase-lambda (`(,_ ,column ,_ ,fn))
                          (let ((anthe-dashboard--origin (+ column 2))) (funcall fn)))
                        cards))
         (height (apply #'max (mapcar #'length texts)))
         (framed (cl-mapcar (pcase-lambda (`(,name ,column ,width ,_) text)
                              (anthe-dashboard--card
                               name column width
                               (append text (make-list (- height (length text)) ""))))
                            cards texts)))
    (apply #'cl-mapcar #'concat framed)))

;;; Sections' keys

(defvar anthe-dashboard-card-map
  (define-keymap "RET" #'anthe-dashboard-act "<return>" #'anthe-dashboard-act
    "<mouse-1>" #'anthe-dashboard-act
    "TAB" #'anthe-dashboard-toggle-list "<tab>" #'anthe-dashboard-toggle-list
    "C-j" #'anthe-dashboard-next-item "C-k" #'anthe-dashboard-previous-item)
  "Keys on every card, under its own (`anthe-dashboard--card-keys').")

(defvar anthe-dashboard--card-keys
  `((week . ,(define-keymap "[" #'anthe-dashboard-previous-week "]" #'anthe-dashboard-next-week
               "." #'anthe-dashboard-this-week))
    (tasks . ,(define-keymap "d" (lambda () (interactive) (org-agenda nil "d"))
                "w" (lambda () (interactive) (org-agenda nil "w"))
                "p" #'anthe-dashboard-cycle-context
                "," #'anthe-dashboard-task-priority
                "+" #'anthe-dashboard-task-priority-up
                "-" #'anthe-dashboard-task-priority-down
                "s" #'anthe-dashboard-task-schedule
                "D" #'anthe-dashboard-task-deadline
                "T" #'anthe-dashboard-task-state))
    (news . ,(define-keymap "l" #'anthe-dashboard-article-later
               "a" #'anthe-dashboard-article-add
               "R" #'anthe-dashboard-article-read
               "x" #'anthe-dashboard-article-skip
               "n" #'anthe-dashboard-article-note
               "o" #'anthe-dashboard-article-entry)))
  "The keys of each card, by its name.")

(defun anthe-dashboard--mark (name string)
  "STRING as part of the card NAME, with its keys under those already there
\(an event's, a slot's, a button's)."
  (let ((map (make-composed-keymap (alist-get name anthe-dashboard--card-keys)
                                   anthe-dashboard-card-map))
        (pos 0)
        (end (length string)))
    (put-text-property 0 end 'anthe-dashboard-card name string)
    (while (< pos end)
      (let ((next (next-single-property-change pos 'keymap string end))
            (own (get-text-property pos 'keymap string)))
        (put-text-property pos next 'keymap (if own (make-composed-keymap own map) map) string)
        (setq pos next)))
    string))

;;; The header: the planet, a greeting, the status strip

(defvar anthe-dashboard--status (make-hash-table)
  "What the status strip shows from programs, by name: (TIME . VALUE).")

(defun anthe-dashboard--fetch (name command interval parse)
  "Run COMMAND (a shell command) in the background as NAME, if its last run
is older than INTERVAL seconds; keep (PARSE its output) and draw again if it
changed."
  (let ((last (gethash name anthe-dashboard--status))
        (process-name (format "dashboard-%s" name)))
    (when (and (not (get-process process-name))
               (or (null last) (> (float-time (time-since (car last))) interval)))
      (puthash name (cons (current-time) (cdr last)) anthe-dashboard--status)
      (let ((output (generate-new-buffer (format " *%s*" process-name))))
        (make-process
         :name process-name :buffer output :noquery t
         :command (list "sh" "-c" command)
         :sentinel
         (lambda (process _)
           (when (memq (process-status process) '(exit signal))
             (unwind-protect
                 (when (zerop (process-exit-status process))
                   (let ((value (ignore-errors
                                  (with-current-buffer output
                                    (goto-char (point-min))
                                    (funcall parse)))))
                     (unless (equal value (cdr (gethash name anthe-dashboard--status)))
                       (puthash name (cons (current-time) value) anthe-dashboard--status)
                       (anthe-dashboard-redraw))))
               (kill-buffer output)))))))
    (cdr (gethash name anthe-dashboard--status))))

(defun anthe-dashboard--unread ()
  "The unread mail, as mu4e's Unread bookmark counts it."
  (anthe-dashboard--fetch
   'unread
   (format "mu find %s --fields=i 2>/dev/null | wc -l"
           (shell-quote-argument
            (or (and (boundp 'mu4e-bookmarks)
                     (plist-get (seq-find (lambda (b) (equal (plist-get b :name) "Unread messages"))
                                          mu4e-bookmarks)
                                :query))
                "flag:unread AND NOT flag:trashed")))
   300 (lambda () (string-to-number (buffer-string)))))

(defun anthe-dashboard--syncthing ()
  "The other Syncthing devices, each (NAME . CONNECTED)."
  (anthe-dashboard--fetch
   'syncthing "syncthing cli show connections && syncthing cli config dump-json"
   300 (lambda ()
         (let* ((connections (gethash "connections" (json-parse-buffer)))
                (devices (gethash "devices" (json-parse-buffer))))
           (delq nil (mapcar (lambda (device)
                               (when-let* ((connection (gethash (gethash "deviceID" device) connections)))
                                 (cons (gethash "name" device)
                                       (eq (gethash "connected" connection) t))))
                             devices))))))

(defun anthe-dashboard--next-event ()
  "The next timed event of today or tomorrow, in words."
  (let* ((today (org-today))
         (now (current-time))
         (event (seq-find (lambda (e) (and (not (anthe-week-event-all-day e))
                                           (time-less-p now (anthe-week-event-start e))))
                          (sort (anthe-week--events today (1+ today))
                                :key #'anthe-week-event-start
                                :lessp #'time-less-p))))
    (when event
      (let* ((minutes (round (float-time (time-subtract (anthe-week-event-start event) now)) 60))
             (when (cond ((< minutes 60) (format "in %d min" minutes))
                         ((= (anthe-week-event-first event) today)
                          (format "in %d h %02d" (/ minutes 60) (% minutes 60)))
                         (t "tomorrow"))))
        (concat (format-time-string "%H:%M " (anthe-week-event-start event))
                (anthe-week-event-title event)
                (anthe-dashboard--text (concat "  " when) (if (< minutes 30) 'warning 'shadow)))))))

(defun anthe-dashboard--greeting ()
  (let ((hour (decoded-time-hour (decode-time))))
    (format "%s, anthe"
            (cond ((< hour 5) "Good night") ((< hour 12) "Good morning")
                  ((< hour 18) "Good afternoon") (t "Good evening")))))

(defun anthe-dashboard--status-line (icon text &optional face)
  (concat (if (fboundp 'nerd-icons-octicon)
              (concat (nerd-icons-octicon icon :face (or face 'shadow)) "  ")
            "")
          (anthe-dashboard--text text)))

(defun anthe-dashboard--header (width tasks)
  "The header's lines, WIDTH columns: the planet, then the greeting and the
status, TASKS giving those due."
  (let* ((banner (if (file-readable-p anthe-dashboard-banner)
                     (split-string (with-temp-buffer (insert-file-contents anthe-dashboard-banner)
                                                     (buffer-string))
                                   "\n" t)
                   nil))
         (banner-width (apply #'max 0 (mapcar #'string-width banner)))
         (column (+ banner-width 6))
         (due (seq-filter (lambda (task) (let ((d (plist-get task :deadline))) (and d (<= d 7)))) tasks))
         (late (seq-count (lambda (task) (< (plist-get task :deadline) 0)) due))
         (unread (anthe-dashboard--unread))
         (devices (anthe-dashboard--syncthing))
         (limits (and (fboundp 'anthe/claude-limits-string) (anthe/claude-limits-string)))
         (next (anthe-dashboard--next-event))
         (right
          (delq nil
                (list
                 (anthe-dashboard--text (anthe-dashboard--greeting) 'dashboard-heading '(:weight bold))
                 (anthe-dashboard--text (format-time-string "%A %-d %B · week %V") 'shadow)
                 ""
                 (anthe-dashboard--status-line "nf-oct-clock" (or next "Nothing more today"))
                 (anthe-dashboard--status-line
                  "nf-oct-checklist"
                  (concat (format "%d due this week" (length due))
                          (if (> late 0) (anthe-dashboard--text (format " · %d late" late) 'error) ""))
                  (if (> late 0) 'error 'shadow))
                 (anthe-dashboard--status-line
                  "nf-oct-mail" (if unread (format "%d unread" unread) "…")
                  (if (and unread (> unread 0)) 'warning 'shadow))
                 (anthe-dashboard--status-line
                  "nf-oct-sync"
                  (concat (if devices
                              (mapconcat (pcase-lambda (`(,name . ,connected))
                                           (concat name (if connected
                                                            (anthe-dashboard--text " ✓" 'success)
                                                          (anthe-dashboard--text " ✗" 'error))))
                                         devices "   ")
                            "Syncthing …")
                          (if limits (concat (anthe-dashboard--text "      Claude  " 'shadow) limits) "")))))))
    (cl-loop for i below (max (length banner) (length right))
             collect (concat (propertize (or (nth i banner) "") 'face (anthe-dashboard--fg 'org-level-2))
                             (if (nth i right) (concat (anthe-dashboard--at column) (nth i right)) "")))))

;;; The week

(defvar anthe-dashboard--week-offset 0
  "The week shown, in weeks from this one.")

(defun anthe-dashboard--week-monday ()
  (+ (anthe-week--monday (org-today)) (* 7 anthe-dashboard--week-offset)))

(defun anthe-dashboard-next-week (&optional count)
  "Show the next week, or COUNT later, on the dashboard."
  (interactive "p")
  (setq anthe-dashboard--week-offset (+ anthe-dashboard--week-offset (or count 1)))
  (anthe-dashboard-redraw))

(defun anthe-dashboard-previous-week (&optional count)
  "Show the previous week, or COUNT earlier, on the dashboard."
  (interactive "p")
  (anthe-dashboard-next-week (- (or count 1))))

(defun anthe-dashboard-this-week ()
  "Show this week on the dashboard."
  (interactive)
  (setq anthe-dashboard--week-offset 0)
  (anthe-dashboard-redraw))

(defun anthe-dashboard--grid-width (width)
  "The widest week, its gutter and 7 columns, in WIDTH columns, as
`anthe-week--insert' lays it out."
  (+ 7 (* 7 (1+ (max 8 (1- (/ (- width 7) 7)))))))

(defun anthe-dashboard--week (width)
  "The week's lines, WIDTH columns: this week first, compact.  Its events
are items."
  (let* ((monday (anthe-dashboard--week-monday))
         (grid (with-temp-buffer
                 (anthe-week--insert monday (anthe-dashboard--grid-width width) t)
                 (split-string (buffer-substring (point-min) (1- (point-max))) "\n"))))
    (dolist (line grid)
      (let ((pos 0))
        (while (< pos (length line))
          (let ((next (next-single-property-change pos 'anthe-week-event line (length line))))
            (when-let* ((event (get-text-property pos 'anthe-week-event line)))
              (put-text-property pos next 'anthe-dashboard-item event line))
            (setq pos next)))))
    (append
     (list (anthe-dashboard--heading
            width "nf-oct-calendar"
            (format "Week %s" (anthe-week--date monday "%V"))
            (concat (anthe-week--date monday "%-d %b") " – " (anthe-week--date (+ 6 monday) "%-d %b")
                    (pcase anthe-dashboard--week-offset
                      (0 "") (1 " · next week") (-1 " · last week")
                      (n (format " · %d weeks %s" (abs n) (if (> n 0) "ahead" "ago")))))
            "[ ]  weeks    .  this week"
            (lambda () (anthe-week monday)))
           "")
     grid)))

;;; The tasks: by deadline, priority and schedule, no calendar events

(defvar anthe-dashboard-task-skipped-states '("HOLD" "WAIT" "IDEA")
  "Waiting, out of the dashboard as of the other views (the Later view has them).")

(defvar anthe-dashboard-task-contexts
  '((work "phd" "work")
    (personal "perso" "finances" "emacs" "piano" "music" "goals" "system" "os"))
  "The contexts `p' cycles the tasks through, after all of them: each a name
and the tags of its tasks (inherited ones too, as a file's #+filetags).")

(defvar anthe-dashboard-task-context nil
  "The context of the tasks shown (see `anthe-dashboard-task-contexts'), nil
for all.")

(defun anthe-dashboard-cycle-context ()
  "Show all the tasks, then each context's in turn (work, personal)."
  (interactive)
  (let ((names (mapcar #'car anthe-dashboard-task-contexts)))
    (setq anthe-dashboard-task-context
          (if anthe-dashboard-task-context
              (cadr (memq anthe-dashboard-task-context names))
            (car names))))
  (anthe-dashboard-redraw)
  (message "Tasks: %s" (or anthe-dashboard-task-context "all")))

(defun anthe-dashboard--in-context-p (tags)
  (or (null anthe-dashboard-task-context)
      (seq-intersection tags (alist-get anthe-dashboard-task-context anthe-dashboard-task-contexts))))

;;; Changing a task from the dashboard

(defun anthe-dashboard--task-command (command)
  "Run COMMAND on the task at point, in its file, save it and draw again."
  (let ((marker (or (get-text-property (point) 'anthe-dashboard-task)
                    (user-error "Not on a task"))))
    (with-current-buffer (marker-buffer marker)
      (org-with-point-at marker
        (call-interactively command))
      (save-buffer))
    (anthe-dashboard-redraw)))

(defun anthe-dashboard-task-priority ()
  "Set the priority of the task at point."
  (interactive)
  (anthe-dashboard--task-command #'org-priority))

(defun anthe-dashboard-task-priority-up ()
  "Raise the priority of the task at point."
  (interactive)
  (anthe-dashboard--task-command #'org-priority-up))

(defun anthe-dashboard-task-priority-down ()
  "Lower the priority of the task at point."
  (interactive)
  (anthe-dashboard--task-command #'org-priority-down))

(defun anthe-dashboard-task-schedule ()
  "Schedule the task at point (C-u removes the schedule)."
  (interactive)
  (anthe-dashboard--task-command #'org-schedule))

(defun anthe-dashboard-task-deadline ()
  "Set the deadline of the task at point (C-u removes it)."
  (interactive)
  (anthe-dashboard--task-command #'org-deadline))

(defun anthe-dashboard-task-state ()
  "Change the state of the task at point (DONE, HOLD...)."
  (interactive)
  (anthe-dashboard--task-command #'org-todo))

(defun anthe-dashboard--task-files ()
  (seq-remove (lambda (file)
                (member (file-name-nondirectory file) '("calendar.org" "Log.org")))
              (org-agenda-files)))

(defun anthe-dashboard--tasks ()
  "The open tasks, the most pressing first: a deadline in its warning
period (its -Nd, else `org-deadline-warning-days') or past, priority A,
scheduled for today or before, priority B, then the rest.  A deadline not
yet in its warning period, or a schedule later, keeps a task out.  Each a plist."
  (let ((today (org-today))
        tasks)
    (dolist (file (anthe-dashboard--task-files))
      (when (file-exists-p file)
        (with-current-buffer (find-file-noselect file)
          (org-with-wide-buffer
           (org-map-entries
            (lambda ()
              (let* ((state (org-get-todo-state))
                     (deadline-stamp (org-entry-get nil "DEADLINE"))
                     (scheduled (org-get-scheduled-time (point)))
                     (d (and deadline-stamp
                             (- (time-to-days (org-time-string-to-time deadline-stamp)) today)))
                     (warning (and d (<= d (org-get-wdays deadline-stamp))))
                     (s (and scheduled (- (time-to-days scheduled) today)))
                     (tags (org-get-tags))
                     (priority (save-excursion
                                 (beginning-of-line)
                                 (when (looking-at org-complex-heading-regexp)
                                   (and (match-beginning 3)
                                        (string-to-char (substring (match-string 3) 2))))))
                     (group (cond (warning 0)
                                  ((eq priority ?A) 1)
                                  ((and s (<= s 0)) 2)
                                  ((eq priority ?B) 3)
                                  (t 4))))
                (unless (or (member state anthe-dashboard-task-skipped-states)
                            (org-entry-is-done-p)
                            (member "habit" tags)
                            (equal (org-entry-get nil "STYLE") "habit")
                            (and d (not warning) (not (and s (<= s 0))))
                            (and s (> s 0) (not warning))
                            (not (anthe-dashboard--in-context-p tags)))
                  (push (list :group group :deadline (and warning d) :scheduled s :priority priority
                              :state state :title (org-link-display-format (org-get-heading t t t t))
                              :category (org-get-category)
                              :marker (point-marker))
                        tasks))))
            "/!")))))
    (sort tasks
          :key (lambda (task)
                 (list (plist-get task :group)
                       (or (plist-get task :deadline) 9999)
                       (or (plist-get task :priority) ?Z)
                       (or (plist-get task :scheduled) 9999))))))

(defun anthe-dashboard--when (task)
  "When TASK is due, in words, coloured as it nears."
  (let ((d (plist-get task :deadline))
        (s (plist-get task :scheduled)))
    (cond ((and d (< d 0)) (anthe-dashboard--text (format "%d d late" (- d)) 'error))
          ((and d (= d 0)) (anthe-dashboard--text "due today" 'error))
          ((and d (= d 1)) (anthe-dashboard--text "due tomorrow" 'warning))
          (d (anthe-dashboard--text (format "due in %d d" d) 'warning))
          ((and s (< s 0)) (anthe-dashboard--text (format "since %d d" (- s)) 'shadow))
          ((and s (= s 0)) (anthe-dashboard--text "today" 'success))
          (t ""))))

(defun anthe-dashboard--task-line (task width)
  "TASK's line, WIDTH columns: its priority, title, when and category in
aligned columns."
  (let* ((priority (plist-get task :priority))
         (category-column (- width 13))
         (when-column (- category-column 14))
         (state (plist-get task :state))
         (marker (plist-get task :marker))
         (title (concat
                 ;; Only a state other than TODO (STRT, LOOP, PROJ...)
                 (if (equal state "TODO") ""
                   (concat (anthe-dashboard--text state (org-get-todo-face state)) " "))
                 (anthe-dashboard--text (plist-get task :title)))))
    (propertize
     (anthe-dashboard--item
      (anthe-dashboard--action
       (concat (if priority
                  (anthe-dashboard--text (format "%c" priority)
                                         (pcase priority (?A 'error) (?B 'warning) (_ 'shadow))
                                         '(:weight bold))
                "")
              (anthe-dashboard--at 3)
              (anthe-dashboard--truncate title (- when-column 4))
              (anthe-dashboard--at when-column)
              (anthe-dashboard--when task)
              (anthe-dashboard--at category-column)
              (anthe-dashboard--truncate
               (anthe-dashboard--text (or (plist-get task :category) "") (anthe-dashboard--fg 'font-lock-doc-face))
               12))
      (lambda ()
        (switch-to-buffer (marker-buffer marker))
        (goto-char marker)
        (org-fold-show-context)
        (org-fold-show-entry))
      "RET: go to the task"))
     'anthe-dashboard-task marker)))

(defun anthe-dashboard--tasks-card (width tasks)
  "The lines of TASKS, WIDTH columns."
  (append
   (list (anthe-dashboard--heading
          width "nf-oct-checklist" "Tasks"
          (if anthe-dashboard-task-context
              (format "%s only" anthe-dashboard-task-context)
            "by deadline, priority, schedule")
          ",  priority    s  schedule    D  deadline    T  state    p  work, personal")
         "")
   (anthe-dashboard--fit (mapcar (lambda (task) (anthe-dashboard--task-line task width)) tasks)
                         'tasks)))

;;; The Cryolist

(defvar anthe-dashboard-cryolist-query "from:cryolist-request AND NOT flag:trashed"
  "The Cryolist's digests, in mu4e.")

(defun anthe-dashboard--cryolist-topics (body)
  "The topics of a Cryolist digest's BODY, each (TITLE . AUTHOR)."
  (when (string-match "Today's Topics:\n\\(\\(?:.\\|\n\\)*?\\)\n-\\{20,\\}" body)
    (mapcar (lambda (topic)
              (let ((topic (string-join (split-string topic nil t) " ")))
                (if (string-match "\\`\\(.*?\\) *(\\([^()]*\\))\\'" topic)
                    (cons (match-string 1 topic) (match-string 2 topic))
                  (cons topic nil))))
            (cdr (split-string (match-string 1 body) "^ *[0-9]+\\. ")))))

(defun anthe-dashboard--cryolist ()
  "The latest Cryolist digest, from mu: a plist of :date, :message-id and
:topics, each (TITLE . AUTHOR)."
  (let ((find (format "mu find %s --sortfield=date --reverse --maxnum=1"
                      (shell-quote-argument anthe-dashboard-cryolist-query))))
    (anthe-dashboard--fetch
     'cryolist
     (format "%s --format=sexp && echo && mu view \"$(%s --fields=l)\"" find find)
     600 (lambda ()
           (let ((message (read (current-buffer))))
             (list :date (plist-get message :date)
                   :message-id (plist-get message :message-id)
                   :topics (anthe-dashboard--cryolist-topics
                            (buffer-substring (point) (point-max)))))))))

(defun anthe-dashboard--days-ago (time)
  (pcase (- (org-today) (time-to-days time))
    (0 "today") (1 "yesterday") (n (format "%d days ago" n))))

(defun anthe-dashboard-open-cryolist (&optional message-id)
  "The Cryolist's digests in mu4e (the bc bookmark), with the latest open,
or the one of MESSAGE-ID."
  (interactive)
  (require 'mu4e)
  (let ((id (or message-id
                (plist-get (cdr (gethash 'cryolist anthe-dashboard--status)) :message-id))))
    (when id
      (letrec ((open (lambda ()
                       (remove-hook 'mu4e-headers-found-hook open)
                       (when (mu4e-headers-goto-message-id id)
                         (mu4e-headers-view-message)))))
        (add-hook 'mu4e-headers-found-hook open)))
    (mu4e-search anthe-dashboard-cryolist-query)))

(defun anthe-dashboard--cryolist-card (width)
  (let* ((digest (anthe-dashboard--cryolist))
         (id (plist-get digest :message-id)))
    (append
     (list (anthe-dashboard--heading
            width "nf-oct-mail" "Cryolist"
            (if digest (anthe-dashboard--days-ago (plist-get digest :date)) "…")
            nil #'anthe-dashboard-open-cryolist)
           "")
     (anthe-dashboard--fit
      (anthe-dashboard--numbered
       (mapcar (pcase-lambda (`(,title . ,author))
                 (delq nil (list (anthe-dashboard--text title)
                                 (and author (anthe-dashboard--text (concat "— " author)
                                                                    (anthe-dashboard--fg 'font-lock-doc-face))))))
               (plist-get digest :topics))
       width (lambda (_) (anthe-dashboard-open-cryolist id)))
      'cryolist))))

;;; Research news: the feed of python-utils' research/feed.py
;; Its new articles (from OpenAlex, scored by my keywords and bibliography)
;; and those to read.  On an article: RET opens its PDF if downloaded, else
;; its page; `l' to read later (its open PDF downloaded to the library's
;; inbox), `a' add to the bibliography, `R' read, `x' skip, `o' its entry in
;; the feed.  The states are the feed's: set on the phone, they act at the
;; next sync (the morning timer, or one of these keys).

(defvar anthe-dashboard-feed (expand-file-name "~/org/roam/digest/feed.org")
  "The research feed, written by python-utils' research/feed.py.")

(defvar anthe-dashboard-python "/home/anthe/software/miniconda3/envs/processing/bin/python3"
  "The Python of python-utils.")

(defun anthe-dashboard--feed-articles ()
  "The feed's articles to show: the new ones by score, then those to read.
Each a plist of the entry's properties, :state, :title and :marker."
  (when (file-exists-p anthe-dashboard-feed)
    (with-current-buffer (find-file-noselect anthe-dashboard-feed)
      (let (articles)
        (org-with-wide-buffer
         (org-map-entries
          (lambda ()
            (let ((state (org-get-todo-state)))
              (when (member state '("NEW" "LATER" "ADD"))
                (push (append (list :state state
                                    :title (org-get-heading t t t t)
                                    :marker (point-marker)
                                    :abstract (string-trim
                                               (buffer-substring-no-properties
                                                (save-excursion (org-end-of-meta-data t) (point))
                                                (save-excursion (org-end-of-subtree t) (point)))))
                              (mapcan (pcase-lambda (`(,key . ,value))
                                        (list (intern (concat ":" (downcase key))) value))
                                      (org-entry-properties nil 'standard)))
                      articles))))))
        (sort articles
              :key (lambda (a)
                     (list (if (equal (plist-get a :state) "NEW") 0 1)
                           (- (string-to-number (or (plist-get a :score) "0"))))))))))

(defvar anthe-dashboard--note-doi nil
  "The DOI whose note to open once the feed's sync has added it.")

(defun anthe-dashboard--note-of (doi)
  "Open the note of DOI, an entry of the library (anthe-bib.el)."
  (anthe-bib--run (list "lookup" doi)
                  (lambda (found)
                    (if-let* ((key (alist-get 'key found)))
                        (run-at-time 0 nil (lambda ()
                                             (anthe/citar-update-bibliography)
                                             (anthe-bib-note key)))
                      (message "%s is not in the library: no note" doi)))))

(defun anthe-dashboard--feed-sync ()
  "Run the feed's sync in the background (LATER downloads, ADD adds), then
read the feed again and draw."
  (when-let* ((buffer (find-buffer-visiting anthe-dashboard-feed)))
    (with-current-buffer buffer (save-buffer)))
  (make-process
   :name "research-feed" :buffer " *research-feed*" :noquery t
   :command (list anthe-dashboard-python "-m" "python_utils.research.feed" "sync")
   :sentinel (lambda (process _)
               (when (memq (process-status process) '(exit signal))
                 (when-let* ((buffer (find-buffer-visiting anthe-dashboard-feed)))
                   (with-current-buffer buffer (revert-buffer t t t)))
                 (when-let* ((doi (prog1 anthe-dashboard--note-doi
                                    (setq anthe-dashboard--note-doi nil))))
                   (anthe-dashboard--note-of doi))
                 (let ((output (with-current-buffer (process-buffer process)
                                 (prog1 (string-trim (buffer-string)) (erase-buffer)))))
                   (unless (string-empty-p output) (message "Research feed: %s" output)))
                 (anthe-dashboard-redraw)))))

(defun anthe-dashboard--article-state (state)
  "Set the article at point to STATE in the feed, sync, draw again."
  (let ((marker (or (get-text-property (point) 'anthe-dashboard-article)
                    (user-error "Not on an article"))))
    (with-current-buffer (marker-buffer marker)
      (org-with-point-at marker (org-todo state))
      (save-buffer))
    (if (member state '("LATER" "ADD"))
        (progn (message "%s: syncing..." state) (anthe-dashboard--feed-sync))
      (anthe-dashboard-redraw))))

(defun anthe-dashboard-article-later ()
  "Read the article at point later: its open PDF to the library's inbox."
  (interactive)
  (anthe-dashboard--article-state "LATER"))

(defun anthe-dashboard-article-add ()
  "Add the article at point to the library, in the feed's topic (a preprint
with the keyword preprint)."
  (interactive)
  (anthe-dashboard--article-state "ADD"))

(defun anthe-dashboard-article-note ()
  "The note of the article at point, in org-roam: added to the library first."
  (interactive)
  (let ((marker (or (get-text-property (point) 'anthe-dashboard-article)
                    (user-error "Not on an article"))))
    (setq anthe-dashboard--note-doi (org-entry-get marker "DOI"))
    (anthe-dashboard--article-state "ADD")))

(defun anthe-dashboard-article-read ()
  "Mark the article at point read."
  (interactive)
  (anthe-dashboard--article-state "READ"))

(defun anthe-dashboard-article-skip ()
  "Skip the article at point."
  (interactive)
  (anthe-dashboard--article-state "SKIP"))

(defun anthe-dashboard-article-entry ()
  "The entry of the article at point, in the feed."
  (interactive)
  (let ((marker (or (get-text-property (point) 'anthe-dashboard-article)
                    (user-error "Not on an article"))))
    (switch-to-buffer (marker-buffer marker))
    (goto-char marker)
    (org-fold-show-entry)))

(defun anthe-dashboard--article-open (article)
  "ARTICLE's PDF if downloaded, else its page."
  (let ((file (and (plist-get article :file)
                   (string-match "\\[\\[file:\\(.*?\\)\\]\\]" (plist-get article :file))
                   (match-string 1 (plist-get article :file)))))
    (if (and file (file-exists-p file))
        (find-file file)
      (browse-url (plist-get article :url)))))

(defun anthe-dashboard--news-card (width)
  (let* ((articles (anthe-dashboard--feed-articles))
         (new (seq-count (lambda (a) (equal (plist-get a :state) "NEW")) articles))
         (later (seq-count (lambda (a) (equal (plist-get a :state) "LATER")) articles))
         (lines (anthe-dashboard--numbered
                 (mapcar (lambda (article)
                           (delq nil
                                 (list (pcase (plist-get article :state)
                                         ("LATER" (anthe-dashboard--text "to read" 'success '(:weight bold)))
                                         ("ADD" (anthe-dashboard--text "adding…" 'warning)))
                                       (pcase (plist-get article :type)
                                         ("preprint" (anthe-dashboard--text "preprint" 'warning '(:slant italic)))
                                         ("dataset" (anthe-dashboard--text "dataset" 'warning '(:slant italic))))
                                       (anthe-dashboard--text (plist-get article :title)
                                                              (anthe-dashboard--fg 'org-level-1))
                                       (and (plist-get article :authors)
                                            (anthe-dashboard--text (concat "— " (plist-get article :authors))
                                                                   (anthe-dashboard--fg 'font-lock-doc-face)))
                                       (and (plist-get article :journal)
                                            (anthe-dashboard--text (plist-get article :journal)
                                                                   (anthe-dashboard--fg 'org-level-2)
                                                                   '(:slant italic))))))
                         articles)
                 width
                 (lambda (i) (anthe-dashboard--article-open (nth i articles))))))
    ;; Each line knows its article, for the keys and the hover
    (let ((i -1))
      (dolist (line lines)
        (when (get-text-property 0 'anthe-dashboard-item line)
          (setq i (1+ i)))
        (when (>= i 0)
          (let ((article (nth i articles)))
            (add-text-properties
             0 (length line)
             (list 'anthe-dashboard-article (plist-get article :marker)
                   'help-echo (concat (plist-get article :title)
                                      (format "\n%s · score %s%s\n\n" (or (plist-get article :journal) "")
                                              (plist-get article :score)
                                              (if (plist-get article :cites_mine)
                                                  (format " · cites %s of mine" (plist-get article :cites_mine))
                                                ""))
                                      (truncate-string-to-width (or (plist-get article :abstract) "") 600 nil nil "…")))
             line)))))
    (append
     (list (anthe-dashboard--heading
            width "nf-oct-book" "Research news"
            (let ((queued (if (fboundp 'anthe-bib--queued) (length (anthe-bib--queued)) 0)))
              ;; With the DOIs queued from the phone or the map, SPC k c q
              (concat (format "%d new · %d to read" new later)
                      (if (> queued 0) (format " · %d queued" queued) "")))
            "l  later   a  add   n  note   R  read   x  skip"
            (lambda () (find-file anthe-dashboard-feed)))
           "")
     (anthe-dashboard--fit lines 'news))))

;;; The footer: a quote and the keys

(defun anthe-dashboard--footer (width)
  (let ((keys (anthe-dashboard--text
               "c  calendar   t  tasks   m  Cryolist   r  news   C-j C-k  items   TAB  more   RET  open"
               'shadow)))
    (concat (anthe-dashboard--text (dashboard-random-footer) 'shadow '(:slant italic))
            (anthe-dashboard--at (- width (anthe-dashboard--columns keys)))
            keys)))

;;; Drawing it all

(defvar-local anthe-dashboard--rendered-width nil)

(defun anthe-dashboard--window-width ()
  (let ((window (get-buffer-window dashboard-buffer-name t)))
    (if window (window-max-chars-per-line window) (frame-width))))

(defun anthe-dashboard-insert ()
  "Draw the dashboard, in rows of cards, centred."
  (let* ((width (min anthe-dashboard-max-width (- (anthe-dashboard--window-width) 4)))
         (anthe-dashboard--half (/ width 2.0))
         (gap anthe-dashboard-gap)
         (tasks (anthe-dashboard--tasks))
         (two (>= width anthe-dashboard-two-columns-width))
         ;; The week a grid wide, the tasks the rest
         (week-width (if two (+ 4 (anthe-dashboard--grid-width (- (floor (* width 0.6)) 4))) width))
         (half (/ (- width gap) 2))
         (rows
          (list
           (anthe-dashboard--row
            (list 'header 0 width (lambda () (anthe-dashboard--header (- width 4) tasks))))
           (if two
               (anthe-dashboard--row
                (list 'week 0 week-width (lambda () (anthe-dashboard--week (- week-width 4))))
                (list 'tasks (+ week-width gap) (- width week-width gap)
                      (lambda () (anthe-dashboard--tasks-card (- width week-width gap 4) tasks))))
             (append
              (anthe-dashboard--row
               (list 'week 0 width (lambda () (anthe-dashboard--week (- width 4)))))
              (anthe-dashboard--row
               (list 'tasks 0 width (lambda () (anthe-dashboard--tasks-card (- width 4) tasks))))))
           (anthe-dashboard--row
            (list 'cryolist 0 half (lambda () (anthe-dashboard--cryolist-card (- half 4))))
            (list 'news (- width half) half (lambda () (anthe-dashboard--news-card (- half 4)))))
           (list (let ((anthe-dashboard--origin 1))
                   (concat (anthe-dashboard--at 0) (anthe-dashboard--footer (- width 2))))))))
    (insert (mapconcat (lambda (row) (string-join row "\n")) rows "\n\n") "\n")))

;;; Moving around

(defvar anthe-dashboard--card-order '(header week tasks cryolist news))

(defun anthe-dashboard-goto-card (name)
  "Go to the heading of the card NAME."
  (let ((pos (point-min)) found)
    (while (and (not found)
                (setq pos (text-property-not-all pos (point-max) 'anthe-dashboard-heading nil)))
      (if (eq (get-text-property pos 'anthe-dashboard-card) name)
          (setq found pos)
        (setq pos (next-single-property-change pos 'anthe-dashboard-heading nil (point-max)))))
    (when found (goto-char found))))

(defun anthe-dashboard--items (name)
  "The positions of the items of the card NAME, an item once, in order."
  (let ((pos (point-min)) seen positions)
    (while (setq pos (next-single-property-change pos 'anthe-dashboard-item))
      (let ((item (get-text-property pos 'anthe-dashboard-item)))
        (when (and item (eq (get-text-property pos 'anthe-dashboard-card) name)
                   (not (memq item seen)))
          (push item seen)
          (push pos positions))))
    (nreverse positions)))

(defun anthe-dashboard-next-item (&optional count)
  "Go to the next item of the card (an event, a task, an article), or COUNT
on, back if negative; past its last, the next card's first."
  (interactive "p")
  (let* ((forward (> (or count 1) 0))
         (card (or (get-text-property (point) 'anthe-dashboard-card) 'header))
         (cards (member card (if forward anthe-dashboard--card-order
                               (reverse anthe-dashboard--card-order))))
         target)
    (dotimes (_ (abs (or count 1)))
      (setq target nil)
      (let ((cards cards))
        (while (and cards (not target))
          (let ((items (anthe-dashboard--items (car cards))))
            (setq target (if (eq (car cards) card)
                             (if forward
                                 (seq-find (lambda (pos) (> pos (point))) items)
                               (seq-find (lambda (pos) (< pos (point))) (reverse items)))
                           (if forward (car items) (car (last items))))))
          (setq cards (cdr cards))))
      (when target (goto-char target)))))

(defun anthe-dashboard-previous-item (&optional count)
  "Go to the previous item, or COUNT back."
  (interactive "p")
  (anthe-dashboard-next-item (- (or count 1))))

(defun anthe-dashboard-toggle-list ()
  "Show the whole list of the card at point, or cut it again."
  (interactive)
  (when-let* ((name (get-text-property (point) 'anthe-dashboard-card))
              ((memq name '(tasks cryolist news))))
    (setq anthe-dashboard--expanded
          (if (memq name anthe-dashboard--expanded)
              (delq name anthe-dashboard--expanded)
            (cons name anthe-dashboard--expanded)))
    (anthe-dashboard-redraw)))

(defun anthe-dashboard--position ()
  "Where the point is: its card, line from the card's top, and place on the line."
  (when-let* ((card (get-text-property (point) 'anthe-dashboard-card)))
    (list card
          (count-lines (text-property-any (point-min) (point-max) 'anthe-dashboard-card card)
                       (line-beginning-position))
          (- (point) (or (text-property-any (line-beginning-position) (line-end-position)
                                            'anthe-dashboard-card card)
                         (line-beginning-position))))))

(defun anthe-dashboard--restore (position)
  (pcase-let ((`(,card ,line ,offset) position))
    (when-let* ((top (text-property-any (point-min) (point-max) 'anthe-dashboard-card card)))
      (goto-char top)
      (forward-line line)
      (let ((start (text-property-any (line-beginning-position) (line-end-position)
                                      'anthe-dashboard-card card)))
        (goto-char (min (+ (or start (line-beginning-position)) offset) (line-end-position)))))))

;;; A dashboard a monitor

;; Each EXWM workspace (a monitor) has its own dashboard, drawn at its width:
;; one buffer shown on the laptop's screen and the wide one took the layout of
;; the last drawn.  The first workspace's is *dashboard*, the others
;; *dashboard: 2*...  `dashboard-buffer-name' says which one is drawn.
(defun anthe-dashboard--buffer-name (&optional frame)
  "The name of the dashboard of FRAME, the selected one by default."
  (let* ((frame (or frame (selected-frame)))
         (frame (or (frame-parent frame) frame))
         (index (and (fboundp 'exwm-workspace--position)
                     (bound-and-true-p exwm-workspace--list)
                     (exwm-workspace--position frame))))
    (if (memq index '(nil 0)) "*dashboard*" (format "*dashboard: %d*" (1+ index)))))

(defun anthe-dashboard--buffers ()
  "The dashboards drawn."
  (seq-filter (lambda (buffer) (eq (buffer-local-value 'major-mode buffer) 'dashboard-mode))
              (buffer-list)))

(defun anthe-dashboard-buffer (&optional frame)
  "The dashboard of FRAME, drawn if it isn't yet."
  (let* ((dashboard-buffer-name (anthe-dashboard--buffer-name frame))
         (buffer (get-buffer dashboard-buffer-name)))
    (if (and buffer (eq (buffer-local-value 'major-mode buffer) 'dashboard-mode))
        buffer
      (let (buffer-list-update-hook)
        (dashboard-insert-startupify-lists t))
      (get-buffer dashboard-buffer-name))))

(defun anthe-dashboard-open ()
  "Show this monitor's dashboard, drawn again."
  (interactive)
  (let ((dashboard-buffer-name (anthe-dashboard--buffer-name)))
    (dashboard-open)))

;; Doom's fallback, where a window goes when its last buffer is killed: this
;; monitor's dashboard
(advice-add 'doom-fallback-buffer :override #'anthe-dashboard-buffer)

(defun anthe-dashboard-redraw ()
  "Draw the dashboards again, the point where it was."
  (interactive)
  (dolist (buffer (anthe-dashboard--buffers))
    (let ((dashboard-buffer-name (buffer-name buffer))
          (window (get-buffer-window buffer t)))
      (if window
          (with-selected-window window
            (let ((position (anthe-dashboard--position)))
              (dashboard-insert-startupify-lists t)
              (when position (anthe-dashboard--restore position))))
        (with-current-buffer buffer
          (dashboard-insert-startupify-lists t))))))

(defun anthe-refresh-dashboard-buffer ()
  "Refresh the dashboard buffer without switching to it."
  (interactive)
  (anthe-dashboard-redraw))

;; evil-collection binds again r, m, p, a and e after each drawing, to the
;; dashboard's own sections, which it no longer has
(with-eval-after-load 'evil-collection-dashboard
  (advice-remove 'dashboard-insert-startupify-lists
                 'evil-collection-dashboard-setup-jump-commands))

(map! :map dashboard-mode-map
      :n "c" (cmd! (anthe-dashboard-goto-card 'week))
      :n "t" (cmd! (anthe-dashboard-goto-card 'tasks))
      :n "m" (cmd! (anthe-dashboard-goto-card 'cryolist))
      :n "r" (cmd! (anthe-dashboard-goto-card 'news))
      :n "C-j" #'anthe-dashboard-next-item
      :n "C-k" #'anthe-dashboard-previous-item
      "C-j" #'anthe-dashboard-next-item
      "C-k" #'anthe-dashboard-previous-item)

;; Drawn again when its window changes width, the cards taking it
(defun anthe-dashboard--redraw-at-width (&rest _)
  (unless (window-minibuffer-p (frame-selected-window))
    (dolist (buffer (anthe-dashboard--buffers))
      (when-let* ((window (get-buffer-window buffer t))
                  ((not (equal (window-max-chars-per-line window)
                               (buffer-local-value 'anthe-dashboard--rendered-width buffer)))))
        (let ((dashboard-buffer-name (buffer-name buffer)))
          (with-selected-window window
            (let ((position (anthe-dashboard--position)))
              (dashboard-insert-startupify-lists t)
              (when position (anthe-dashboard--restore position)))))))))

(add-hook 'dashboard-after-initialize-hook #'anthe-dashboard--redraw-at-width)
(add-hook 'window-size-change-functions #'anthe-dashboard--redraw-at-width)
(add-hook 'dashboard-mode-hook
          (lambda ()
            (setq anthe-dashboard--rendered-width
                  (when-let* ((window (get-buffer-window (current-buffer) t)))
                    (window-max-chars-per-line window)))
            ;; An event's title and time in the echo area, as in the week
            (add-hook 'post-command-hook #'anthe-week--echo-event nil t)
            ;; evil-snipe would take s, T and , from the tasks
            (when (fboundp 'evil-snipe-local-mode) (evil-snipe-local-mode -1))
            (when (fboundp 'evil-snipe-override-local-mode) (evil-snipe-override-local-mode -1))))

;; The calendars synced in the background once Emacs is up (the dashboard
;; shows the events imported last), and the dashboard drawn again if they
;; changed.  It was an agenda built at startup, then hidden: 1.6 s.  What it
;; was for, the agenda's files (custom.el's old list replaces those
;; anthe-workflow.el reads from roam, as org loads) are read again before the
;; dashboard first shows
(add-hook 'after-init-hook
          (lambda ()
            (when (fboundp 'anthe-org-roam-refresh-agenda-list)
              (anthe-org-roam-refresh-agenda-list))))

(defvar anthe-dashboard-sync-delay 3
  "Seconds after startup to sync the calendars.")

(defun anthe-dashboard--sync-calendars ()
  (let* ((file (expand-file-name "~/org/calendar.org"))
         (before (file-attribute-modification-time (file-attributes file))))
    (anthe-week-sync
     (lambda (_ok)
       (unless (equal before (file-attribute-modification-time (file-attributes file)))
         (anthe-dashboard-redraw))))))

(add-hook 'window-setup-hook
          (lambda () (run-with-timer anthe-dashboard-sync-delay nil #'anthe-dashboard--sync-calendars)))

(setq initial-buffer-choice #'anthe-dashboard-open)
(setq doom-fallback-buffer-name "*dashboard*")

;; q (`quit-window') in a buffer alone in its workspace, ibuffer's or mu4e's,
;; left it in place: Doom finds no other buffer to show there.  The dashboard
;; then, as when killing the last buffer: only for q itself, in the window
;; quit, not when a package quits some window of its own
(defun anthe-dashboard--quit-window-a (fn &optional kill window)
  "Show the dashboard when FN leaves the window on the buffer it quit."
  (let* ((window (window-normalize-window window t))
         (buffer (window-buffer window))
         (asked (and (or (called-interactively-p 'any) (eq this-command 'quit-window))
                     (eq window (selected-window)))))
    (funcall fn kill window)
    (when (and asked
               (window-live-p window)
               (eq (window-buffer window) buffer)
               (not (eq (buffer-local-value 'major-mode buffer) 'dashboard-mode)))
      (with-selected-window window
        (anthe-dashboard-open)))))

(advice-add 'quit-window :around #'anthe-dashboard--quit-window-a)

(map! :leader
      (:prefix ("k d" . "dashboard")
       :desc "Draw the dashboard again" "r" #'anthe-dashboard-redraw
       :desc "Open dashboard" "o" #'anthe-dashboard-open))

(provide 'anthe-dashboard)
;;; anthe-dashboard.el ends here
