;;; anthe-transparency.el --- How see-through Emacs is -*- lexical-binding: t; -*-
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  The frames' background is see-through (alpha-background): the text stays
;;  opaque, and under EXWM picom blurs the wallpaper behind
;;  (rcfiles/picom/picom.conf), the top bar kept less see-through by a shader
;;  there (emacs-bar.frag).
;;
;;  SPC t t, then + and - without the prefix: more or less see-through, 10 %
;;  a step; 0 opaque, or back.  Any other key leaves.
;;
;;; Code:

(defvar anthe/transparency 15
  "How see-through the frames' background is, in percent (0: opaque).")

(defvar anthe/transparency-step 10
  "Percent a step of `anthe/transparency-adjust'.")

(defvar anthe/transparency--before nil
  "The transparency before 0 made the frames opaque.")

(defun anthe/transparency--frames ()
  (if (bound-and-true-p exwm-workspace--list)
      (seq-filter #'frame-live-p exwm-workspace--list)
    (frame-list)))

(defun anthe/transparency-set (percent)
  "Make the frames' background PERCENT see-through, 0 to 90."
  (setq anthe/transparency (max 0 (min 90 percent)))
  (let ((alpha (- 100 anthe/transparency)))
    (setf (alist-get 'alpha-background default-frame-alist) alpha)
    (dolist (frame (anthe/transparency--frames))
      (set-frame-parameter frame 'alpha-background alpha))))

(defun anthe/transparency--show ()
  (message "Transparency %d %%   + more, - less, 0 %s"
           anthe/transparency (if anthe/transparency--before "back" "opaque")))

(defun anthe/transparency-more ()
  "More see-through, by `anthe/transparency-step'."
  (interactive)
  (setq anthe/transparency--before nil)
  (anthe/transparency-set (+ anthe/transparency anthe/transparency-step))
  (anthe/transparency--show))

(defun anthe/transparency-less ()
  "Less see-through, by `anthe/transparency-step'."
  (interactive)
  (setq anthe/transparency--before nil)
  (anthe/transparency-set (- anthe/transparency anthe/transparency-step))
  (anthe/transparency--show))

(defun anthe/transparency-opaque ()
  "Opaque, or back to the transparency before."
  (interactive)
  (if anthe/transparency--before
      (progn (anthe/transparency-set anthe/transparency--before)
             (setq anthe/transparency--before nil))
    (setq anthe/transparency--before (max anthe/transparency anthe/transparency-step))
    (anthe/transparency-set 0))
  (anthe/transparency--show))

(defvar anthe/transparency-repeat-map
  (let ((map (make-sparse-keymap)))
    (define-key map "+" #'anthe/transparency-more)
    (define-key map "=" #'anthe/transparency-more)
    (define-key map "-" #'anthe/transparency-less)
    (define-key map "0" #'anthe/transparency-opaque)
    map)
  "Keys after SPC t t, without the prefix.")

(defun anthe/transparency-adjust ()
  "Adjust the transparency: + and - then, 0 opaque or back."
  (interactive)
  (anthe/transparency--show)
  (set-transient-map anthe/transparency-repeat-map t))

(anthe/transparency-set anthe/transparency)

(map! :leader :desc "Transparency (+ - 0)" "t t" #'anthe/transparency-adjust)

(provide 'anthe-transparency)
;;; anthe-transparency.el ends here
