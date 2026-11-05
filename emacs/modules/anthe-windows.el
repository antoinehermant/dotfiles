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

(provide 'anthe-windows)
;;; anthe-windows.el ends here
