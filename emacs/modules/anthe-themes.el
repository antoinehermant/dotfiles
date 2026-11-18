;;; anthe-themes.el --- Night Owl, Light Owl and sunlight -*- lexical-binding: t; -*-
;;
;; Author: anthe
;;
;;; Commentary:
;;
;;  `SPC k l l' switches between anthe-night-owl and anthe-light-owl.
;;
;;  Sunlight raises the contrast of the current theme, for a bright office or
;;  the outdoors, where reflected light washes the dim colours out first:
;;  comments, line numbers, muted text, and the region and current line
;;  backgrounds. `SPC k l +' raises it a level, `-' lowers it, `0' turns it
;;  off; after the first key, `+', `-' and `0' go on without the prefix.
;;
;;  Each level asks more contrast against the background: the dim colours
;;  move towards the theme's own text colour (towards white or black if
;;  that is not enough), the highlight backgrounds away from the
;;  background. The theme's colours stay as they are above the target. It
;;  works with any theme, dark or light, and survives a theme switch.
;;
;;; Code:

(require 'color)

(add-to-list 'custom-theme-load-path "~/.dotfiles/emacs/themes/anthe-light-owl/")

(defun anthe/owl-toggle ()
  "Switch between anthe-night-owl and anthe-light-owl."
  (interactive)
  (let ((theme (if (memq 'anthe-light-owl custom-enabled-themes)
                   'anthe-night-owl
                 'anthe-light-owl)))
    (setq doom-theme theme)
    (load-theme theme t)
    (message "Theme: %s" theme)))

;;; Sunlight

(defvar anthe/sunlight-level 0
  "How much sunlight raises the contrast, from 0 (off) to `anthe/sunlight-max'.")

(defconst anthe/sunlight-max 6)

(defun anthe/sunlight-text-contrast (level)
  "The contrast text should reach at LEVEL: 4.5:1 at 1, 10.75:1 at 6."
  (+ 4.5 (* 1.25 (1- level))))

(defun anthe/sunlight-background-contrast (level)
  "The contrast a highlight background should reach against the background."
  (+ 1.3 (* 0.2 level)))

(defvar anthe/sunlight-backgrounds
  '(region hl-line highlight secondary-selection lazy-highlight isearch
    show-paren-match vertico-current corfu-current completions-highlight
    magit-section-highlight mode-line mode-line-active)
  "Faces whose background sunlight moves away from the background.")

(defvar anthe/sunlight--saved nil
  "The (FACE ATTRIBUTE . VALUE) sunlight changed, to put back.")

(defun anthe/sunlight--luminance (rgb)
  (apply #'+ (cl-mapcar (lambda (c w)
                          (* w (if (<= c 0.03928) (/ c 12.92)
                                 (expt (/ (+ c 0.055) 1.055) 2.4))))
                        rgb '(0.2126 0.7152 0.0722))))

(defun anthe/sunlight--contrast (a b)
  (let ((la (anthe/sunlight--luminance a))
        (lb (anthe/sunlight--luminance b)))
    (/ (+ (max la lb) 0.05) (+ (min la lb) 0.05))))

(defun anthe/sunlight--blend (from to n)
  (cl-mapcar (lambda (a b) (+ a (* n (- b a)))) from to))

(defun anthe/sunlight--towards (rgb against target poles)
  "Move RGB towards the first of POLES that gets TARGET contrast with AGAINST.
Moves as little as needed; nil if RGB already has it."
  (unless (>= (anthe/sunlight--contrast rgb against) target)
    (let ((pole (or (seq-find (lambda (p) (>= (anthe/sunlight--contrast p against) target))
                              poles)
                    (car (last poles))))
          (lo 0.0) (hi 1.0))
      (dotimes (_ 12)
        (let ((mid (/ (+ lo hi) 2)))
          (if (>= (anthe/sunlight--contrast (anthe/sunlight--blend rgb pole mid) against) target)
              (setq hi mid)
            (setq lo mid))))
      (apply #'color-rgb-to-hex (append (anthe/sunlight--blend rgb pole hi) '(2))))))

(defun anthe/sunlight--rgb (face attribute)
  "FACE's own ATTRIBUTE colour as a list of floats, or nil."
  (let ((c (face-attribute face attribute nil nil)))
    (and (stringp c) (not (string-prefix-p "unspecified" c)) (color-name-to-rgb c))))

(defun anthe/sunlight--set (face attribute value)
  (unless (assoc (cons face attribute) anthe/sunlight--saved)
    (push (cons (cons face attribute) (face-attribute face attribute nil nil))
          anthe/sunlight--saved))
  (set-face-attribute face nil attribute value))

(defun anthe/sunlight--restore ()
  (pcase-dolist (`((,face . ,attribute) . ,value) anthe/sunlight--saved)
    (when (facep face) (set-face-attribute face nil attribute value)))
  (setq anthe/sunlight--saved nil))

(defun anthe/sunlight--apply ()
  "Raise the contrast of the current faces to `anthe/sunlight-level'."
  (anthe/sunlight--restore)
  (let ((bg (anthe/sunlight--rgb 'default :background))
        (fg (anthe/sunlight--rgb 'default :foreground))
        (level anthe/sunlight-level))
    (when (and bg fg (> level 0))
      (let* ((dark (< (anthe/sunlight--luminance bg) 0.18))
             (light-pole (if dark '(1.0 1.0 1.0) '(0.0 0.0 0.0)))
             (text (anthe/sunlight-text-contrast level))
             (backgrounds (anthe/sunlight-background-contrast level)))
        ;; The highlight backgrounds first, the text is then checked on them
        (dolist (face anthe/sunlight-backgrounds)
          (when-let* (((facep face))
                      (rgb (anthe/sunlight--rgb face :background))
                      ((> (anthe/sunlight--contrast rgb bg) 1.01))
                      (new (anthe/sunlight--towards rgb bg backgrounds (list fg))))
            (anthe/sunlight--set face :background new)))
        (dolist (face (face-list))
          (when-let* (((not (eq face 'default)))
                      ((not (eq (face-attribute face :inverse-video nil nil) t)))
                      (rgb (anthe/sunlight--rgb face :foreground))
                      (on (or (anthe/sunlight--rgb face :background) bg))
                      (new (anthe/sunlight--towards rgb on text (list fg light-pole))))
            (anthe/sunlight--set face :foreground new)))))))

(defvar anthe/sunlight-repeat-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "+") #'anthe/sunlight-raise)
    (define-key map (kbd "=") #'anthe/sunlight-raise)
    (define-key map (kbd "-") #'anthe/sunlight-lower)
    (define-key map (kbd "0") #'anthe/sunlight-off)
    map)
  "Keys that go on changing sunlight after `SPC k l +' or `-'.")

(defun anthe/sunlight-set (level)
  "Set sunlight to LEVEL, from 0 (off) to `anthe/sunlight-max'."
  (setq anthe/sunlight-level (max 0 (min anthe/sunlight-max level)))
  (anthe/sunlight--apply)
  (set-transient-map anthe/sunlight-repeat-map t)
  (message "Sunlight %d/%d   + more, - less, 0 off" anthe/sunlight-level anthe/sunlight-max))

(defun anthe/sunlight-raise ()
  "Raise the contrast a level, for bright light."
  (interactive)
  (anthe/sunlight-set (1+ anthe/sunlight-level)))

(defun anthe/sunlight-lower ()
  "Lower the contrast a level."
  (interactive)
  (anthe/sunlight-set (1- anthe/sunlight-level)))

(defun anthe/sunlight-off ()
  "Put the theme's own colours back."
  (interactive)
  (anthe/sunlight-set 0))

;; A theme load puts its own faces back: sunlight starts again from them
(add-hook 'doom-load-theme-hook
          (defun anthe/sunlight-reapply-h ()
            (setq anthe/sunlight--saved nil)
            (anthe/sunlight--apply)))

(map! :leader
      (:prefix ("k l" . "light and themes")
       :desc "Night Owl / Light Owl" "l" #'anthe/owl-toggle
       :desc "Sunlight: more contrast" "+" #'anthe/sunlight-raise
       :desc "Sunlight: more contrast" "=" #'anthe/sunlight-raise
       :desc "Sunlight: less contrast" "-" #'anthe/sunlight-lower
       :desc "Sunlight off" "0" #'anthe/sunlight-off
       :desc "Load a theme" "t" #'consult-theme))

(provide 'anthe-themes)
;;; anthe-themes.el ends here
