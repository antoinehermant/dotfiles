;;; anthe-windows.el --- Resize windows from a repeating key map -*- lexical-binding: t; -*-
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  `SPC w .' enters a resize mode: h/j/k/l move the window border in that
;;  direction, and any key outside the mode leaves it.
;;
;;  Tiled EXWM windows live in Emacs windows, so the same commands resize
;;  them.  Floating EXWM windows are resized directly instead.  The mode uses
;;  `set-transient-map', whose map EXWM checks before sending a key to the
;;  application, so it also works from an EXWM buffer.
;;
;;; Code:

(require 'color)

;; Without these, windows snap to whole character cells
(setq window-resize-pixelwise t
      frame-resize-pixelwise t)

(defvar anthe/window-resize-step '(5 . 2)
  "Columns and lines moved by one resize step.")

(defun anthe/window--move-border (direction steps)
  "Move the border of the selected window STEPS steps in DIRECTION.
The right or bottom border is moved when there is a window beyond it,
otherwise the left or top one, so the border follows the key."
  (let* ((horizontal (memq direction '(left right)))
         (delta (* steps (if horizontal
                             (car anthe/window-resize-step)
                           (cdr anthe/window-resize-step))))
         (delta (if (memq direction '(left up)) (- delta) delta)))
    (cond
     ((and (derived-mode-p 'exwm-mode) (bound-and-true-p exwm--floating-frame))
      (let ((pixels (* delta (if horizontal (frame-char-width) (frame-char-height)))))
        (if horizontal
            (exwm-layout-enlarge-window-horizontally pixels)
          (exwm-layout-enlarge-window pixels))))
     ((window-in-direction (if horizontal 'right 'below))
      (enlarge-window delta horizontal))
     ((window-in-direction (if horizontal 'left 'above))
      (enlarge-window (- delta) horizontal)))))

(defmacro anthe/window--define-move (name direction steps)
  "Define NAME, moving the window border STEPS steps in DIRECTION."
  `(defun ,name ()
     ,(format "Move the window border %s by %d step(s)." direction steps)
     (interactive)
     (anthe/window--move-border ',direction ,steps)))

(anthe/window--define-move anthe/window-border-left left 1)
(anthe/window--define-move anthe/window-border-down down 1)
(anthe/window--define-move anthe/window-border-up up 1)
(anthe/window--define-move anthe/window-border-right right 1)
(anthe/window--define-move anthe/window-border-left-more left 3)
(anthe/window--define-move anthe/window-border-down-more down 3)
(anthe/window--define-move anthe/window-border-up-more up 3)
(anthe/window--define-move anthe/window-border-right-more right 3)

(defun anthe/window-resize-quit ()
  "Leave the window resize mode."
  (interactive))

(defvar-keymap anthe/window-resize-map
  "h" #'anthe/window-border-left
  "j" #'anthe/window-border-down
  "k" #'anthe/window-border-up
  "l" #'anthe/window-border-right
  "H" #'anthe/window-border-left-more
  "J" #'anthe/window-border-down-more
  "K" #'anthe/window-border-up-more
  "L" #'anthe/window-border-right-more
  "=" #'balance-windows
  "m" #'doom/window-maximize-buffer
  "u" #'winner-undo
  "<escape>" #'anthe/window-resize-quit
  "q" #'anthe/window-resize-quit)

(defun anthe/window-resize ()
  "Resize windows with single keys until another key is pressed."
  (interactive)
  (set-transient-map
   anthe/window-resize-map
   ;; Checked before each command: stay for the keys of the map, except quit
   (lambda ()
     (and (eq this-command (lookup-key anthe/window-resize-map (this-command-keys-vector)))
          (not (eq this-command #'anthe/window-resize-quit))))
   nil
   "Resize: hjkl move border, HJKL more, = balance, m maximize, u undo, ESC quit"))

(map! :leader
      :desc "Resize windows" "w ." #'anthe/window-resize)

;;; A gentle flash of the window switched into, to see where the cursor went
;;; among many windows: its text's background goes a little towards the text
;;; colour and fades back.  Only with three windows or more on the frame; not
;;; on coming back from the minibuffer, nor in EXWM buffers (an X window,
;;; which an overlay can't tint).

(defvar anthe/window-flash-strength 0.09
  "How far towards the text colour the flash takes the background, 0 to 1.")

(defvar anthe/window-flash-duration 0.4
  "Seconds the flash takes to fade.")

(defvar anthe/window-flash--steps 12)
(defvar anthe/window-flash--overlay nil)
(defvar anthe/window-flash--timer nil)
(defvar anthe/window-flash--last nil
  "The window last selected, but the minibuffer's.")

(defun anthe/window-flash--stop ()
  "End the flash going on."
  (when (timerp anthe/window-flash--timer)
    (cancel-timer anthe/window-flash--timer))
  (when (overlayp anthe/window-flash--overlay)
    (delete-overlay anthe/window-flash--overlay))
  (setq anthe/window-flash--timer nil
        anthe/window-flash--overlay nil))

(defun anthe/window-flash (&optional window)
  "Flash the text of WINDOW, the selected one by default, gently."
  (interactive)
  (anthe/window-flash--stop)
  (let* ((window (or window (selected-window)))
         (background (color-name-to-rgb (face-background 'default nil t)))
         (foreground (color-name-to-rgb (face-foreground 'default nil t)))
         (overlay (with-current-buffer (window-buffer window)
                    (make-overlay (window-start window) (window-end window t))))
         (step 0))
    (when (and background foreground)
      ;; Only in this window, should the buffer show in others
      (overlay-put overlay 'window window)
      (overlay-put overlay 'priority 1000)
      (setq anthe/window-flash--overlay overlay
            anthe/window-flash--timer
            (run-at-time
             0 (/ anthe/window-flash-duration anthe/window-flash--steps)
             (lambda ()
               (if (>= step anthe/window-flash--steps)
                   (anthe/window-flash--stop)
                 ;; Fading fast first, then slowly
                 (let ((amount (* anthe/window-flash-strength
                                  (expt (- 1 (/ (float step) anthe/window-flash--steps)) 2))))
                   (overlay-put overlay 'face
                                `(:background
                                  ,(apply #'color-rgb-to-hex
                                          (append (cl-mapcar (lambda (b f) (+ b (* amount (- f b))))
                                                             background foreground)
                                                  '(2)))
                                  :extend t)))
                 (setq step (1+ step)))))))))

(defun anthe/window-flash--selected (frame)
  "Flash the window selected in FRAME, when it is another one."
  (let ((window (frame-selected-window frame)))
    (when (and (eq frame (selected-frame))
               (not (window-minibuffer-p window))
               (not (eq window anthe/window-flash--last)))
      (setq anthe/window-flash--last window)
      (unless (or (with-current-buffer (window-buffer window) (derived-mode-p 'exwm-mode))
                  ;; With two windows, which one is selected is plain enough
                  (< (length (window-list (window-frame window) 'nomini)) 3))
        (anthe/window-flash window)))))

(define-minor-mode anthe/window-flash-mode
  "Flash the window switched into, gently."
  :global t
  (if anthe/window-flash-mode
      (add-hook 'window-selection-change-functions #'anthe/window-flash--selected)
    (remove-hook 'window-selection-change-functions #'anthe/window-flash--selected)))

(anthe/window-flash-mode 1)

;;; Gaps between the windows

;; Gaps between the windows, and margins: left and right of the windows,
;; between them and the top bar, and the echo area, under which too.  The top
;; bar and the echo area run the frame's whole width.  Under EXWM the gaps
;; are holes cut in the frame (its X shape): the wallpaper shows there as it
;; is, neither tinted nor blurred, and the applications' rounded corners
;; round into it; the child frames (completion popups) are kept whole across
;; them.  The window dividers make the gaps between windows, the outer
;; fringes the margins beside them, the room under the top bar's text the
;; margin under it; the margin above the echo area is taken from the
;; dividers under the bottom windows.
(defvar anthe/window-gap 6
  "Pixels between two windows.")

(defvar anthe/window-margin 6
  "Pixels left and right of the windows, by the frame's edges.")

(defvar anthe/window-bar-gap nil
  "Pixels between the top bar and the windows; nil: `anthe/window-margin'.")

(defvar anthe/window-bar-padding 0
  "Pixels of the top bar above and under its text.")

(defvar anthe/window-echo-gap nil
  "Pixels between the windows and the echo area, at most `anthe/window-gap';
nil: `anthe/window-margin'.")

(defvar anthe/window-echo-margin 0
  "Pixels under the echo area, by the frame's bottom edge.")

(defvar anthe/window-radius 10
  "Pixels of the windows' rounded corners, 0 for square ones.
The corners are cut in steps of a pixel, not smoothed as picom's.")

(defvar-local anthe/window-cards-function nil
  "When non-nil, a function of a window showing this buffer giving the cards
kept of it, each (LEFT TOP RIGHT BOTTOM) in its frame's pixels: the rest of
the window is cut out, the wallpaper showing there.")

(defun anthe/window-cards (window property)
  "The cards in WINDOW: the text of each value of PROPERTY, from the first
to the last character of its lines, bar the space aligning them, as many of
its lines as show.  For `anthe/window-cards-function'."
  (with-current-buffer (window-buffer window)
    (pcase-let ((`(,body-left ,body-top ,body-right ,body-bottom) (window-body-pixel-edges window))
                (cards nil)
                (pos (window-start window))
                (end (min (point-max) (or (window-end window t) (point-max)))))
      (save-excursion
        (while (< pos end)
          (let ((name (get-text-property pos property))
                ;; A card's text is a line's part at most
                (next (min (next-single-property-change pos property nil end)
                           (progn (goto-char pos) (line-end-position)))))
            (when name
              (let ((from pos))
                ;; The space reaching the card's column is not the card
                (while (and (< from next)
                            (eq (car-safe (get-text-property from 'display)) 'space))
                  (setq from (1+ from)))
                (when-let* (((< from next))
                            (left (pos-visible-in-window-p from window t))
                            ;; The last character, and its width: an aligning
                            ;; space after it is placed oddly on a line cut
                            ;; by the window's bottom
                            (last (pos-visible-in-window-p (1- next) window t))
                            (right (list (+ (car last)
                                            (string-pixel-width (buffer-substring (1- next) next))))))
                  (let* ((height (or (nth 4 left)
                                     (cdr (window-text-pixel-size
                                           window (line-beginning-position) (line-end-position)))))
                         (x1 (+ body-left (car left)))
                         (x2 (+ body-left (car right)))
                         (y1 (+ body-top (max 0 (cadr left))))
                         (y2 (+ body-top (cadr left) height))
                         (card (assq name cards)))
                    (if card
                        (setcdr card (list (min x1 (nth 1 card)) (min y1 (nth 2 card))
                                           (max x2 (nth 3 card)) (max y2 (nth 4 card))))
                      (push (list name x1 y1 x2 y2) cards))))))
            (setq pos (if (= next pos) (1+ pos) next))))
        (mapcar (pcase-lambda (`(,_ ,x1 ,y1 ,x2 ,y2))
                  (list x1 y1 (min x2 body-right) (min y2 body-bottom)))
                cards)))))

(defun anthe/window-gaps--bar-gap ()
  (or anthe/window-bar-gap anthe/window-margin))

(defun anthe/window-gaps--echo-gap ()
  (min anthe/window-gap (or anthe/window-echo-gap anthe/window-margin)))

(defun anthe/window-gaps--colours (&rest _)
  "Colour the dividers as the background, where they are not cut out."
  (when anthe/window-gaps-mode
    (let ((background (face-attribute 'default :background nil t)))
      (dolist (face '(window-divider window-divider-first-pixel window-divider-last-pixel))
        (set-face-attribute face nil :foreground background)))))

(defun anthe/window-gaps--bar-room ()
  "A tab bar item, empty, giving the bar room above and under its text."
  (when-let* ((anthe/window-gaps-mode)
              (info (font-info (face-font 'tab-bar))))
    (let* ((ascent (+ (aref info 8) anthe/window-bar-padding))
           (height (+ ascent (aref info 9) anthe/window-bar-padding
                      (anthe/window-gaps--bar-gap))))
      `((anthe-window-gaps menu-item
         ,(propertize " " 'display `(space :width (0) :height (,height)
                                          :ascent ,(round (* 100.0 ascent) height)))
         ignore)))))

(defun anthe/window-gaps--frames ()
  "The frames shaped: EXWM's workspaces."
  (and (bound-and-true-p exwm--connection) (bound-and-true-p exwm-workspace--list)
       (seq-filter #'frame-live-p exwm-workspace--list)))

;; The mode line's right end before the right fringe, off the margin cut
;; there (doom-modeline follows it too)
(setq mode-line-right-align-edge 'right-fringe)

(defun anthe/window-gaps--margins (window)
  "The margins beside WINDOW, (LEFT . RIGHT): by the frame's edges."
  (if anthe/window-gaps-mode
      (cons (if (window-at-side-p window 'left) anthe/window-margin 0)
            (if (window-at-side-p window 'right) anthe/window-margin 0))
    '(0 . 0)))

(defun anthe/window-gaps--fringes (frame)
  "Widen the fringes of FRAME's windows by the frame's edges by the margin:
the buffer's, else the frame's, and the margin."
  (dolist (window (window-list frame 'never))
    (let* ((buffer (window-buffer window))
           (margins (anthe/window-gaps--margins window))
           (left (+ (or (buffer-local-value 'left-fringe-width buffer)
                        (frame-parameter frame 'left-fringe) 8)
                    (car margins)))
           (right (+ (or (buffer-local-value 'right-fringe-width buffer)
                         (frame-parameter frame 'right-fringe) 8)
                     (cdr margins))))
      (unless (equal (take 2 (window-fringes window)) (list left right))
        (set-window-fringes window left right nil t)))))

(defun anthe/window-gaps--rectangles (frame)
  "The rectangles of FRAME to keep: the top bar but the gap under it, the
windows but their dividers and margins, the echo area but its margin, and
the child frames."
  (let ((rects nil)
        (width (frame-native-width frame))
        (bar (tab-bar-height frame t))
        (mini (minibuffer-window frame)))
    (cl-labels ((add (left top right bottom)
                  (when (and (> right left) (> bottom top))
                    (push (make-instance 'xcb:RECTANGLE :x left :y top
                                         :width (- right left) :height (- bottom top))
                          rects)))
                (add-rounded (left top right bottom)
                  ;; The middle, then a row of a pixel a step of the corners
                  (let ((radius (min anthe/window-radius
                                     (/ (- right left) 2) (/ (- bottom top) 2))))
                    (add left (+ top radius) right (- bottom radius))
                    (dotimes (row radius)
                      (let* ((dy (- radius row 0.5))
                             (inset (round (- radius (sqrt (- (* radius radius) (* dy dy)))))))
                        (add (+ left inset) (+ top row) (- right inset) (+ top row 1))
                        (add (+ left inset) (- bottom row 1) (- right inset) (- bottom row)))))))
      (when (> bar 0)
        (add 0 0 width (- bar (anthe/window-gaps--bar-gap))))
      (dolist (window (window-list frame 'never))
        (pcase-let ((`(,left ,top ,right ,bottom) (window-pixel-edges window))
                    (`(,margin-left . ,margin-right) (anthe/window-gaps--margins window)))
          (if-let* ((cards (buffer-local-value 'anthe/window-cards-function
                                               (window-buffer window))))
              ;; A buffer of cards (the dashboard, the wallpaper): only them
              (dolist (card (funcall cards window))
                (apply #'add-rounded card))
            (add-rounded (+ left margin-left) top
                         (- right (window-right-divider-width window) margin-right)
                         (- bottom (window-bottom-divider-width window))))
          ;; Above the echo area, the divider under the gap is kept
          (when (and (eq (window-frame mini) frame) (window-at-side-p window 'bottom)
                     (not (buffer-local-value 'anthe/window-cards-function
                                              (window-buffer window))))
            (add left (+ (- bottom (window-bottom-divider-width window))
                         (anthe/window-gaps--echo-gap))
                 right bottom))))
      (when (eq (window-frame mini) frame)
        (pcase-let ((`(,left ,top ,right ,bottom) (window-pixel-edges mini)))
          (add left top right (- bottom anthe/window-echo-margin))))
      (dolist (child (frame-list))
        (when (and (eq (frame-parameter child 'parent-frame) frame)
                   (frame-visible-p child))
          (pcase-let ((`(,x . ,y) (frame-position child))
                      (`(,left ,top ,right ,bottom) (frame-edges child 'outer-edges)))
            (add x y (+ x (- right left)) (+ y (- bottom top)))))))
    rects))

(defvar anthe/window-gaps--shape-ready nil)

(defun anthe/window-gaps--shape (frame)
  "Cut the gaps out of FRAME's EXWM container, or fill them back."
  (unless anthe/window-gaps--shape-ready
    (require 'xcb-shape)
    (xcb:get-extension-data exwm--connection 'xcb:shape)
    (setq anthe/window-gaps--shape-ready t))
  (when-let* ((container (frame-parameter frame 'exwm-container)))
    (xcb:+request exwm--connection
        (if anthe/window-gaps-mode
            (make-instance 'xcb:shape:Rectangles
                           :operation xcb:shape:SO:Set
                           :destination-kind xcb:shape:SK:Bounding
                           :ordering xcb:ClipOrdering:Unsorted
                           :destination-window container
                           :x-offset 0 :y-offset 0
                           :rectangles (anthe/window-gaps--rectangles frame))
          (make-instance 'xcb:shape:Mask
                         :operation xcb:shape:SO:Set
                         :destination-kind xcb:shape:SK:Bounding
                         :destination-window container
                         :x-offset 0 :y-offset 0
                         :source-bitmap xcb:Pixmap:None)))))

(defvar anthe/window-gaps--timer nil)

(defun anthe/window-gaps--refresh ()
  "Set the margins and shape the frames again, now."
  (setq anthe/window-gaps--timer nil)
  (when-let* ((frames (anthe/window-gaps--frames)))
    (mapc #'anthe/window-gaps--fringes frames)
    (mapc #'anthe/window-gaps--shape frames)
    (xcb:flush exwm--connection)))

(defun anthe/window-gaps--update (&rest _)
  "Shape the frames again, once the changes of this command are done."
  (unless (timerp anthe/window-gaps--timer)
    (setq anthe/window-gaps--timer (run-at-time 0 nil #'anthe/window-gaps--refresh))))

(defun anthe/window-gaps--child-a (frame &rest _)
  "Shape again when FRAME, a child frame, shows, hides or moves."
  (when (and (framep frame) (frame-parameter frame 'parent-frame))
    (anthe/window-gaps--update)))

(define-minor-mode anthe/window-gaps-mode
  "Gaps between the windows and margins around them, the wallpaper showing
through.  After changing their sizes, call this again to apply them."
  :global t
  (let ((width (if anthe/window-gaps-mode anthe/window-gap 1)))
    (setq window-divider-default-right-width width
          window-divider-default-bottom-width width)
    (when window-divider-mode
      (window-divider-mode 1)))
  (let ((hook (if anthe/window-gaps-mode #'add-hook #'remove-hook)))
    (funcall hook 'doom-load-theme-hook #'anthe/window-gaps--colours)
    (funcall hook 'window-size-change-functions #'anthe/window-gaps--update)
    (funcall hook 'window-configuration-change-hook #'anthe/window-gaps--update)
    ;; The cards move with a scroll
    (funcall hook 'window-scroll-functions #'anthe/window-gaps--update))
  (dolist (fn '(make-frame-visible make-frame-invisible set-frame-position set-frame-size))
    (if anthe/window-gaps-mode
        (advice-add fn :after #'anthe/window-gaps--child-a)
      (advice-remove fn #'anthe/window-gaps--child-a)))
  ;; The room under the top bar's text, last of the bar
  (setq tab-bar-format (delq 'anthe/window-gaps--bar-room tab-bar-format))
  (when anthe/window-gaps-mode
    (setq tab-bar-format (append tab-bar-format '(anthe/window-gaps--bar-room))))
  (force-mode-line-update t)
  (if anthe/window-gaps-mode
      (anthe/window-gaps--colours)
    (dolist (face '(window-divider window-divider-first-pixel window-divider-last-pixel))
      (custom-theme-recalc-face face)))
  (anthe/window-gaps--refresh))

(when (display-graphic-p)
  ;; Once the top bar's items are set (anthe-bar.el)
  (add-hook 'emacs-startup-hook (lambda () (anthe/window-gaps-mode 1)) 90))

(map! :leader :desc "Gaps between windows" "t G" #'anthe/window-gaps-mode)

(provide 'anthe-windows)
;;; anthe-windows.el ends here
