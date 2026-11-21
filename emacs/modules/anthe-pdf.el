;;; anthe-pdf.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 anthe
;;
;; Author: anthe <anthe@inspiron>
;; Maintainer: anthe <anthe@inspiron>
;; Created: February 15, 2026
;; Modified: February 15, 2026
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/anthe/anthe-pdf
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:


(use-package pdf-tools
  :defer t
  ;; :commands (pdf-view-mode pdf-tools-install)
  :mode ("\\.pdf\\'" . pdf-view-mode)
  :config
  (pdf-tools-install)
  (setq-default pdf-view-display-size 'fit-height)
  :hook (pdf-view-mode . pdf-view-midnight-minor-mode))

(custom-set-faces!
  '(pdf-isearch-match :background "#ffcb6b" :foreground "#303030"))

(after! pdf-tools
  (setq pdf-view-midnight-gamma 1.0))

;; consult's previews run only these of a mode's hooks: night mode, not a white page
(after! consult
  (add-to-list 'consult-preview-allowed-hooks 'pdf-view-midnight-minor-mode))

;; Night mode in the theme's own colours: the ink is the text, the paper the
;; background as it looks.  On a translucent frame, the background lets the
;; wallpaper through and a page, an image, doesn't: its paper is then the
;; background blended with the wallpaper's mean colour, so the page and the
;; buffer around it look one colour (but where the wallpaper has a pattern).
;; Zathura, emacs-reader and nsxiv take them too.
(defvar anthe/wallpaper-colours nil
  "The mean colour of wallpapers, an alist from their file.")

(defun anthe/wallpaper-colour ()
  "The mean colour of the wallpaper feh sets (~/.fehbg), or nil."
  (when-let* ((fehbg (and (file-readable-p "~/.fehbg")
                          (with-temp-buffer (insert-file-contents "~/.fehbg") (buffer-string))))
              (file (and (string-match "--bg-[a-z]+ +'\\([^']+\\)'" fehbg) (match-string 1 fehbg)))
              ((file-readable-p file)))
    (or (alist-get file anthe/wallpaper-colours nil nil #'equal)
        (let ((mean (string-trim
                     (shell-command-to-string
                      (format "convert %s -resize 1x1! -format '#%%[hex:p{0,0}]' info: 2>/dev/null"
                              (shell-quote-argument file))))))
          (when (string-match-p "\\`#[0-9A-Fa-f]\\{6\\}" mean)
            (setf (alist-get file anthe/wallpaper-colours nil nil #'equal) (substring mean 0 7)))))))

(defun anthe/seen-background (background)
  "BACKGROUND as it looks on the selected frame, over the wallpaper."
  (let ((alpha (/ (or (frame-parameter nil 'alpha-background) 100) 100.0))
        (wallpaper (anthe/wallpaper-colour)))
    (if (or (>= alpha 1) (not wallpaper))
        background
      (apply #'color-rgb-to-hex
             (append (cl-mapcar (lambda (b w) (+ (* alpha b) (* (- 1 alpha) w)))
                                (color-name-to-rgb background) (color-name-to-rgb wallpaper))
                     '(2))))))

(defun anthe/pdf-theme-colours (&rest _)
  "Give the PDF and image viewers the colours of the theme."
  (let ((ink (face-foreground 'default nil t))
        (paper (anthe/seen-background (face-background 'default nil t))))
    (setq pdf-view-midnight-colors (cons ink paper))
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
        (when (bound-and-true-p pdf-view-midnight-minor-mode)
          (pdf-view-midnight-minor-mode 1))))
    (anthe/viewers-theme-colours ink paper)))

(add-hook 'doom-load-theme-hook #'anthe/pdf-theme-colours)
(dolist (toggle '(toggle-frame-transparency toggle-frame-transparency-100))
  (advice-add toggle :after #'anthe/pdf-theme-colours))

;;; Other viewers, as Emacs buffers: zathura and nsxiv are X windows, so EXWM
;;; buffers, with pdf-view's keys (anthe-viewers.el); emacs-reader (EMuReader,
;;; MuPDF) is in Emacs.  PDFs open in zathura, images in nsxiv; SPC k o v
;;; chooses others.

(defvar anthe/pdf-viewer 'zathura
  "How PDFs open: `pdf-tools', `zathura' or `emureader'.")

(defvar anthe/image-viewer 'nsxiv
  "How images open: `emacs' (image-mode) or `nsxiv'.")

(defvar anthe/emureader-directory "~/software/emacs-reader/"
  "Where emacs-reader is cloned and built (make).")

(defun anthe/open-outside (command)
  "Open this buffer's file with COMMAND, a list, the file appended, and drop
the buffer: the program's window shows instead, as an EXWM buffer, or the one
already showing the file (`anthe-viewers-open')."
  (let ((buffer (current-buffer)))
    (fundamental-mode)
    ;; Emptied, so a preview doesn't take it for a binary file
    (let ((inhibit-read-only t)) (erase-buffer))
    (set-buffer-modified-p nil)
    (anthe-viewers-open buffer-file-name command buffer)))

;; Its dark mode inverts the page; with a local patch to ~/software/emacs-reader
;; (render-theme.c, built with make MUPDF_VERSION=1.27.0), it can tint it instead:
;; the theme's colours, as pdf-view's midnight mode
(defun anthe/emureader-colours (args)
  "Add the theme's ink and paper to the dark mode's ARGS, as 0xRRGGBB."
  (cl-flet ((hex (colour) (string-to-number (substring colour 1) 16)))
    (if (and (/= (car args) 0) (string-prefix-p "#" (car pdf-view-midnight-colors)))
        (list (car args) (hex (car pdf-view-midnight-colors)) (hex (cdr pdf-view-midnight-colors)))
      args)))

(with-eval-after-load 'emureader-dyn
  (when (equal (cdr (func-arity 'emureader-dyn--doc-invert)) 3)
    (advice-add 'emureader-dyn--doc-invert :filter-args #'anthe/emureader-colours)))

(declare-function emureader-mode "emureader")
(declare-function emureader-dark-mode "emureader")

(define-advice pdf-view-mode (:around (fn &rest args) anthe-viewer)
  "Open the PDF with `anthe/pdf-viewer'; previews, while completing, stay in pdf-view."
  (pcase (and buffer-file-name (not (active-minibuffer-window)) anthe/pdf-viewer)
    ('zathura (anthe/open-outside '("zathura")))
    ('emureader
     (add-to-list 'load-path (expand-file-name anthe/emureader-directory))
     (require 'emureader)
     (emureader-mode)
     (emureader-dark-mode 1))
    (_ (apply fn args))))

(define-advice image-mode (:around (fn &rest args) anthe-viewer)
  "Open the image with `anthe/image-viewer'; previews stay in image-mode."
  (pcase (and buffer-file-name (not (active-minibuffer-window)) anthe/image-viewer)
    ('nsxiv (anthe/open-outside '("nsxiv" "-b")))
    (_ (apply fn args))))

(defun anthe/choose-viewers (pdf image)
  "Choose the viewer for PDFs, PDF, and for images, IMAGE."
  (interactive
   (list (intern (completing-read "PDFs in: " '("pdf-tools" "zathura" "emureader") nil t nil nil
                                  (symbol-name anthe/pdf-viewer)))
         (intern (completing-read "Images in: " '("emacs" "nsxiv") nil t nil nil
                                  (symbol-name anthe/image-viewer)))))
  (setq anthe/pdf-viewer pdf anthe/image-viewer image)
  ;; A file already visited would show its buffer again, not the new viewer
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (when (and buffer-file-name (not (buffer-modified-p)) (not (get-buffer-window buffer t))
                 (or (and (derived-mode-p 'pdf-view-mode 'emureader-mode)
                          (not (eq major-mode (alist-get pdf '((pdf-tools . pdf-view-mode)
                                                               (emureader . emureader-mode))))))
                     (and (derived-mode-p 'image-mode) (not (eq image 'emacs)))))
        (kill-buffer buffer))))
  (message "PDFs in %s, images in %s" pdf image))

(map! :leader :desc "Viewers for PDFs and images" "k o v" #'anthe/choose-viewers)

(defun anthe/pdf-open-in-zathura ()
  "Open this PDF in zathura, at this page."
  (interactive)
  (make-process :name "zathura" :noquery t
                :command (list "zathura" "-P" (number-to-string (pdf-view-current-page))
                               (expand-file-name buffer-file-name))))

(map! :map pdf-view-mode-map :localleader :desc "Open in zathura" "z" #'anthe/pdf-open-in-zathura)

;; The viewers' colours, the theme's: zathura includes ~/.config/zathura/emacs-colours
;; (rcfiles/zathura/zathurarc); nsxiv reads X resources
(defvar anthe/viewers-highlight "#C792EA"
  "The colour of zathura's search results and link numbers: Night Owl's purple.")

(defun anthe/viewers-theme-colours (ink paper)
  "Write the colours of zathura and nsxiv: INK on PAPER."
  ;; zathura's background is fully transparent: compton shows the Emacs frame
  ;; behind it.  nsxiv's can't be: it gets the paper, the background as it looks.
  (let ((rgb (mapcar (lambda (c) (round (* 255 c))) (color-name-to-rgb paper))))
    (make-directory "~/.config/zathura" t)
    (with-temp-file "~/.config/zathura/emacs-colours"
      (insert "# Written by Emacs (anthe-pdf.el) when the theme changes\n"
              (format "set default-bg \"rgba(%d,%d,%d,0)\"\n" (nth 0 rgb) (nth 1 rgb) (nth 2 rgb))
              (format "set default-fg \"%s\"\n" ink)
              (format "set recolor-lightcolor \"%s\"\n" paper)
              (format "set recolor-darkcolor \"%s\"\n" ink)
              ;; Search results in the purple, seen through: the one gone to
              ;; more; link numbers in the paper on it
              (let ((purple (mapcar (lambda (c) (round (* 255 c)))
                                    (color-name-to-rgb anthe/viewers-highlight))))
                (concat (apply #'format "set highlight-active-color \"rgba(%d,%d,%d,0.55)\"\n" purple)
                        (apply #'format "set highlight-color \"rgba(%d,%d,%d,0.25)\"\n" purple)))
              (format "set highlight-fg \"%s\"\n" paper)
              (mapconcat (lambda (part)
                           (format "set %s-bg \"%s\"\nset %s-fg \"%s\"\n" part paper part ink))
                         '("statusbar" "inputbar" "notification" "completion" "index")
                         "")))
    (when (executable-find "xrdb")
      (with-temp-buffer
        (insert (format "Nsxiv.window.background: %s\nNsxiv.window.foreground: %s\n" paper ink)
                (format "Nsxiv.bar.background: %s\nNsxiv.bar.foreground: %s\n" paper ink))
        (call-process-region (point-min) (point-max) "xrdb" nil nil nil "-merge")))))

(anthe/pdf-theme-colours)

(require 'anthe-viewers)

(provide 'anthe-pdf)
;;; anthe-pdf.el ends here
