;;; anthe-wallpaper.el --- The wallpaper, a clock on it -*- lexical-binding: t; -*-
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  A desktop as other window managers have: SPC k w shows the *wallpaper*
;;  buffer, whose window is cut out of the frame as the gaps are
;;  (anthe-windows.el), all but a card in its middle with the time, the date
;;  and the next event.  The card is as see-through as Emacs, its corners
;;  rounded.  Without the gaps (SPC t G), the window shows as any other.
;;
;;; Code:

(defvar anthe-wallpaper-buffer-name "*wallpaper*")

(defvar anthe-wallpaper-padding 28
  "Pixels of the card around its text.")

(defface anthe-wallpaper-time '((t :height 4.0 :weight light))
  "The time on the wallpaper.")

(defface anthe-wallpaper-date '((t :height 1.3))
  "The date on the wallpaper.")

(defvar-local anthe-wallpaper--start nil
  "Where the card's text starts, after the room above it.")

(defvar anthe-wallpaper--timer nil)

(define-derived-mode anthe-wallpaper-mode special-mode "Wallpaper"
  "The wallpaper, a clock on it."
  (setq-local mode-line-format nil
              header-line-format nil
              cursor-type nil
              cursor-in-non-selected-windows nil
              truncate-lines t)
  (add-hook 'window-size-change-functions #'anthe-wallpaper--draw nil t))

(defun anthe-wallpaper--lines ()
  "The card's lines: the time, the date, and the next event, if any."
  (delq nil
        (list (propertize (format-time-string "%H:%M") 'face 'anthe-wallpaper-time)
              (propertize (format-time-string "%A %-d %B") 'face 'anthe-wallpaper-date)
              (and (fboundp 'anthe-dashboard--next-event)
                   (ignore-errors (anthe-dashboard--next-event))))))

(defun anthe-wallpaper--draw (&rest _)
  "Draw the card, centred in the first window showing it."
  (when-let* ((buffer (get-buffer anthe-wallpaper-buffer-name)))
    (with-current-buffer buffer
      (let ((inhibit-read-only t)
            (window (get-buffer-window buffer t)))
        (erase-buffer)
        (dolist (line (anthe-wallpaper--lines))
          ;; Each line centred
          (insert (propertize " " 'display
                              `(space :align-to (- center (,(/ (string-pixel-width line) 2)))))
                  line "\n"))
        ;; After the room above, inserted before it
        (setq anthe-wallpaper--start (copy-marker (point-min) t))
        (when window
          ;; The room above, so that the card is in the window's middle
          (let ((height (cdr (window-text-pixel-size window (point-min) (point-max)))))
            (goto-char (point-min))
            (insert (propertize "\n" 'line-height
                                (max 1 (/ (- (window-body-height window t) height) 2)))))
          (set-window-start window (point-min) t))
        (goto-char (point-min)))))
  (when (fboundp 'anthe/window-gaps--update)
    (anthe/window-gaps--update)))

(defun anthe-wallpaper-p (window)
  "Return non-nil if WINDOW shows the wallpaper."
  (eq (buffer-local-value 'major-mode (window-buffer window)) 'anthe-wallpaper-mode))

(defun anthe-wallpaper--card (window)
  "The card in WINDOW, (LEFT TOP RIGHT BOTTOM) in its frame's pixels."
  (with-current-buffer (window-buffer window)
    (when-let* ((anthe-wallpaper--start)
                (top-left (pos-visible-in-window-p anthe-wallpaper--start window t)))
      (pcase-let* ((`(,left ,top ,right ,_) (window-body-pixel-edges window))
                   (`(,width . ,height) (window-text-pixel-size
                                         window anthe-wallpaper--start (point-max)))
                   (pad anthe-wallpaper-padding)
                   ;; The lines are centred: as much room left as right
                   (from (- (- right left) width))
                   (y (+ top (cadr top-left))))
        (list (+ left from (- pad)) (- y pad)
              (+ left width pad) (+ y height pad))))))

(defun anthe-wallpaper--tick ()
  "Draw the card again, while the wallpaper shows."
  (if (get-buffer-window anthe-wallpaper-buffer-name t)
      (anthe-wallpaper--draw)
    (cancel-timer anthe-wallpaper--timer)
    (setq anthe-wallpaper--timer nil)))

(defun anthe-wallpaper ()
  "Show the wallpaper in this window, a clock on it."
  (interactive)
  (let ((buffer (get-buffer-create anthe-wallpaper-buffer-name)))
    (with-current-buffer buffer
      (unless (derived-mode-p 'anthe-wallpaper-mode)
        (anthe-wallpaper-mode)))
    (switch-to-buffer buffer)
    (anthe-wallpaper--draw)
    (unless (timerp anthe-wallpaper--timer)
      ;; On the minute
      (setq anthe-wallpaper--timer
            (run-at-time (- 60 (mod (float-time) 60)) 60 #'anthe-wallpaper--tick)))))

(map! :leader :desc "Wallpaper (a clock on it)" "k w" #'anthe-wallpaper)

(provide 'anthe-wallpaper)
;;; anthe-wallpaper.el ends here
