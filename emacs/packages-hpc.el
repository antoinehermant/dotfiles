;; -*- no-byte-compile: t; -*-
;;; packages-hpc.el

;; The packages of the HPC (UBELIX), where ~/.config/doom/packages.el links
;; here: those of the laptop's packages.el that its modules use there. Left
;; out: the desktop (exwm, xelb, desktop-environment), calendars and contacts
;; (org-caldav, khalel, khardel, org-vcard, org-wild-notifier, alert), the
;; dashboard, tldr, night-owl-theme (anthe-night-owl is in the dotfiles).
;; Run `doomc sync' after a change.

(package! ws-butler)
(package! solaire-mode :disable t)
(package! code-cells)
(package! popper)
(package! f)
(package! pkg-info)
(package! exec-path-from-shell)
(package! cape)

;; Claude in agent-shell (anthe-agents.el), as on the laptop
(package! shell-maker)
(package! acp)
(package! agent-shell)
