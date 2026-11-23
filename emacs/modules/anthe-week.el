;;; anthe-week.el --- A week of calendar events, as in a calendar app -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  The calendar events of a week (khalel's import, ~/org/calendar.org) laid
;;  out as in a calendar app: a column a day, the hours down the side, each
;;  event a block from its start to its end, those at the same time side by
;;  side, and the all-day ones on top.  A line marks the time now.
;;
;;  `anthe-week' shows it in its own buffer (SPC o a w): ] and [ the next
;;  and previous week, . this week, RET (or a click) on an event opens it,
;;  g reads the calendar again, S syncs it with the server first.
;;  + or a click on an empty time adds an event there (khalel's capture).
;;  s or / searches an event, the week showing as it's chosen.
;;
;;  Each event is notified (dunst) as its reminders say, read from the .ics
;;  files as khalel doesn't import them; a default for those without.
;;  The dashboard shows it too, compact: this week, or the next one at the
;;  weekend.
;;
;;  The colours: `anthe-week-calendar-colours', a colour per calendar.
;;
;;; Code:

(require 'org)
(require 'color)
(require 'cl-lib)
(require 'filenotify)

(defvar anthe-week-files '("~/org/calendar.org")
  "Org files with the events as khalel imports them: a heading an event,
with a \"- When: <start>--<end>\" line.")

(defvar anthe-week-hours '(8 . 19)
  "The hours always shown, from the first to the last; more if an event is
earlier or later.")

(defvar anthe-week-calendar-colours '(("infomaniak" . blue) ("outlook" . orange))
  "The colour of each calendar's events: a Doom theme colour like `blue', or
a colour like \"#82aaff\".  Other calendars take `violet'.")

(cl-defstruct (anthe-week-event (:constructor anthe-week-event-create)
                                (:copier nil))
  title calendar location description organizer id file pos start end all-day
  ;; In the bars on top: all-day, or lasting a day or more
  banner
  ;; The reminders, minutes before the start
  alarms
  ;; Absolute days, the first and the last; minutes from midnight
  first last from to
  ;; Rows in the grid, and the place among the events at the same time
  row-start row-end lane lanes)

;;; The events

(defvar anthe-week--cache nil
  "(MODIFICATION-TIMES . EVENTS) of `anthe-week-files' at the last read.")

(defun anthe-week--read-file (file &optional alarms)
  "The events in FILE; their reminders from ALARMS, a table from their ID."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (let (events)
      (while (re-search-forward "^\\* +\\(.*?\\)\\(?:[ \t]+:[[:alnum:]_@#%:]+:\\)?[ \t]*$" nil t)
        (let* ((title (match-string-no-properties 1))
               (pos (match-beginning 0))
               (end (save-excursion
                      (if (re-search-forward "^\\* " nil t) (match-beginning 0) (point-max))))
               (field (lambda (regexp)
                        (save-excursion
                          (when (re-search-forward regexp end t)
                            (string-trim (match-string-no-properties 1))))))
               (when (funcall field "^- When: \\(.*\\)$"))
               (id (funcall field "^:ID: *\\(.*\\)$")))
          (when (and when (string-match "<\\([^>]+\\)>\\(?:--<\\([^>]+\\)>\\)?" when))
            (let* ((from (match-string 1 when))
                   (to (or (match-string 2 when) from))
                   (start (org-time-string-to-time from))
                   (stop (org-time-string-to-time to))
                   (all-day (not (string-match-p "[0-9]:[0-9]" from)))
                   (minutes (lambda (time)
                              (let ((decoded (decode-time time)))
                                (+ (* 60 (decoded-time-hour decoded)) (decoded-time-minute decoded))))))
              (push (anthe-week-event-create
                     :title title :file file :pos pos :start start :end stop :all-day all-day
                     :banner (or all-day (>= (float-time (time-subtract stop start)) 86400))
                     :calendar (funcall field "^:CALENDAR: *\\(.*\\)$")
                     :location (let ((where (funcall field "^- Where: *\\(.*\\)$")))
                                 (unless (equal where "") where))
                     :description (let ((text (funcall field "^- Description: *\\(\\(?:.\\|\n\\)*?\\)\n- URL:")))
                                    (unless (equal text "") text))
                     :organizer (let ((who (funcall field "^- Organizer: *\\(.*\\)$")))
                                  (unless (equal who "") who))
                     :id id :alarms (and id alarms (gethash id alarms))
                     :first (time-to-days start) :last (time-to-days stop)
                     :from (funcall minutes start)
                     ;; An event ending another day ends at midnight here, unless
                     ;; it lasts a day or more: a bar, ending at its time
                     :to (if (and (> (time-to-days stop) (time-to-days start))
                                  (< (float-time (time-subtract stop start)) 86400))
                             (* 24 60)
                           (funcall minutes stop)))
                    events)))
          (goto-char end)))
      events)))

;; khalel doesn't import the reminders: they are read from the calendars' .ics
;; files, those khal reads (its config), by the events' UID, khalel's ID
(defvar anthe-week-khal-config "~/.config/khal/config")

(defun anthe-week--calendar-directories ()
  "The directories of khal's calendars."
  (when (file-readable-p anthe-week-khal-config)
    (with-temp-buffer
      (insert-file-contents anthe-week-khal-config)
      (let (directories)
        (while (re-search-forward "^[ \t]*path *= *\\(.+?\\)[ \t]*$" nil t)
          (push (expand-file-name (match-string 1)) directories))
        (seq-filter #'file-directory-p directories)))))

(defun anthe-week--trigger-minutes (trigger)
  "The minutes before the start of a VALARM's TRIGGER, a duration like -PT10M,
or nil (a time, or relative to the end)."
  (when (and (not (string-match-p "RELATED=END\\|VALUE=DATE-TIME" trigger))
             (string-match ":\\([-+]?\\)P\\(?:\\([0-9]+\\)W\\)?\\(?:\\([0-9]+\\)D\\)?\\(?:T\\(?:\\([0-9]+\\)H\\)?\\(?:\\([0-9]+\\)M\\)?\\(?:\\([0-9]+\\)S\\)?\\)?[ \t\r]*\\'"
                           trigger))
    (let ((minutes (+ (* 10080 (string-to-number (or (match-string 2 trigger) "0")))
                      (* 1440 (string-to-number (or (match-string 3 trigger) "0")))
                      (* 60 (string-to-number (or (match-string 4 trigger) "0")))
                      (string-to-number (or (match-string 5 trigger) "0"))
                      (/ (string-to-number (or (match-string 6 trigger) "0")) 60))))
      (if (equal (match-string 1 trigger) "-") minutes (- minutes)))))

(defun anthe-week--alarms ()
  "The reminders of the events in khal's calendars: a table from their UID
to the minutes before their start."
  (let ((alarms (make-hash-table :test #'equal)))
    (dolist (directory (anthe-week--calendar-directories))
      (dolist (file (directory-files directory t "\\.ics\\'"))
        (with-temp-buffer
          (insert-file-contents file)
          ;; The first event's, a repeating event's
          (when (re-search-forward "^UID:\\(.+?\\)\r?$" nil t)
            (let ((uid (match-string 1)) minutes)
              (goto-char (point-min))
              (while (re-search-forward "^BEGIN:VALARM" nil t)
                (let ((end (save-excursion (re-search-forward "^END:VALARM" nil 'move) (point))))
                  (when-let* (((not (save-excursion (re-search-forward "^ACTION:NONE" end t))))
                              ((re-search-forward "^TRIGGER[^\r\n]*" end t))
                              (m (anthe-week--trigger-minutes (match-string 0))))
                    (push m minutes))
                  (goto-char end)))
              (when minutes
                (puthash uid (sort (delete-dups minutes)) alarms)))))))
    alarms))

(defun anthe-week--events (first last)
  "The events from the absolute day FIRST to LAST, read again if a file changed."
  (let* ((files (seq-filter #'file-readable-p (mapcar #'expand-file-name anthe-week-files)))
         (times (mapcar (lambda (f) (file-attribute-modification-time (file-attributes f))) files)))
    (unless (equal (car anthe-week--cache) times)
      (let ((alarms (anthe-week--alarms)))
        (setq anthe-week--cache
              (cons times (mapcan (lambda (file) (anthe-week--read-file file alarms)) files)))))
    (seq-filter (lambda (e) (and (<= (anthe-week-event-first e) last)
                                 (>= (anthe-week-event-last e) first)))
                (cdr anthe-week--cache))))

;;; Colours

(defun anthe-week--colour (name)
  (cond ((stringp name) name)
        ((and (fboundp 'doom-color) (doom-color name)))
        (t (face-foreground 'font-lock-keyword-face nil t))))

(defun anthe-week--blend (colour alpha)
  "COLOUR at ALPHA over the background."
  (let ((background (face-background 'default nil t)))
    (if (or (not (color-defined-p colour)) (not (color-defined-p background)))
        colour
      (apply #'color-rgb-to-hex
             (append (cl-mapcar (lambda (a b) (+ (* alpha a) (* (- 1 alpha) b)))
                                (color-name-to-rgb colour) (color-name-to-rgb background))
                     '(2))))))

(defun anthe-week--calendar-colour (event)
  (anthe-week--colour (or (cdr (assoc (anthe-week-event-calendar event) anthe-week-calendar-colours))
                          'violet)))

;;; Opening an event

(defvar-local anthe-week--view 'week "What the buffer shows: `week' or `month'.")

(defun anthe-week-visit (&optional event)
  "Open the event at point, or of the click EVENT, in its Org file; on a day
of the month without one, show its week."
  (interactive (list last-nonmenu-event))
  (when (mouse-event-p event) (posn-set-point (event-start event)))
  (let ((e (get-text-property (point) 'anthe-week-event))
        (slot (get-text-property (point) 'anthe-week-slot)))
    (cond (e (find-file-other-window (anthe-week-event-file e))
             (goto-char (anthe-week-event-pos e))
             (org-fold-show-entry))
          ((and slot (eq anthe-week--view 'month)) (anthe-week (car slot)))
          (t (user-error "No event here")))))

(defvar anthe-week-event-map
  (define-keymap "RET" #'anthe-week-visit "<return>" #'anthe-week-visit
                 "<mouse-1>" #'anthe-week-visit)
  "The keys on an event, here and on the dashboard.")

;;; Adding an event

(defun anthe-week-add-event (&optional event)
  "Add an event to the calendar with khalel, at the time at point or of the
click EVENT, for an hour (all day from the days or the all-day rows).
The capture buffer has the time, to change; C-c C-c sends it to the server."
  (interactive (list last-nonmenu-event))
  (when (mouse-event-p event) (posn-set-point (event-start event)))
  (pcase-let* ((`(,day . ,minutes) (or (get-text-property (point) 'anthe-week-slot)
                                       (user-error "Not on a day of the calendar")))
               (date (anthe-week--date day "%Y-%m-%d %a"))
               (stamp (if minutes
                          (format "<%s %02d:%02d-%02d:%02d>" date (/ minutes 60) (% minutes 60)
                                  (min 23 (1+ (/ minutes 60))) (% minutes 60))
                        (format "<%s>" date))))
    (require 'khalel)
    (require 'org-capture)
    (let* ((template (or (assoc khalel-capture-key org-capture-templates)
                         (user-error "No khalel capture template")))
           ;; khalel's template asks the time (%^T): it is the one clicked
           (org-capture-templates
            (cons (append (seq-take template 4)
                          (list (string-replace "%^T" stamp (nth 4 template)))
                          (nthcdr 5 template))
                  (remove template org-capture-templates))))
      (org-capture nil khalel-capture-key))))

(defvar anthe-week-slot-map
  (define-keymap "<mouse-1>" #'anthe-week-add-event)
  "The keys on the empty parts of the calendar.")

;;; Laying out a week

(defun anthe-week--monday (day)
  "The Monday of the week of DAY, an absolute day."
  (- day (mod (+ 6 (calendar-day-of-week (calendar-gregorian-from-absolute day))) 7)))

(defun anthe-week--date (day format)
  (format-time-string format (days-to-time (- day (time-to-days 0)))))

(defun anthe-week--lanes (events)
  "Place EVENTS, one day's, side by side where they are at the same time:
set their lane, and the lanes of the events at the same time as them."
  (let (group ends)
    (cl-flet ((close ()
                (dolist (e group) (setf (anthe-week-event-lanes e) (length ends)))
                (setq group nil ends nil)))
      (dolist (e (sort events :key (lambda (e) (list (anthe-week-event-row-start e)
                                                     (- (anthe-week-event-row-end e))))))
        (when (and ends (>= (anthe-week-event-row-start e) (apply #'max ends)))
          (close))
        (let ((lane (seq-position ends (anthe-week-event-row-start e) #'<=)))
          (if lane
              (setf (nth lane ends) (anthe-week-event-row-end e))
            (setq lane (length ends) ends (append ends (list (anthe-week-event-row-end e)))))
          (setf (anthe-week-event-lane e) lane)
          (push e group)))
      (close))))

(defun anthe-week--event-text (event width row today now &optional continued earlier)
  "The ROW of EVENT's block, WIDTH wide: a coloured edge, then the time and
the title, wrapped, then the place.  CONTINUED: only its colour, for the
days after the first of an event in the bars.  EARLIER: a bar begun before
this week, its title without its time."
  (let* ((past (or (< (anthe-week-event-last event) today)
                   (and (= (anthe-week-event-last event) today)
                        (not (anthe-week-event-all-day event))
                        (<= (anthe-week-event-to event) now))))
         (colour (anthe-week--calendar-colour event))
         (background (anthe-week--blend colour (if past 0.12 0.3)))
         (foreground (if past (face-foreground 'shadow nil t) (face-foreground 'default nil t)))
         (lines (if (anthe-week-event-banner event)
                    (list (if (anthe-week-event-all-day event)
                              (anthe-week-event-title event)
                            (concat (format-time-string "%H:%M " (anthe-week-event-start event))
                                    (anthe-week-event-title event))))
                  (append (split-string
                           (string-fill (concat (format-time-string "%H:%M" (anthe-week-event-start event))
                                                " " (anthe-week-event-title event))
                                        (max 1 (1- width)))
                           "\n")
                          (when (anthe-week-event-location event)
                            (list (anthe-week-event-location event))))))
         (line (cond (continued "")
                     (earlier (concat "… " (anthe-week-event-title event)))
                     (t (or (nth row lines) ""))))
         (text (concat (propertize (if continued " " "▎") 'face `(:foreground ,colour :background ,background))
                       (propertize (truncate-string-to-width line (max 0 (1- width)) nil ?\s "…")
                                   'face `(:foreground ,foreground :background ,background
                                           :weight ,(if (= row 0) 'bold 'normal))))))
    (truncate-string-to-width (anthe-week--event-properties text event) width)))

(defun anthe-week--event-properties (text event)
  "TEXT, a piece of EVENT: its details on hovering it, its keys."
  (add-text-properties 0 (length text)
                       `(anthe-week-event ,event
                         help-echo ,(anthe-week--describe event)
                         mouse-face highlight
                         keymap ,anthe-week-event-map)
                       text)
  text)

(defun anthe-week--echo-event ()
  "Show the event at point in the echo area, as hovering it does, after every
command while point is on it, but not over what a command said."
  (when-let* ((event (get-text-property (point) 'anthe-week-event))
              (description (get-text-property (point) 'help-echo)))
    (when (or (null (current-message)) (equal (current-message) description))
      (let ((message-log-max nil))
        (message "%s" description)))))

(defun anthe-week--describe (event)
  (concat (anthe-week-event-title event) "\n"
          (if (anthe-week-event-all-day event)
              (if (= (anthe-week-event-first event) (anthe-week-event-last event))
                  (format-time-string "%A %-d %B, all day" (anthe-week-event-start event))
                (concat (format-time-string "%A %-d %B" (anthe-week-event-start event)) " to "
                        (format-time-string "%A %-d %B" (anthe-week-event-end event))))
            (concat (format-time-string "%A %-d %B, %H:%M" (anthe-week-event-start event))
                    (format-time-string (if (= (anthe-week-event-first event) (anthe-week-event-last event))
                                            " to %H:%M"
                                          " to %A %-d %B, %H:%M")
                                        (anthe-week-event-end event))))
          (when (anthe-week-event-location event)
            (concat "\n" (anthe-week-event-location event)))
          (when (anthe-week-event-calendar event)
            (concat "\nCalendar: " (anthe-week-event-calendar event)))))

(defvar anthe-week-compact-margin 1
  "Hours shown before the first event and after the last, when compact.")

(defun anthe-week--insert (monday width &optional compact)
  "Insert the week from MONDAY, an absolute day, at most WIDTH columns wide.
COMPACT: a row an hour instead of two, and only the hours with events.
Each cell has its day and time, as `anthe-week-slot', for adding an event."
  (let* ((gutter 7)                  ; "all day" and a space
         (per-hour (if compact 1 2))
         (slot (/ 60 per-hour))
         (column (max 8 (1- (/ (- width gutter) 7))))
         (days (number-sequence monday (+ monday 6)))
         (today (org-today))
         (decoded (decode-time))
         (now (+ (* 60 (decoded-time-hour decoded)) (decoded-time-minute decoded)))
         (events (anthe-week--events monday (+ monday 6)))
         (all-day (sort (seq-filter #'anthe-week-event-banner events)
                        :key (lambda (e) (list (anthe-week-event-first e) (- (anthe-week-event-last e))))))
         (timed (seq-remove #'anthe-week-event-banner events))
         (hours (unless (and compact timed) (list anthe-week-hours)))
         (margin (if (and compact timed) anthe-week-compact-margin 0))
         (first-hour (max 0 (- (apply #'min (append (mapcar #'car hours)
                                                    (mapcar (lambda (e) (/ (anthe-week-event-from e) 60)) timed)))
                               margin)))
         (last-hour (min 24 (+ (apply #'max (append (mapcar #'cdr hours)
                                                    (mapcar (lambda (e) (ceiling (anthe-week-event-to e) 60.0)) timed)))
                               margin)))
         (rows (* per-hour (- last-hour first-hour)))
         (grid (anthe-week--blend (face-foreground 'default nil t) 0.12))
         (today-background (anthe-week--blend (face-foreground 'default nil t) 0.04))
         (accent (anthe-week--colour 'blue))
         (separator (lambda (&optional face) (propertize "│" 'face `(:foreground ,grid ,@face))))
         (now-row (and (<= (* 60 first-hour) now) (< now (* 60 last-hour))
                       (/ (- now (* 60 first-hour)) slot)))
         (cell (lambda (start day minutes)
                 "Mark the cell from START to point as DAY at MINUTES."
                 (put-text-property start (point) 'anthe-week-slot (cons day minutes)))))
    ;; The rows of the timed events, and their lanes
    (dolist (e timed)
      (setf (anthe-week-event-row-start e) (/ (- (anthe-week-event-from e) (* 60 first-hour)) slot))
      (setf (anthe-week-event-row-end e)
            (max (1+ (anthe-week-event-row-start e))
                 (ceiling (- (anthe-week-event-to e) (* 60 first-hour)) (float slot)))))
    (dolist (day days)
      (anthe-week--lanes (seq-filter (lambda (e) (= (anthe-week-event-first e) day)) timed)))
    ;; The days
    (insert (make-string gutter ?\s))
    (dolist (day days)
      (insert (funcall separator))
      (let ((start (point)))
      (insert (let ((label (truncate-string-to-width
                            (anthe-week--date day (if (>= column 14) " %a %-d %b " " %a %-d "))
                            column)))
                (cond ((= day today)
                       (concat (propertize label 'face `(:background ,accent
                                                         :foreground ,(face-background 'default nil t)
                                                         :weight bold))
                               (make-string (- column (string-width label)) ?\s)))
                      ((< day today) (propertize (string-pad label column) 'face 'shadow))
                      (t (propertize (string-pad label column) 'face 'bold)))))
      (funcall cell start day nil)))
    (insert "\n")
    ;; The all-day events, each on the days it lasts, in rows
    (let (lanes)
      (dolist (e all-day)
        (let ((lane (seq-position lanes (anthe-week-event-first e) #'<)))
          (if lane (setf (nth lane lanes) (anthe-week-event-last e))
            (setq lane (length lanes) lanes (append lanes (list (anthe-week-event-last e)))))
          (setf (anthe-week-event-lane e) lane)))
      (dotimes (lane (length lanes))
        (insert (propertize (string-pad (if (= lane 0) "all day" "") gutter) 'face 'shadow))
        (dolist (day days)
          (let ((e (seq-find (lambda (e) (and (= (anthe-week-event-lane e) lane)
                                              (<= (anthe-week-event-first e) day (anthe-week-event-last e))))
                             all-day)))
            (cond ((null e) (insert (funcall separator)
                                    (anthe-week--blank (make-string column ?\s) nil)))
                  ;; The title on its first day this week, its colour on the others
                  ((or (= day monday) (= day (anthe-week-event-first e)))
                   (insert (funcall separator)
                           (anthe-week--event-text e column 0 today now nil
                                                   (< (anthe-week-event-first e) day))))
                  ;; The separator too, for one block
                  (t (insert (anthe-week--event-text e (1+ column) 0 today now t))))
            (funcall cell (- (point) column) day nil)))
        (insert "\n")))
    ;; The hours
    (dotimes (row rows)
      (let* ((hour-line (and (= 0 (% row per-hour)) (> row 0)))
             (minutes (+ (* 60 first-hour) (* row slot)))
             (line-face (and hour-line `(:overline ,grid))))
        (insert (cond ((eql row now-row)
                       (propertize (string-pad (format "%02d:%02d" (/ now 60) (% now 60)) gutter) 'face `(error bold ,@line-face)))
                      ((= 0 (% row per-hour))
                       (propertize (string-pad (format "%02d:00" (+ first-hour (/ row per-hour))) gutter) 'face `(shadow ,@line-face)))
                      (t (make-string gutter ?\s))))
        (dolist (day days)
          (let ((here (sort (seq-filter (lambda (e) (and (= (anthe-week-event-first e) day)
                                                         (<= (anthe-week-event-row-start e) row)
                                                         (< row (anthe-week-event-row-end e))))
                                        timed)
                            :key #'anthe-week-event-lane))
                (blank (lambda (n)
                         (anthe-week--blank
                          (make-string n (if (and (= day today) (eql row now-row)) ?─ ?\s))
                          `(,@(when (and (= day today) (eql row now-row)) '(:foreground "red"))
                            ,@(when (= day today) `(:background ,today-background))
                            ,@line-face))))
                (at 0))
            (insert (funcall separator line-face))
            (dolist (e here)
              (let* ((start (/ (* (anthe-week-event-lane e) column) (anthe-week-event-lanes e)))
                     (end (/ (* (1+ (anthe-week-event-lane e)) column) (anthe-week-event-lanes e))))
                (when (> start at) (insert (funcall blank (- start at))))
                (insert (anthe-week--event-text e (- end start) (- row (anthe-week-event-row-start e))
                                                today now))
                (setq at end)))
            (when (< at column) (insert (funcall blank (- column at))))
            (funcall cell (- (point) column) day minutes)))
        (insert "\n")))))

(defun anthe-week--blank (text face)
  "TEXT, an empty part of the calendar, in FACE: a click adds an event there."
  (propertize text 'face face 'keymap anthe-week-slot-map
              'help-echo "mouse-1: add an event here"))

;;; Laying out a month

(defun anthe-week--month-event-text (event width today now)
  "A line for EVENT, timed, in the month, WIDTH wide: a coloured edge, its
time and title."
  (let* ((past (or (< (anthe-week-event-last event) today)
                   (and (= (anthe-week-event-last event) today)
                        (<= (anthe-week-event-to event) now))))
         (text (concat (propertize "▎" 'face `(:foreground ,(anthe-week--calendar-colour event)))
                       (propertize (format-time-string "%H:%M " (anthe-week-event-start event))
                                   'face 'shadow)
                       (propertize (anthe-week-event-title event) 'face (if past 'shadow 'default)))))
    (anthe-week--event-properties (truncate-string-to-width text width nil ?\s "…") event)))

(defun anthe-week--insert-month (first width height)
  "Insert the month from FIRST, its first day, an absolute day, at most WIDTH
columns wide and HEIGHT lines high: a row a week, each day its number, then
its all-day events, on top as bars across the days they last, then the others,
as many as fit, and how many more.  Each cell has its day, as
`anthe-week-slot': RET on it shows its week, + adds an event that day."
  (let* ((gutter 4)
         (column (max 8 (1- (/ (- width gutter) 7))))
         (month (car (calendar-gregorian-from-absolute first)))
         (last (1- (anthe-week--add-months first 1)))
         (start (anthe-week--monday first))
         (weeks (ceiling (- (1+ last) start) 7.0))
         ;; A row a week, its number's line and its events'
         (lines (max 3 (/ (1- height) weeks)))
         (today (org-today))
         (decoded (decode-time))
         (now (+ (* 60 (decoded-time-hour decoded)) (decoded-time-minute decoded)))
         (events (anthe-week--events start (+ start (* 7 weeks) -1)))
         (grid (anthe-week--blend (face-foreground 'default nil t) 0.12))
         (today-background (anthe-week--blend (face-foreground 'default nil t) 0.04))
         (accent (anthe-week--colour 'blue))
         (separator (lambda (&optional face) (propertize "│" 'face `(:foreground ,grid ,@face)))))
    ;; The days of the week
    (insert (make-string gutter ?\s))
    (dotimes (i 7)
      (insert (funcall separator)
              (propertize (string-pad (anthe-week--date (+ start i) (if (>= column 12) " %A" " %a")) column)
                          'face (if (>= i 5) 'shadow 'bold))))
    (insert "\n")
    (dotimes (week weeks)
      (let* ((monday (+ start (* 7 week)))
             (days (number-sequence monday (+ monday 6)))
             (all-day (sort (seq-filter (lambda (e) (and (anthe-week-event-banner e)
                                                         (<= (anthe-week-event-first e) (+ monday 6))
                                                         (>= (anthe-week-event-last e) monday)))
                                        events)
                            :key (lambda (e) (list (anthe-week-event-first e) (- (anthe-week-event-last e))))))
             lanes)
        ;; The all-day events in rows, as in the week
        (dolist (e all-day)
          (let ((lane (seq-position lanes (max monday (anthe-week-event-first e)) #'<)))
            (if lane (setf (nth lane lanes) (anthe-week-event-last e))
              (setq lane (length lanes) lanes (append lanes (list (anthe-week-event-last e)))))
            (setf (anthe-week-event-lane e) lane)))
        (let ((items                    ; Each day's lines: an all-day event, nil, or a timed one
               (mapcar (lambda (day)
                         (append (mapcar (lambda (lane)
                                           (seq-find (lambda (e) (and (= (anthe-week-event-lane e) lane)
                                                                      (<= (anthe-week-event-first e) day
                                                                          (anthe-week-event-last e))))
                                                     all-day))
                                         (number-sequence 0 (1- (length lanes))))
                                 (sort (seq-filter (lambda (e) (and (not (anthe-week-event-banner e))
                                                                    (= (anthe-week-event-first e) day)))
                                                   events)
                                       :key #'anthe-week-event-from)))
                       days)))
          (dotimes (line lines)
            (let ((line-face (and (= line 0) `(:overline ,grid))))
              (insert (if (= line 0)
                          (propertize (string-pad (anthe-week--date monday "%V") gutter) 'face `(shadow ,@line-face))
                        (make-string gutter ?\s)))
              (cl-loop
               for day in days for here in items
               do (let* ((cell (point))
                         (other-month (/= (car (calendar-gregorian-from-absolute day)) month))
                         (blank (lambda (n)
                                  (anthe-week--blank (make-string n ?\s)
                                                     `(,@(when (= day today) `(:background ,today-background))
                                                       ,@line-face))))
                         (fits (1- lines))
                         ;; The last line says how many more, if they don't fit
                         (hidden (when (> (length here) fits)
                                   (seq-filter #'identity (nthcdr (1- fits) here))))
                         (item (and (> line 0) (nth (1- line) here)))
                         (continued (and item (anthe-week-event-banner item)
                                         (> day (max monday (anthe-week-event-first item))))))
                    (unless continued (insert (funcall separator line-face)))
                    (cond
                     ((= line 0)
                      (let ((label (anthe-week--date day (if (= 1 (calendar-extract-day
                                                                    (calendar-gregorian-from-absolute day)))
                                                             " %-d %b " " %-d "))))
                        (insert (cond ((= day today)
                                       (propertize label 'face `(:background ,accent :weight bold
                                                                 :foreground ,(face-background 'default nil t)
                                                                 ,@line-face)))
                                      (other-month (propertize label 'face `(shadow ,@line-face)))
                                      (t (propertize label 'face `(bold ,@line-face))))
                                (funcall blank (max 0 (- column (string-width label)))))))
                     ((and hidden (= line fits))
                      (let ((more (format " +%d more" (length hidden))))
                        (insert (propertize more 'face 'shadow
                                            'help-echo (mapconcat #'anthe-week--describe hidden "\n\n"))
                                (funcall blank (max 0 (- column (length more)))))))
                     ((null item) (insert (funcall blank column)))
                     ((anthe-week-event-banner item)
                      (insert (anthe-week--event-text item (if continued (1+ column) column) 0 today now continued)))
                     (t (insert (anthe-week--month-event-text item column today now))))
                    (put-text-property (if continued cell (1+ cell)) (point) 'anthe-week-slot (cons day nil))))
              (insert "\n"))))))))

;;; The week buffer

(defvar-local anthe-week--start nil
  "The first day shown, an absolute day: a Monday, or a month's first day.")
(defvar-local anthe-week--width nil)
(defvar-local anthe-week--height nil)

(defun anthe-week--period-start (day)
  "The first day of the week or the month of DAY, as the buffer shows."
  (if (eq anthe-week--view 'month)
      (pcase-let ((`(,month ,_ ,year) (calendar-gregorian-from-absolute day)))
        (calendar-absolute-from-gregorian (list month 1 year)))
    (anthe-week--monday day)))

(defun anthe-week--day-shown ()
  "The day at point, or the first shown, today if shown."
  (or (car (get-text-property (point) 'anthe-week-slot))
      (let ((next (if (eq anthe-week--view 'month)
                      (anthe-week--add-months anthe-week--start 1)
                    (+ 7 anthe-week--start))))
        (if (and (<= anthe-week--start (org-today)) (< (org-today) next)) (org-today)
          anthe-week--start))))

(defun anthe-week--add-months (first count)
  "The first day of the month COUNT months after the one of FIRST, its first day."
  (pcase-let* ((`(,month ,_ ,year) (calendar-gregorian-from-absolute first))
               (months (+ (* 12 year) (1- month) count)))
    (calendar-absolute-from-gregorian (list (1+ (mod months 12)) 1 (floor months 12)))))
(defvar anthe-week--watches nil)

(defun anthe-week--render ()
  (let ((inhibit-read-only t)
        (line (line-number-at-pos))
        (window (get-buffer-window (current-buffer))))
    (setq anthe-week--width (if window (window-max-chars-per-line window) (frame-width))
          anthe-week--height (if window (window-body-height window) (frame-height)))
    (erase-buffer)
    (insert (propertize (anthe-week--date anthe-week--start "%B %Y")
                        'face '(:weight bold :height 1.3))
            (if (eq anthe-week--view 'month)
                ""
              (propertize (format "   week %s, %s to %s" (anthe-week--date anthe-week--start "%V")
                                  (anthe-week--date anthe-week--start "%-d %b")
                                  (anthe-week--date (+ 6 anthe-week--start) "%-d %b"))
                          'face 'shadow))
            "\n"
            (propertize (if (eq anthe-week--view 'month)
                            "[ previous   ] next   . this month   w week   s search   RET open (a day: its week)   + add an event   gr refresh   S sync\n\n"
                          "[ previous   ] next   . this week   m month   s search   RET open   + or a click: add an event   gr refresh   S sync\n\n")
                        'face 'shadow))
    (if (eq anthe-week--view 'month)
        ;; The title's line is taller
        (anthe-week--insert-month anthe-week--start (1- anthe-week--width) (- anthe-week--height 5))
      (anthe-week--insert anthe-week--start (1- anthe-week--width)))
    (goto-char (point-min))
    (forward-line (1- line))))

(defun anthe-week--resized (window)
  (with-current-buffer (window-buffer window)
    (unless (and (eql (window-max-chars-per-line window) anthe-week--width)
                 (or (eq anthe-week--view 'week)
                     (eql (window-body-height window) anthe-week--height)))
      (anthe-week--render))))

(defun anthe-week--file-changed (_event)
  "Show the events again in the week buffers, as a file changed."
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (when (derived-mode-p 'anthe-week-mode) (anthe-week--render)))))

(define-derived-mode anthe-week-mode special-mode "Week"
  "A week of calendar events.  See `anthe-week'."
  (setq truncate-lines t
        buffer-read-only t)
  (add-hook 'window-size-change-functions #'anthe-week--resized nil t)
  (add-hook 'post-command-hook #'anthe-week--echo-event nil t)
  ;; Its s and S would hide the keys here
  (when (fboundp 'evil-snipe-local-mode) (evil-snipe-local-mode -1))
  (unless anthe-week--watches
    (setq anthe-week--watches
          (delq nil (mapcar (lambda (file)
                              (ignore-errors
                                (file-notify-add-watch (expand-file-name file) '(change)
                                                       #'anthe-week--file-changed)))
                            anthe-week-files))))
  (add-hook 'kill-buffer-hook
            (lambda ()
              (unless (seq-some (lambda (b) (and (not (eq b (current-buffer)))
                                                 (eq (buffer-local-value 'major-mode b) 'anthe-week-mode)))
                                (buffer-list))
                (mapc #'file-notify-rm-watch anthe-week--watches)
                (setq anthe-week--watches nil)))
            nil t))

(defun anthe-week--show (view day)
  "Show the VIEW (`week' or `month') of DAY, an absolute day, today by default,
in its buffer, *week* or *month*."
  (with-current-buffer (get-buffer-create (format "*%s*" view))
    (unless (derived-mode-p 'anthe-week-mode) (anthe-week-mode))
    (setq anthe-week--view view
          mode-name (capitalize (symbol-name view)))
    (setq anthe-week--start (anthe-week--period-start (or day (org-today))))
    (pop-to-buffer-same-window (current-buffer))
    (anthe-week--render)))

(defun anthe-week (&optional day)
  "Show the week of DAY (an absolute day, today by default) in the *week* buffer;
from the month, the week of the day at point."
  (interactive (list (and (derived-mode-p 'anthe-week-mode) (anthe-week--day-shown))))
  (anthe-week--show 'week day))

(defun anthe-month (&optional day)
  "Show the month of DAY (an absolute day, today by default) in the *month*
buffer; from the week, the month of the day at point."
  (interactive (list (and (derived-mode-p 'anthe-week-mode) (anthe-week--day-shown))))
  (anthe-week--show 'month day))

(defun anthe-week-next (&optional count)
  "Show the next week or month, or COUNT later."
  (interactive "p")
  (setq anthe-week--start (if (eq anthe-week--view 'month)
                              (anthe-week--add-months anthe-week--start (or count 1))
                            (+ anthe-week--start (* 7 (or count 1)))))
  (anthe-week--render))

(defun anthe-week-previous (&optional count)
  "Show the previous week or month, or COUNT earlier."
  (interactive "p")
  (anthe-week-next (- (or count 1))))

(defun anthe-week-today ()
  "Show this week or month."
  (interactive)
  (setq anthe-week--start (anthe-week--period-start (org-today)))
  (anthe-week--render))

(defun anthe-week-refresh ()
  "Read the events again."
  (interactive)
  (setq anthe-week--cache nil)
  (anthe-week--render))

(defun anthe-week-sync ()
  "Sync the calendars with the server (vdirsyncer), then import them; the
week shows the new events once the file changes."
  (interactive)
  (require 'khalel)
  (message "Syncing the calendars...")
  (let ((buffer (generate-new-buffer " *anthe-week-sync*")))
    (make-process
     :name "vdirsyncer" :buffer buffer :noquery t :connection-type 'pipe
     :command `(,(or khalel-vdirsyncer-command "vdirsyncer") "sync")
     :sentinel (lambda (process _event)
                 (unless (process-live-p process)
                   (if (zerop (process-exit-status process))
                       (progn (save-window-excursion (khalel-import-events))
                              (message "Calendars synced"))
                     (message "Calendar sync failed: %s"
                              (car (last (split-string (with-current-buffer buffer (buffer-string))
                                                       "\n" t)))))
                   (kill-buffer buffer))))))

(define-keymap :keymap anthe-week-mode-map
  "]" #'anthe-week-next "[" #'anthe-week-previous "." #'anthe-week-today
  "g" #'anthe-week-refresh "S" #'anthe-week-sync "RET" #'anthe-week-visit
  "+" #'anthe-week-add-event "m" #'anthe-month "w" #'anthe-week)

(with-eval-after-load 'evil
  (evil-set-initial-state 'anthe-week-mode 'motion)
  (evil-define-key* 'motion anthe-week-mode-map
    "]" #'anthe-week-next "[" #'anthe-week-previous "." #'anthe-week-today
    "gr" #'anthe-week-refresh "S" #'anthe-week-sync "+" #'anthe-week-add-event
    (kbd "RET") #'anthe-week-visit "q" #'quit-window "m" #'anthe-month "w" #'anthe-week))

(map! :leader :desc "Week calendar" "o a w" #'anthe-week
      :desc "Month calendar" "o a M" #'anthe-month)

;;; Searching an event

(defun anthe-week--candidate (event today)
  "EVENT as a candidate: its day and time, title and place, then, dimmed, what
else to match: its calendar, organiser and description."
  (let* ((past (< (anthe-week-event-last event) today))
         (more (string-join (delq nil (list (anthe-week-event-calendar event)
                                            (anthe-week-event-organizer event)
                                            (anthe-week-event-description event)))
                            " · "))
         (text (concat (propertize (format-time-string
                                    (if (anthe-week-event-all-day event) "%a %e %b %Y  all day" "%a %e %b %Y  %H:%M  ")
                                    (anthe-week-event-start event))
                                   'face (if past 'shadow 'font-lock-constant-face))
                       "  "
                       (propertize (anthe-week-event-title event) 'face (if past 'shadow 'bold))
                       (when (anthe-week-event-location event)
                         (concat "  " (propertize (anthe-week-event-location event) 'face 'font-lock-string-face)))
                       (unless (string-empty-p more)
                         (concat "  " (propertize (replace-regexp-in-string "[ \t\n]+" " " more)
                                                  'face 'shadow))))))
    (propertize text 'anthe-week-event event)))

(defun anthe-week--event-region (event)
  "The first and last positions of EVENT's block in this buffer, or nil."
  (let (start end (pos (point-min)))
    (while (setq pos (text-property-not-all pos (point-max) 'anthe-week-event nil))
      (let ((e (get-text-property pos 'anthe-week-event))
            (next (next-single-property-change pos 'anthe-week-event nil (point-max))))
        (when (and (equal (anthe-week-event-file e) (anthe-week-event-file event))
                   (= (anthe-week-event-pos e) (anthe-week-event-pos event)))
          (setq start (or start pos) end next))
        (setq pos next)))
    (and start (cons start end))))

(defvar anthe-week--found nil "The overlays on the event previewed.")

(defun anthe-week--show-event (event window)
  "Show the week or month of EVENT in WINDOW, the calendar's, point on it,
highlighted."
  (with-current-buffer (window-buffer window)
    (mapc #'delete-overlay anthe-week--found)
    (setq anthe-week--found nil)
    (let ((first (anthe-week--period-start (anthe-week-event-first event))))
      (unless (eql first anthe-week--start)
        (setq anthe-week--start first)
        (anthe-week--render)))
    (when-let* ((region (anthe-week--event-region event)))
      (goto-char (car region))
      (set-window-point window (car region))
      ;; Each piece of its block, on each of its lines
      (let ((pos (car region)))
        (while (setq pos (text-property-not-all pos (cdr region) 'anthe-week-event nil))
          (let ((next (next-single-property-change pos 'anthe-week-event nil (cdr region))))
            (when (= (anthe-week-event-pos (get-text-property pos 'anthe-week-event))
                     (anthe-week-event-pos event))
              (let ((overlay (make-overlay pos next)))
                (overlay-put overlay 'face '(:inverse-video t))
                (push overlay anthe-week--found)))
            (setq pos next)))))))

(defun anthe-week-search ()
  "Search an event, by its title, place, calendar, organiser or
description: the week or month of the one selected shows while choosing;
RET stays on it, C-g goes back.  The coming events first, then the past ones, the latest first."
  (interactive)
  (unless (derived-mode-p 'anthe-week-mode) (anthe-week))
  (require 'consult)
  (let* ((today (org-today))
         (window (selected-window))
         (start anthe-week--start)
         (line (line-number-at-pos))
         (events (sort (copy-sequence (anthe-week--events most-negative-fixnum most-positive-fixnum))
                       :key (lambda (e) (anthe-week-event-start e))))
         (coming (seq-filter (lambda (e) (>= (anthe-week-event-last e) today)) events))
         (past (reverse (seq-remove (lambda (e) (>= (anthe-week-event-last e) today)) events)))
         (restore (lambda ()
                    (with-current-buffer (window-buffer window)
                      (mapc #'delete-overlay anthe-week--found)
                      (setq anthe-week--found nil)
                      (unless (eql start anthe-week--start)
                        (setq anthe-week--start start)
                        (anthe-week--render))
                      (goto-char (point-min))
                      (forward-line (1- line))
                      (set-window-point window (point)))))
         (event (consult--read
                 (mapcar (lambda (e) (anthe-week--candidate e today)) (append coming past))
                 :prompt "Event: "
                 :sort nil
                 :require-match t
                 :category 'anthe-week-event
                 :lookup (lambda (selected candidates &rest _)
                           (when-let* ((candidate (car (member selected candidates))))
                             (get-text-property 0 'anthe-week-event candidate)))
                 :state (lambda (action event)
                          (pcase action
                            ('preview (if event (anthe-week--show-event event window) (funcall restore)))
                            ('return (if event
                                         (with-current-buffer (window-buffer window)
                                           (mapc #'delete-overlay anthe-week--found)
                                           (setq anthe-week--found nil))
                                       (funcall restore))))))))
    (when event
      (anthe-week--show-event event window)
      (with-current-buffer (window-buffer window)
        (mapc #'delete-overlay anthe-week--found)
        (setq anthe-week--found nil)))))

(define-keymap :keymap anthe-week-mode-map "s" #'anthe-week-search "/" #'anthe-week-search)
(with-eval-after-load 'evil
  (evil-define-key* 'motion anthe-week-mode-map "s" #'anthe-week-search "/" #'anthe-week-search))

;;; Reminders

;; A notification (dunst) before each event, as the calendar's reminders say,
;; those set on the phone or the server, or as khalel's capture adds
;; (`khalel-default-alarm'); for the events without, `anthe-week-default-reminders'.

(defvar anthe-week-default-reminders '(10)
  "The minutes before an event without reminders to remind it, but all-day ones.")

(defvar anthe-week--reminders-timer nil)
(defvar anthe-week--reminders-checked nil "When the reminders were last checked.")

(defun anthe-week--remind (event minutes)
  "Notify of EVENT, MINUTES before it."
  (let ((start (anthe-week-event-start event)))
    (notifications-notify
     :app-name "Calendar"
     :app-icon "x-office-calendar"
     :title (anthe-week-event-title event)
     :body (concat (cond ((anthe-week-event-all-day event)
                          (format-time-string "%A %-d %B, all day" start))
                         ((<= minutes 0) (format-time-string "Now, %H:%M" start))
                         ((= (time-to-days start) (org-today))
                          (format "In %s, at %s"
                                  (if (< minutes 60) (format "%d min" minutes)
                                    (format "%d h%s" (/ minutes 60)
                                            (if (zerop (% minutes 60)) "" (format " %02d" (% minutes 60)))))
                                  (format-time-string "%H:%M" start)))
                         (t (format-time-string "%A %-d %B, %H:%M" start)))
                   (when (anthe-week-event-location event)
                     (concat "\n" (anthe-week-event-location event))))
     :actions '("default" "Show the week")
     :on-action (lambda (_id _key)
                  (anthe-week (anthe-week-event-first event))
                  (when-let* ((region (anthe-week--event-region event)))
                    (goto-char (car region)))))))

(defun anthe-week--check-reminders ()
  "Notify of the events whose reminder came since the last check, but those
over (after a sleep)."
  (let* ((now (current-time))
         (since (or anthe-week--reminders-checked (time-subtract now 60)))
         (today (org-today)))
    (setq anthe-week--reminders-checked now)
    (dolist (event (anthe-week--events today (+ today 8)))
      (when (time-less-p now (anthe-week-event-end event))
        (dolist (minutes (or (anthe-week-event-alarms event)
                             (unless (anthe-week-event-all-day event) anthe-week-default-reminders)))
          (let ((at (time-subtract (anthe-week-event-start event) (* 60 minutes))))
            (when (and (time-less-p since at) (not (time-less-p now at)))
              (anthe-week--remind event minutes))))))))

(define-minor-mode anthe-week-reminders-mode
  "Notify of the calendar's events, before them, as their reminders say."
  :global t
  (when anthe-week--reminders-timer (cancel-timer anthe-week--reminders-timer))
  (setq anthe-week--reminders-timer nil anthe-week--reminders-checked nil)
  (when anthe-week-reminders-mode
    (require 'notifications)
    ;; At the start of each minute
    (setq anthe-week--reminders-timer
          (run-at-time (- 60 (mod (float-time) 60)) 60
                       (lambda () (with-demoted-errors "Calendar reminders: %S"
                                    (anthe-week--check-reminders)))))))

(anthe-week-reminders-mode 1)

(provide 'anthe-week)
;;; anthe-week.el ends here
