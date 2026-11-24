;;; anthe-wallpaper.el --- The wallpaper, the dashboard's header on it -*- lexical-binding: t; -*-
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  A desktop as other window managers have: SPC k w shows the *wallpaper*
;;  buffer, whose window is cut out of the frame as the gaps are
;;  (anthe-windows.el), all but a card in its top left corner: the
;;  dashboard's header (the planet, the greeting, the day's overview), as
;;  see-through as Emacs, its corners rounded, drawn again every minute.
;;  Without the gaps (SPC t G), the window shows as any other.
;;
;;; Code:

(require 'anthe-dashboard)

(defvar anthe-wallpaper-buffer-name "*wallpaper*")

(defvar anthe-wallpaper-top 8
  "Pixels above the card.")

(defvar anthe-wallpaper--timer nil)

(defun anthe-wallpaper--cards (window)
  (anthe/window-cards window 'anthe-dashboard-card))

(define-derived-mode anthe-wallpaper-mode special-mode "Wallpaper"
  "The wallpaper, the dashboard's header on it."
  (setq-local mode-line-format nil
              header-line-format nil
              cursor-type nil
              cursor-in-non-selected-windows nil
              truncate-lines t
              anthe/window-cards-function #'anthe-wallpaper--cards)
  (add-hook 'window-size-change-functions #'anthe-wallpaper--draw nil t))

(defun anthe-wallpaper--width (lines)
  "The columns LINES of the header take, drawn at column 0: the column its
aligning space reaches, and the text after it."
  (apply #'max 0
         (mapcar (lambda (line)
                   (if-let* ((at (text-property-not-all 0 (length line) 'display nil line))
                             (to (plist-get (cdr (get-text-property at 'display line)) :align-to)))
                       ;; (+ (- center HALF) COLUMN)
                       (+ (nth 2 to) (anthe-dashboard--columns (substring line (1+ at))))
                     (anthe-dashboard--columns line)))
                 lines)))

(defun anthe-wallpaper--draw (&rest _)
  "Draw the header card in the top left corner of the window showing it."
  (when-let* ((buffer (get-buffer anthe-wallpaper-buffer-name)))
    (with-current-buffer buffer
      (let* ((inhibit-read-only t)
             (window (get-buffer-window buffer t))
             (columns (if window (window-max-chars-per-line window) (frame-width)))
             ;; The cards' column 0 at the window's left
             (anthe-dashboard--half (/ columns 2.0))
             (tasks (anthe-dashboard--tasks))
             (width (min columns
                         (+ 4 (let ((anthe-dashboard--origin 0))
                                (anthe-wallpaper--width (anthe-dashboard--header columns tasks)))))))
        (erase-buffer)
        (insert (propertize "\n" 'line-height anthe-wallpaper-top)
                (string-join (anthe-dashboard--row
                              (list 'header 0 width
                                    (lambda () (anthe-dashboard--header (- width 4) tasks))))
                             "\n")
                "\n")
        (goto-char (point-min))
        (when window
          (set-window-start window (point-min) t)))))
  (when (fboundp 'anthe/window-gaps--update)
    (anthe/window-gaps--update)))

(defun anthe-wallpaper--tick ()
  "Draw the card again, while the wallpaper shows."
  (if (get-buffer-window anthe-wallpaper-buffer-name t)
      (anthe-wallpaper--draw)
    (cancel-timer anthe-wallpaper--timer)
    (setq anthe-wallpaper--timer nil)))

(defun anthe-wallpaper ()
  "Show the wallpaper in this window, the dashboard's header on it."
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

(map! :leader :desc "Wallpaper (the header on it)" "k w" #'anthe-wallpaper)

(provide 'anthe-wallpaper)
;;; anthe-wallpaper.el ends here
