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

;; The dividers widened into gaps, as see-through as the windows (the
;; wallpaper blurred behind, picom), a faint line along each window's edge
(defvar anthe/window-gap 12
  "Pixels between two windows, with `anthe/window-gaps-mode'.")

(defun anthe/window-gaps--colours (&rest _)
  "Colour the gaps after the theme: its background, faint edges."
  (when anthe/window-gaps-mode
    (let* ((background (face-attribute 'default :background nil t))
           (border (face-attribute 'vertical-border :foreground nil 'default))
           (edge (if (and (color-defined-p background) (color-defined-p border))
                     (apply #'color-rgb-to-hex
                            (append (cl-mapcar (lambda (b f) (+ b (* 0.35 (- f b))))
                                               (color-name-to-rgb background)
                                               (color-name-to-rgb border))
                                    '(2)))
                   border)))
      (set-face-attribute 'window-divider nil :foreground background)
      (set-face-attribute 'window-divider-first-pixel nil :foreground edge)
      (set-face-attribute 'window-divider-last-pixel nil :foreground edge))))

(define-minor-mode anthe/window-gaps-mode
  "Gaps between the windows, the wallpaper showing through."
  :global t
  (let ((width (if anthe/window-gaps-mode anthe/window-gap 1)))
    (setq window-divider-default-right-width width
          window-divider-default-bottom-width width)
    (when window-divider-mode
      (window-divider-mode 1)))
  (if anthe/window-gaps-mode
      (progn (add-hook 'doom-load-theme-hook #'anthe/window-gaps--colours)
             (anthe/window-gaps--colours))
    (remove-hook 'doom-load-theme-hook #'anthe/window-gaps--colours)
    (dolist (face '(window-divider window-divider-first-pixel window-divider-last-pixel))
      (custom-theme-recalc-face face))))

(when (display-graphic-p)
  (anthe/window-gaps-mode 1))

(map! :leader :desc "Gaps between windows" "t G" #'anthe/window-gaps-mode)

(provide 'anthe-windows)
;;; anthe-windows.el ends here
