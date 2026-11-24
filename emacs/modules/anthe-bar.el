;;; anthe-bar.el --- A top bar for EXWM -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  A status bar at the top of each EXWM workspace, like a desktop's: the
;;  Doom workspaces on the left, the current one highlighted (a click
;;  switches), the date and time in the middle (a click opens the calendar),
;;  and on the right how much of Claude's session is used (a click tells
;;  the rest, anthe-agents.el),
;;  the processors and memory used (a click opens proced),
;;  the USB drives plugged in (a click opens a menu to open or eject them),
;;  Bluetooth (a click opens a menu to turn it on or off and to connect the
;;  paired devices), the network, caffeine (a cup: a click keeps the
;;  screen on, exwm-desktop.el) and the battery.
;;
;;  It is Emacs's own tab bar, shown on the EXWM workspaces only, not on
;;  floating windows.  While it shows, the time and the battery leave the
;;  mode line.  SPC t B hides or shows it.
;;
;;; Code:

(require 'tab-bar)
(require 'dbus)
(require 'battery)
(require 'ansi-color)
(require 'nerd-icons)

(defvar anthe-bar-shown t
  "Whether the bar shows; `anthe-bar-toggle' switches it.")

(defvar anthe-bar-interval 5
  "Seconds between two looks at the system, Bluetooth, the network and the battery.")

(defvar anthe-bar--status nil
  "The right side of the bar, a list of (TEXT HELP [COMMAND]), from the last look.")

(defvar anthe-bar--timer nil)

(defface anthe-bar-clock '((t :weight bold))
  "The date and time in the bar.")

;; The workspaces: the others on the bar's own background, the current one
;; highlighted. To change them, in config-local.el for instance:
;;   (custom-set-faces! '(anthe-bar-current-workspace :background "#7e57c2" :foreground "white"))
(defface anthe-bar-workspace '((t nil))
  "The workspaces other than the current one, in the bar.")

(defface anthe-bar-current-workspace '((t :inherit highlight :weight bold))
  "The current workspace, in the bar.")

(defun anthe-bar--on-bar (items)
  "ITEMS with the bar's face under their own: text without a background of
its own would take the default one, not the bar's."
  (mapcar (lambda (item)
            (let ((text (copy-sequence (nth 2 item))))
              (add-face-text-property 0 (length text) 'tab-bar t text)
              (append (list (car item) (cadr item) text) (nthcdr 3 item))))
          items))

;;; Left: the workspaces

(defun anthe-bar--workspaces ()
  "The Doom workspaces of this frame's monitor, the current one highlighted."
  (when (fboundp '+workspace-list-names)
    (let ((current (+workspace-current-name)))
      (seq-map-indexed
       (lambda (name i)
         ;; The current one's key differs: the tab bar is redrawn only when
         ;; its items change, compared without their faces
         `(,(intern (format (if (equal name current)
                                "anthe-bar-current-workspace-%d"
                              "anthe-bar-workspace-%d")
                            i))
           menu-item
           ,(propertize (format " %d %s " (1+ i) name)
                        'face (if (equal name current)
                                  'anthe-bar-current-workspace
                                'anthe-bar-workspace))
           ,(lambda () (interactive) (+workspace/switch-to name))
           :help ,(format "Switch to %s" name)))
       (if (fboundp 'anthe-workspaces-names)
           (anthe-workspaces-names)
         (+workspace-list-names))))))

;;; Middle: the date and time

(defun anthe-bar--clock ()
  "The date and time, centred."
  (let* ((time (propertize (format-time-string "%a %-d %b  %H:%M")
                           'face 'anthe-bar-clock))
         (half (/ (string-pixel-width (propertize time 'face '(anthe-bar-clock tab-bar))) 2)))
    `((anthe-bar-centre menu-item
       ,(propertize " " 'display `(space :align-to (- center (,half))))
       ignore)
      (anthe-bar-clock menu-item ,time calendar
       :help ,(format-time-string "%A %-d %B %Y, week %V")))))

;;; Right: the system, Bluetooth, the network, the battery

(defun anthe-bar--icon (name &optional face)
  (nerd-icons-mdicon name :face face :v-adjust 0.0))

(defun anthe-bar--bluez ()
  "The Bluetooth adapter's properties, nil without one, and the paired
devices as (PATH DEVICE BATTERY), each an alist of properties."
  (let ((objects (dbus-get-all-managed-objects :system "org.bluez" "/")))
    (cons (seq-some (lambda (o) (cadr (assoc "org.bluez.Adapter1" (cadr o)))) objects)
          (delq nil
                (mapcar (lambda (o)
                          (let ((device (cadr (assoc "org.bluez.Device1" (cadr o)))))
                            (when (cdr (assoc "Paired" device))
                              (list (car o) device
                                    (cadr (assoc "org.bluez.Battery1" (cadr o)))))))
                        objects)))))

(defun anthe-bar--device-name (device battery)
  (concat (cdr (assoc "Alias" device))
          (when battery (format " %d%%" (cdr (assoc "Percentage" battery))))))

(defun anthe-bar--bluetooth ()
  "Off, on, or connected: the headphones by name with their battery, the
keyboard and mouse only in the help.  A click opens `anthe-bar-bluetooth-menu'."
  (pcase-let* ((`(,adapter . ,paired) (anthe-bar--bluez))
               (connected (seq-filter (lambda (d) (cdr (assoc "Connected" (nth 1 d)))) paired))
               (audio (seq-filter (lambda (d) (string-prefix-p "audio" (or (cdr (assoc "Icon" (nth 1 d))) "")))
                                  connected))
               (names (lambda (devices)
                        (string-join (mapcar (lambda (d) (apply #'anthe-bar--device-name (cdr d))) devices)
                                     ", "))))
    (cond
     ((not adapter) nil)
     ((not (cdr (assoc "Powered" adapter)))
      (list (anthe-bar--icon "nf-md-bluetooth_off" 'shadow) "Bluetooth off" #'anthe-bar-bluetooth-menu))
     (connected
      (list (concat (anthe-bar--icon "nf-md-bluetooth_connect")
                    (when audio (concat " " (funcall names audio))))
            (concat "Bluetooth: " (funcall names connected))
            #'anthe-bar-bluetooth-menu))
     (t (list (anthe-bar--icon "nf-md-bluetooth") "Bluetooth on, nothing connected"
              #'anthe-bar-bluetooth-menu)))))

(defun anthe-bar--bluetoothctl (&rest args)
  "Run bluetoothctl with ARGS in the background, its last line in the echo
area, and look again once done.  Connecting can take a while, or hang."
  (let ((buffer (generate-new-buffer " *bluetoothctl*")))
    (make-process
     :name "bluetoothctl" :buffer buffer :noquery t :connection-type 'pipe
     :command `("timeout" "20" "bluetoothctl" ,@args)
     :sentinel (lambda (process _event)
                 (unless (process-live-p process)
                   (let ((lines (split-string (ansi-color-filter-apply
                                               (with-current-buffer buffer (buffer-string)))
                                              "\n" t "[ \t\r]+")))
                     (message "Bluetooth: %s"
                              (if (eq (process-exit-status process) 124) "no answer"
                                (car (last lines)))))
                   (kill-buffer buffer)
                   (anthe-bar--look))))))

(defun anthe-bar-bluetooth-menu ()
  "A menu to turn Bluetooth on or off, and to connect or disconnect the
paired devices, the connected ones ticked."
  (interactive)
  (pcase-let* ((`(,adapter . ,paired) (anthe-bar--bluez))
               (powered (cdr (assoc "Powered" adapter))))
    (unless adapter (user-error "No Bluetooth adapter"))
    (popup-menu
     `("Bluetooth"
       [,(if powered "Turn Bluetooth off" "Turn Bluetooth on")
        (anthe-bar--bluetoothctl "power" ,(if powered "off" "on"))]
       "--"
       ,@(mapcar (pcase-lambda (`(,_path ,device ,battery))
                   (let ((connected (cdr (assoc "Connected" device))))
                     (vector (anthe-bar--device-name device battery)
                             `(anthe-bar--bluetoothctl ,(if connected "disconnect" "connect")
                                                       ,(cdr (assoc "Address" device)))
                             :style 'toggle :selected connected :active powered)))
                 (sort paired :key (lambda (d) (cdr (assoc "Alias" (nth 1 d))))))))))

;;; The system: processors and memory

(defvar anthe-bar--cpu nil
  "The processors' (BUSY . TOTAL) time at the last look, from /proc/stat.")

(defun anthe-bar--proc (file)
  (with-temp-buffer (insert-file-contents file) (buffer-string)))

(defun anthe-bar--system ()
  "How busy the processors were since the last look, and the memory used."
  (let* ((times (mapcar #'string-to-number
                        (seq-take (cdr (split-string (car (split-string (anthe-bar--proc "/proc/stat") "\n"))))
                                  8)))
         (idle (+ (nth 3 times) (nth 4 times)))
         (total (apply #'+ times))
         (cpu (and anthe-bar--cpu (> total (cdr anthe-bar--cpu))
                   (/ (* 100.0 (- total idle (car anthe-bar--cpu)))
                      (- total (cdr anthe-bar--cpu)))))
         (memory (anthe-bar--proc "/proc/meminfo"))
         (kib (lambda (name)
                (string-match (concat "^" name ": *\\([0-9]+\\)") memory)
                (string-to-number (match-string 1 memory))))
         (memory-total (funcall kib "MemTotal"))
         (memory-used (- memory-total (funcall kib "MemAvailable")))
         (ram (/ (* 100.0 memory-used) memory-total))
         (face (lambda (percent) (cond ((>= percent 90) 'error) ((>= percent 75) 'warning)))))
    (setq anthe-bar--cpu (cons (- total idle) total))
    (list (concat (anthe-bar--icon "nf-md-chip" (and cpu (funcall face cpu)))
                  (propertize (if cpu (format " %d%%" cpu) " –") 'face (and cpu (funcall face cpu)))
                  "  "
                  (anthe-bar--icon "nf-md-memory" (funcall face ram))
                  (propertize (format " %d%%" ram) 'face (funcall face ram)))
          (format "Processors %s, load %s\nMemory %.1f of %.1f GiB used"
                  (if cpu (format "%d%% busy" cpu) "–")
                  (mapconcat (lambda (load) (format "%.2f" load)) (load-average t) " ")
                  (/ memory-used 1048576.0) (/ memory-total 1048576.0))
          #'proced)))

(defun anthe-bar--nm (path interface property)
  (dbus-get-property :system "org.freedesktop.NetworkManager" path
                     (concat "org.freedesktop.NetworkManager" interface) property))

(defun anthe-bar--network ()
  "The connection used, its Wi-Fi strength, and a VPN if one is on."
  (let* ((primary (anthe-bar--nm "/org/freedesktop/NetworkManager" "" "PrimaryConnection"))
         (connected (and primary (not (equal primary "/"))))
         (type (and connected (anthe-bar--nm primary ".Connection.Active" "Type")))
         (name (and connected (anthe-bar--nm primary ".Connection.Active" "Id")))
         (vpn (seq-some
               (lambda (path)
                 (or (anthe-bar--nm path ".Connection.Active" "Vpn")
                     (equal (anthe-bar--nm path ".Connection.Active" "Type") "wireguard")))
               (anthe-bar--nm "/org/freedesktop/NetworkManager" "" "ActiveConnections")))
         (link
          (cond
           ((not connected)
            (list (anthe-bar--icon "nf-md-wifi_off" 'warning) "Offline"))
           ((equal type "802-11-wireless")
            (let* ((ap (anthe-bar--nm primary ".Connection.Active" "SpecificObject"))
                   (strength (or (ignore-errors (anthe-bar--nm ap ".AccessPoint" "Strength")) 100)))
              (list (concat (anthe-bar--icon (format "nf-md-wifi_strength_%d"
                                                     (max 1 (min 4 (ceiling strength 25)))))
                            " " name)
                    (format "Wi-Fi %s, %d%%" name strength))))
           (t (list (anthe-bar--icon "nf-md-ethernet") (format "Wired: %s" name))))))
    (if vpn
        (list (concat (anthe-bar--icon "nf-md-vpn" 'success) " " (car link))
              (concat (cadr link) ", VPN on"))
      link)))

(defun anthe-bar--sentence (text)
  "TEXT, like \"fully-charged\", as \"Fully charged\"."
  (let ((text (string-replace "-" " " (or text ""))))
    (if (string-empty-p text) text
      (concat (upcase (substring text 0 1)) (substring text 1)))))

(defun anthe-bar--battery ()
  "The battery's charge, charging or not, and the time left."
  (let* ((status (funcall battery-status-function))
         (percent (string-to-number (or (alist-get ?p status) "")))
         (state (alist-get ?B status))
         (charging (member state '("charging" "fully-charged" "pending-charge")))
         (tens (* 10 (max 1 (min 10 (round percent 10)))))
         (icon (cond (charging (format "nf-md-battery_charging_%d" tens))
                     ((= tens 100) "nf-md-battery")
                     (t (format "nf-md-battery_%d" tens))))
         (face (cond (charging nil)
                     ((<= percent 10) 'error)
                     ((<= percent 20) 'warning)))
         (time (alist-get ?t status))
         (mode (anthe-bar--power-mode)))
    (when (alist-get ?p status)
      (list (concat (pcase mode
                      ;; Balanced, the usual, goes without saying
                      ("power-saver" (concat (anthe-bar--icon "nf-md-leaf" 'success) " "))
                      ("performance" (concat (anthe-bar--icon "nf-md-rocket_launch" 'warning) " ")))
                    (anthe-bar--icon icon face) " "
                    (propertize (format "%d%%" percent) 'face face))
            (concat (anthe-bar--sentence state)
                    (unless (member time '(nil "" "0:00" "N/A"))
                      (format ", %s %s" time (if charging "to full" "left")))
                    (when mode
                      (format "\nPower mode: %s" (alist-get mode anthe-bar--power-modes nil nil #'equal))))
            (and mode #'anthe-bar-power-menu)))))

;;; Power mode (power-profiles-daemon): SPC k e, or the battery's menu

(defconst anthe-bar--power-modes
  '(("power-saver" . "Power saver")
    ("balanced" . "Balanced")
    ("performance" . "Performance"))
  "The power modes, by power-profiles-daemon's name.")

(defun anthe-bar--power-mode ()
  "The power mode on, nil without power-profiles-daemon."
  (ignore-errors
    (dbus-get-property :system "org.freedesktop.UPower.PowerProfiles"
                       "/org/freedesktop/UPower/PowerProfiles"
                       "org.freedesktop.UPower.PowerProfiles" "ActiveProfile")))

(defun anthe-power-mode-set (mode)
  "Switch to the power MODE, asked in the minibuffer."
  (interactive
   (let* ((current (anthe-bar--power-mode))
          (choices (mapcar (lambda (mode)
                             (cons (concat (cdr mode) (when (equal (car mode) current) " (on)"))
                                   (car mode)))
                           anthe-bar--power-modes)))
     (unless current (user-error "No power modes: power-profiles-daemon isn't running"))
     (list (cdr (assoc (completing-read "Power mode: " choices nil t) choices)))))
  (let ((buffer (generate-new-buffer " *powerprofilesctl*")))
    (make-process
     :name "powerprofilesctl" :buffer buffer :noquery t :connection-type 'pipe
     :command (list "powerprofilesctl" "set" mode)
     :sentinel (lambda (process _event)
                 (unless (process-live-p process)
                   (if (zerop (process-exit-status process))
                       (message "Power mode: %s" (alist-get mode anthe-bar--power-modes nil nil #'equal))
                     (message "Power mode not changed: %s"
                              (string-trim (with-current-buffer buffer (buffer-string)))))
                   (kill-buffer buffer)
                   (anthe-bar--look))))))

(defun anthe-bar-power-menu ()
  "A menu to switch the power mode, the one on ticked."
  (interactive)
  (let ((current (anthe-bar--power-mode)))
    (popup-menu
     `("Power mode"
       ,@(mapcar (lambda (mode)
                   (vector (cdr mode) `(anthe-power-mode-set ,(car mode))
                           :style 'radio :selected (equal (car mode) current)))
                 anthe-bar--power-modes)))))

(map! :leader :desc "Power mode" "k e" #'anthe-power-mode-set)

;;; Drives: the USB drives and SD cards plugged in (udisks), mounted by
;;; udiskie as they come (exwm-desktop.el). SPC k u, or a click, ejects one

(defun anthe-bar--bytes (bytes)
  "A D-Bus byte array, as a mount point or a device, as a string."
  (decode-coding-string (apply #'unibyte-string (seq-take-while #'cl-plusp bytes)) 'utf-8))

(defun anthe-bar--drives ()
  "The filesystems on drives that aren't the laptop's own, as plists:
:label, :device, :mount (nil if not mounted), :drive (the udisks object)."
  (let* ((objects (ignore-errors
                    (dbus-get-all-managed-objects :system "org.freedesktop.UDisks2"
                                                  "/org/freedesktop/UDisks2")))
         (interface (lambda (object name) (cadr (assoc name (cadr object)))))
         (get (lambda (props name) (cdr (assoc name props)))))
    (delq nil
          (mapcar
           (lambda (object)
             (let ((block (funcall interface object "org.freedesktop.UDisks2.Block"))
                   (fs (funcall interface object "org.freedesktop.UDisks2.Filesystem")))
               (when (and block fs
                          (not (funcall get block "HintSystem"))
                          (not (funcall get block "HintIgnore")))
                 (let ((device (anthe-bar--bytes (funcall get block "PreferredDevice")))
                       (mount (car (funcall get fs "MountPoints"))))
                   (list :label (let ((label (funcall get block "IdLabel")))
                                  (if (string-empty-p label)
                                      (file-name-nondirectory device)
                                    label))
                         :device device
                         :size (funcall get block "Size")
                         :mount (and mount (anthe-bar--bytes mount))
                         :drive (funcall get block "Drive"))))))
           objects))))

(defun anthe-bar--drive-help (drive)
  (let ((mount (plist-get drive :mount)))
    (concat (plist-get drive :label) ", "
            (file-size-human-readable (plist-get drive :size) 'si " ") ", "
            (if mount
                (let ((info (file-system-info mount)))
                  (format "%s free, on %s"
                          (file-size-human-readable (nth 2 info) 'si " ") mount))
              "not mounted"))))

(defun anthe-bar--drives-status ()
  "The drives plugged in, by name, the mounted ones bright.  A click opens
`anthe-bar-drives-menu'."
  (when-let* ((drives (anthe-bar--drives)))
    (list (concat (anthe-bar--icon "nf-md-usb_flash_drive")
                  (mapconcat (lambda (d)
                               (concat " " (propertize (plist-get d :label)
                                                       'face (unless (plist-get d :mount) 'shadow))))
                             drives))
          (mapconcat #'anthe-bar--drive-help drives "\n")
          #'anthe-bar-drives-menu)))

(defun anthe-bar--udiskie (command &rest args)
  "Run COMMAND (udiskie-mount or udiskie-umount) with ARGS in the
background, its outcome in the echo area, and look again once done."
  (let ((buffer (generate-new-buffer " *udiskie*")))
    (make-process
     :name command :buffer buffer :noquery t :connection-type 'pipe
     :command (cons command args)
     :sentinel (lambda (process _event)
                 (unless (process-live-p process)
                   (let ((output (string-trim (with-current-buffer buffer (buffer-string)))))
                     (message "%s" (cond ((not (zerop (process-exit-status process)))
                                          (concat "Not done: " (car (last (split-string output "\n" t)))))
                                         ((equal command "udiskie-umount")
                                          "Ejected: it can be unplugged")
                                         (t (or (car (last (split-string output "\n" t))) "Mounted")))))
                   (kill-buffer buffer)
                   (anthe-bar--look))))))

(defun anthe-eject-drive (drive)
  "Unmount DRIVE, every filesystem on it, and power it off, to unplug it
safely.  Asked in the minibuffer among those plugged in, if several."
  (interactive
   (let* ((drives (or (anthe-bar--drives) (user-error "No drive plugged in")))
          (choices (mapcar (lambda (d) (cons (anthe-bar--drive-help d) d)) drives)))
     (list (if (cdr choices)
               (cdr (assoc (completing-read "Eject: " choices nil t) choices))
             (car drives)))))
  (message "Ejecting %s…" (plist-get drive :label))
  ;; A buffer visiting a file on it would keep it busy
  (when-let* ((mount (plist-get drive :mount)))
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
        (when (and (or buffer-file-name (derived-mode-p 'dired-mode))
                   (file-in-directory-p default-directory mount)
                   (not (buffer-modified-p)))
          (kill-buffer buffer)))))
  (anthe-bar--udiskie "udiskie-umount" "--detach" (plist-get drive :device)))

(defun anthe-bar-drives-menu ()
  "A menu to open, mount or eject the drives plugged in."
  (interactive)
  (popup-menu
   `("Drives"
     ,@(apply #'append
              (mapcar (lambda (d)
                        (let ((mount (plist-get d :mount)))
                          (list (vector (anthe-bar--drive-help d) nil :active nil)
                                (if mount
                                    (vector "  Open" `(dired ,mount))
                                  (vector "  Mount" `(anthe-bar--udiskie "udiskie-mount" ,(plist-get d :device))))
                                (vector "  Eject" `(anthe-eject-drive ',d)))))
                      (anthe-bar--drives))))))

(map! :leader :desc "Eject a drive" "k u" #'anthe-eject-drive)

;;; Claude's plan limits, from the last reply (anthe-agents.el)

(defun anthe-bar-claude-limits ()
  "Show Claude's limits in words: the session's and the week's, and when
they renew."
  (interactive)
  (message "%s" (anthe/claude-limits-help)))

(defun anthe-bar--claude ()
  "How much of Claude's 5-hour session is used, if known; a click tells
the rest."
  (when-let* (((fboundp 'anthe/claude-limits--percent))
              (percent (anthe/claude-limits--percent :five-hour)))
    (let ((face (cond ((>= percent 90) 'error) ((>= percent 75) 'warning))))
      (list (concat (anthe-bar--icon "nf-md-robot_outline" face)
                    (propertize (format " %d%%" percent) 'face face))
            (anthe/claude-limits-help)
            #'anthe-bar-claude-limits))))

(defun anthe-bar--caffeine ()
  "A cup, full with caffeine on (the screen stays on), empty without; a
click switches it (exwm-desktop.el)."
  (when (fboundp 'anthe-caffeine-mode)
    (let ((on (bound-and-true-p anthe-caffeine-mode)))
      (list (anthe-bar--icon (if on "nf-md-coffee" "nf-md-coffee_outline") (if on 'warning 'shadow))
            (if on "Caffeine on: the screen stays on and unlocked\nClick: lock again when idle"
              "The screen locks when idle\nClick: caffeine, the screen stays on")
            #'anthe-caffeine-mode))))

(defun anthe-bar--look ()
  "Look at Claude's limits, the system, the drives, Bluetooth, the network
and the battery, and redraw the bar."
  (setq anthe-bar--status
        (delq nil (mapcar (lambda (look) (ignore-errors (funcall look)))
                          '(anthe-bar--claude anthe-bar--system anthe-bar--drives-status
                            anthe-bar--bluetooth anthe-bar--network anthe-bar--caffeine
                            anthe-bar--battery))))
  (force-mode-line-update t))

(defun anthe-bar--right ()
  "The status, against the right edge.  Its width is measured a little
over (icons and faces vary), else the tab bar wraps it on a second line."
  (let* ((items (seq-map-indexed
                 (lambda (item i)
                   `(,(intern (format "anthe-bar-status-%d" i)) menu-item
                     ,(concat "  " (car item)) ,(or (nth 2 item) 'ignore)
                     :help ,(nth 1 item)))
                 anthe-bar--status))
         (text (mapconcat (lambda (item) (nth 2 item)) items ""))
         (width (string-pixel-width (propertize text 'face 'tab-bar))))
    (cons `(anthe-bar-right menu-item
            ,(propertize " " 'display
                         `(space :align-to (- right (,(+ width (* 2 (frame-char-width)))))))
            ignore)
          items)))

(setq tab-bar-format
      (list (lambda () (anthe-bar--on-bar (anthe-bar--workspaces)))
            (lambda () (anthe-bar--on-bar (anthe-bar--clock)))
            (lambda () (anthe-bar--on-bar (anthe-bar--right)))))

;;; The colours: the mode line's, the themes' tab bar being for tabs

(defun anthe-bar--colours (&rest _)
  (set-face-attribute 'tab-bar nil
                      :background (face-background 'mode-line nil t)
                      :foreground (face-foreground 'mode-line nil t)
                      :box nil :inherit 'unspecified))

(anthe-bar--colours)
(add-hook 'doom-load-theme-hook #'anthe-bar--colours)

;;; Showing and hiding

(defun anthe-bar--frames ()
  (if (bound-and-true-p exwm-workspace--list) exwm-workspace--list (list (selected-frame))))

(defun anthe-bar--apply ()
  "Show or hide the bar on every workspace, as `anthe-bar-shown' says."
  (dolist (frame (anthe-bar--frames))
    (set-frame-parameter frame 'tab-bar-lines-keep-state t)
    (set-frame-parameter frame 'tab-bar-lines (if anthe-bar-shown 1 0)))
  (when anthe-bar--timer (cancel-timer anthe-bar--timer))
  (setq anthe-bar--timer
        (and anthe-bar-shown (run-at-time nil anthe-bar-interval #'anthe-bar--look)))
  ;; The time and the battery are in the bar or in the mode line
  (display-time-mode (if anthe-bar-shown -1 1))
  (display-battery-mode (if anthe-bar-shown -1 1)))

(defun anthe-bar-toggle ()
  "Hide or show the top bar."
  (interactive)
  (setq anthe-bar-shown (not anthe-bar-shown))
  (anthe-bar--apply))

(defun anthe-bar--redraw (&rest _)
  (force-mode-line-update t))

;;; The workspaces in the echo area: not while the bar shows them

(defun anthe-bar--display-a (fn)
  "Show the workspaces in the echo area only when the bar is hidden, or
when asked (SPC TAB TAB)."
  (when (or (not anthe-bar-shown) (eq this-command '+workspace/display))
    (funcall fn)))

(defun anthe-bar--message-body-a (fn message &optional type)
  "Doom's workspace messages, without the workspaces when the bar shows them."
  (if anthe-bar-shown
      (propertize (format "%s" message)
                  'face (pcase type
                          ('error 'error)
                          ('warn 'warning)
                          ('success 'success)
                          ('info 'font-lock-comment-face)))
    (funcall fn message type)))

(advice-add '+workspace/display :around #'anthe-bar--display-a)
(advice-add '+workspace--message-body :around #'anthe-bar--message-body-a)

(add-hook 'persp-activated-functions #'anthe-bar--redraw)
(add-hook 'persp-renamed-functions #'anthe-bar--redraw)
(add-hook 'exwm-workspace-list-change-hook #'anthe-bar--apply)
(if (bound-and-true-p exwm-workspace--list)
    (anthe-bar--apply)
  (add-hook 'exwm-init-hook #'anthe-bar--apply))

(map! :leader :desc "Top bar" "t B" #'anthe-bar-toggle)

(provide 'anthe-bar)
;;; anthe-bar.el ends here
