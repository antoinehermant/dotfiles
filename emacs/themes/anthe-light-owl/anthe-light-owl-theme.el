;;; anthe-light-owl-theme.el --- Light Owl, the daytime Night Owl -*- lexical-binding: t; no-byte-compile: t; -*-
;;
;; Author: anthe
;; Source: https://github.com/sdras/night-owl-vscode-theme (Night Owl Light)
;;
;;; Commentary:
;;
;;  The colours of Sarah Drasner's "Night Owl Light" for VS Code, as a Doom
;;  theme. The light companion of anthe-night-owl, for bright rooms and the
;;  outdoors: `SPC k l l' switches between the two.
;;
;;; Code:

(require 'doom-themes)

(def-doom-theme anthe-light-owl
    "Light Owl, the daytime Night Owl."

  ;; name        default   256       16
  ((bg         '("#FBFBFB" "#ffffff" "white"        ))
   (bg-alt     '("#F0F0F0" "#eeeeee" "white"        ))
   (base0      '("#F0F0F0" "#eeeeee" "white"        ))
   (base1      '("#E8E8E8" "#e4e4e4" "brightblack"  ))
   (base2      '("#E0E0E0" "#dadada" "brightblack"  ))
   (base3      '("#D9D9D9" "#d0d0d0" "brightblack"  ))
   (base4      '("#90A7B2" "#87afaf" "brightblack"  ))
   (base5      '("#5F7E97" "#5f8787" "brightblack"  ))
   (base6      '("#4A4A5E" "#444444" "brightblack"  ))
   (base7      '("#2E2D3D" "#303030" "brightblack"  ))
   (base8      '("#111111" "#121212" "black"        ))
   (fg         '("#403F53" "#3a3a3a" "black"        ))
   (fg-alt     '("#5F7E97" "#5f8787" "brightblack"  ))

   (grey       base4)
   (red        '("#DE3D3B" "#d73a3a" "red"          ))
   (orange     '("#C96765" "#d75f5f" "brightred"    ))
   (green      '("#08916A" "#008787" "green"        ))
   (teal       '("#2AA298" "#00af87" "brightgreen"  ))
   (yellow     '("#DAAA01" "#d7af00" "yellow"       ))
   (blue       '("#4876D6" "#5f87d7" "brightblue"   ))
   (dark-blue  '("#288ED7" "#0087d7" "blue"         ))
   (magenta    '("#AA0982" "#af0087" "magenta"      ))
   (violet     '("#994CC3" "#af5fd7" "brightmagenta"))
   (cyan       '("#0C969B" "#008787" "brightcyan"   ))
   (dark-cyan  '("#2AA298" "#00af87" "cyan"         ))

   ;; face categories -- required for all themes
   (highlight      blue)
   (vertical-bar   base2)
   (selection      base2)
   (builtin        blue)
   (comments       '("#989FB1" "#949494" "brightblack"))
   (doc-comments   base5)
   (constants      red)
   (functions      blue)
   (keywords       violet)
   (methods        blue)
   (operators      cyan)
   (type           base8)
   (strings        blue)
   (variables      cyan)
   (numbers        magenta)
   (region         base2)
   (error          red)
   (warning        yellow)
   (success        green)
   (vc-modified    dark-blue)
   (vc-added       green)
   (vc-deleted     red)

   ;; custom categories
   (modeline-fg     fg)
   (modeline-fg-alt base5)
   (modeline-bg     base0)
   (modeline-bg-inactive bg))

  ;;;; Base theme face overrides
  (((font-lock-comment-face &override) :slant 'italic)
   ((font-lock-keyword-face &override) :slant 'italic)
   ((line-number &override) :foreground base4)
   ((line-number-current-line &override) :foreground fg :weight 'bold)
   (hl-line :background base0)
   (mode-line :background modeline-bg :foreground modeline-fg)
   (mode-line-inactive :background modeline-bg-inactive :foreground modeline-fg-alt)
   (mode-line-emphasis :foreground highlight)
   (vertical-border :foreground base3)
   ;;;; doom-modeline
   (doom-modeline-bar :background violet)
   ;;;; org <built-in>
   ((org-block &override) :background base0)
   ((org-block-begin-line &override) :background base0 :foreground base5)
   ((org-level-2 &override) :foreground violet)
   ;;;; solaire-mode
   (solaire-mode-line-face :inherit 'mode-line :background modeline-bg)
   (solaire-mode-line-inactive-face :inherit 'mode-line-inactive :background modeline-bg-inactive)))

;;; anthe-light-owl-theme.el ends here
