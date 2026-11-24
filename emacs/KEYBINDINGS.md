# Keybindings

Notes on how the custom Emacs and EXWM keybindings are organised, and on the
decisions made while restructuring them. Doom's own bindings are not listed.

## Principles

- The cost of a key follows how often it is used. Daily actions get one key
  after the leader, like `SPC \` for the app launcher and `SPC j` for the browser.
- The leader is preferred over the super key, which is less comfortable to hit
  and has to be held down.
- No duplicates of Doom's own bindings.
- Keys for one mode only live in that mode. `map! :map foo-mode-map :leader`
  does **not** do that: `:leader` ignores `:map` and binds globally. Use
  `:localleader` (`SPC m`), or a conditional binding like `anthe/python-only`
  in `modules/anthe-python.el`.
- Rare actions live under `SPC k`.
- In EXWM windows, Evil (exwm-evil) handles insert and normal states, so the
  char-mode keys are not needed.

## Current scheme

| Keys | Action | Where |
|---|---|---|
| `SPC \` | App launcher | `config-local.el` |
| `SPC j` / `SPC J` | qutebrowser launcher: open windows with preview, quickmarks (`m` narrows), bookmarks to read later (`b`), history / same in a new window. `TAB` completes the input with the selected candidate | `anthe-qutebrowser.el` |
| `SPC ]` / `SPC [` | Next / previous code cell (Python or code-cells buffers) | `anthe-python.el` |
| `SPC r j`, `r b`, `r ]`, `r r` | Send line or region, buffer, cell; restart the shell (Python buffers) | `anthe-python.el` |
| `SPC r p`, `r J`, `r a` | Python REPL, Jupyter REPL, activate env (from anywhere) | `anthe-python.el` |
| `SPC w .` | Resize mode, for Emacs and EXWM windows: `hjkl` move the border, `HJKL` 3× more, `=` balance, `m` maximize, `u` undo, any other key leaves | `anthe-windows.el` |
| `SPC q p` | Power off: switches the laptop charger off if the Tapo strip answers (at home), quits Emacs and EXWM as `C-x C-c` does (saving files and workspaces, without asking about running shells), then powers off | `anthe-control.el` |
| `SPC o a w` | Week calendar: the calendar events of a week as in a calendar app, a column a day. `]`/`[` next and previous week, `.` this week, `RET` or a click opens an event, `+` or a click on an empty time adds an event there (khalel), `gr` reads the calendar again, `S` syncs it with the server first. Also on the dashboard, compact | `anthe-week.el` |
| `SPC t B` | Hide or show the top bar (Doom workspaces, date and time, Bluetooth, network, battery) | `anthe-bar.el` |
| `SPC z z`, `z a`, `z o`, `z h` | Notifications (dunst): dismiss the last, dismiss all, open (its default action, like the mail), bring back the last dismissed | `anthe-control.el` |
| `SPC k …` | Rare actions: `k t` toggles (`l` desk lamp, `a` armchair lamp, `p` ceiling lamp, sound, drive, VPN, charger; `k t m` light scenes: `a` ambiance, `c` coding, dark blue, `s` small lights on or off), `k r b` NAS backup, `k s f` face height, `k b` edit the qutebrowser quickmarks (`C-u`: bookmarks), `k d` dashboard, `k l` light and themes (`l` Night Owl or Light Owl, `+`/`-` sunlight: more or less contrast for bright light, then `+`, `-`, `0` without the prefix, `0` off, `t` load a theme), `k o d` open externally, `k o m` system monitor, `k m` monitors (`m` mirror or extend, `s` swap the workspaces of the two monitors, `p` primary monitor, the one qutebrowser shares in Zoom, `d` detect), `k p` contacts (`p` find or edit, `n` new, `a` add an address from mail, to a new or an existing contact, `d` delete, `s` sync), `k j` J.A.R.V.I.S (`j` HUD, `s` talk, `t` type a message, `c` cancel or stop talking, `l` listen for "Hey Jarvis" on or off, `v` show the session, `q` stop the session, `Q` HUD off, `R` restart the HUD, `M` switch the model, `m` mute, `L` English or French (speech and voice), `w` wake an agent in a folder; from the private ~/jarvis repository) | various |
| `SPC v v` | New terminal (multi-vterm) in the popper popup; `M-`` cycles the popups, `C-M-`` makes one a normal window | `anthe-vterm.el` |
| `SPC k q q/g` | squeue (HPC config) | `config-hpc.el` |
| `s-<escape>` | `exwm-reset`, the way back if a window gets stuck in char mode | `exwm/exwm-desktop.el` |

In qutebrowser windows (Evil normal state), see `anthe-qutebrowser.el`:
qutebrowser's own keys are sent to it, and prefixes like `g`, `;`, `,` list
the matching qutebrowser bindings at the bottom of the screen. `m` saves the
page as a quickmark, prompting in Emacs with the existing names.

In mu4e (main view, message list and message, Evil normal state), see
`anthe-mu4e.el`: `gm` Gmail, `gw` Work, `gi` Infomaniak, `ga` AntADatabase,
`gu` UniBe go to the inbox of that account; `J` jumps to a folder, choosing
the account first. `gb` opens the message at point in qutebrowser, for HTML
that renders badly in Emacs. Saved searches (`b` then the key): `i` all the
inboxes, `T` To do (flagged). In the main view, `q` closes it (kills the buffer, for the dashboard if nothing else is left in the workspace; mu4e goes
on syncing and notifying) and `Q` quits mu4e. `R` replies, `W` replies to all (in the message
too, where it was Evil's next WORD).

Threads show as their latest message received (not my replies), sorted by
its date, with the number of messages: `TAB` unfolds one (in dark orange),
`S-TAB` all, `{`/`}` go by thread and `M` marks a thread (only
its messages matching the search). In a message, `C-j`/`C-k` go to the
next/previous thread and `]t`/`[t` to the newer/older message in the thread.
`zc` shows the whole thread in one buffer, latest first (`TAB` collapses a
message, `S-TAB` all, `C-j`/`C-k` move, `RET` opens it in mu4e, `q` quits).

## Log

### 2026-11-05

- Browser moved from `SPC k q o` / `O` / `b` to `SPC j` / `SPC J`. The launcher
  already lists open windows, so the separate buffer switcher key was dropped.
- Python buffer keys (`SPC r j/b/]/r`, `SPC ]/[`) are only active in Python or
  code-cells buffers. They were global because of the `:leader` + `:map` issue.
  The REPLs (`SPC r p`, `r J`, `r a`) stay global, to compute or test code from
  anywhere.
- EXWM: removed the char-mode and reset keys (`s-k`, `s-i`, `s-l`, `s-r`,
  `M-i`, `M-k`). `M-k` was bound both to `exwm-reset` and to
  `exwm-input-release-keyboard`. Only `s-<escape>` is kept as a way back.
  Changes to `exwm-input-global-keys` need an EXWM restart.
- System monitor moved from `s-o m` to `SPC k o m`.
- Window resizing moved to the `SPC w .` resize mode. It replaces `C-<arrows>`
  (`config-core.el`, `anthe-popper.el`), which EXWM windows took for
  themselves, and `s--`, `s-=`, `s-_`, `s-+`. The keys move the border in their
  direction instead of growing the window, and the resizing is pixelwise so
  EXWM windows don't snap to character cells.

### 2026-11-09

- mu4e: `g` + a letter goes to the inbox of an account, shown in the
  Accounts section of the main view. They override Evil's `gi`, `ga`, `gu`,
  which do nothing in these read-only buffers. `J` (`mu4e-search-maildir`)
  asks for the account, then the folder.
- agent-shell: `gC` opens the compose buffer beside the shell.
- Notifications under `SPC z` (free in Doom): `z z` dismiss, `z a` dismiss
  all, `z o` open, `z h` bring back the last. Leader rather than super, as
  usual; in a qutebrowser window in insert mode, `Escape` first. With the
  mouse: left click opens, middle click dismisses, right click dismisses all
  (`rcfiles/dunstrc`).
- qutebrowser marks: `m` in a qutebrowser window saves a quickmark from an
  Emacs prompt that offers the existing names, to reuse their prefix
  (`gh pism`, `mail unibe`); `M` stays qutebrowser's bookmark (read later).
  `SPC k b` edits the quickmarks file, `C-u SPC k b` the bookmarks.
  Web pages are no longer saved as Emacs bookmarks.

## Open questions

- **Journal.** Both systems write to `~/org/roam/journal/YYYY.MM.DD.org`:
  org-journal (`SPC n j j` new entry, `SPC n j o` open the current file) and
  `anthe-roam-journal` (`SPC k n j` today, `SPC n r j …`). Proposal: one
  `SPC n j` prefix, keeping `j` for a new entry and `o` for today, plus `y`
  yesterday, `m` tomorrow, `d` date, `f`/`b` next/previous note.
  Also `SPC n r j m` is bound twice (the "capture tomorrow" one goes to tomorrow).
- **Citar.** `citar-open` must stay very accessible, but `SPC n b` (notes)
  felt confusing. Currently `SPC k c …`.
- **Code cells.** If `SPC ]` is not fast enough, `]]` / `[[` in Python normal
  state would be the Vim idiom (Evil binds them to section moves, little used).
- **Remaining duplicates** to remove: `SPC k x` (= `SPC X`), `SPC k a`
  (= `SPC o A`), `SPC k g` (= `SPC o l`), the `SPC s p` and `SPC /` overrides,
  and the two next/previous shell pairs `SPC t n/p` and `SPC v n/p`.
- **HPC.** sbatch moved to `SPC k q b`: `SPC k s` clashed with the `SPC k s f` prefix from
  `config-core.el` there.
- mu4e: `gb` opens the message in qutebrowser (message list and message).
- mu4e: saved searches `b i` (all the inboxes) and `b T` (To do, flagged messages).

### 2026-11-10

- qutebrowser launcher: `TAB` puts the selected candidate in the input (consult made it go to the next group).
- mu4e: `W` replies to all in a message too, as in the message list. It was Evil's next WORD there.
- Capture: `SPC X t m` makes an inbox task linked to the mail at point in mu4e (list or message).
- mu4e threads: folded to their latest message (`TAB`, `S-TAB`), `M` marks a thread, `{`/`}` by thread. In a message, `C-j`/`C-k` go by thread (was by line), `]t`/`[t` within it. `zc` conversation view.
- mu4e main view: `q` closes it without quitting mu4e (it stopped syncing and notifications), `Q` quits mu4e and mail-idle (was `mu4e-search-query`, which `b` and `J` cover).

### 2026-11-11

- mu4e: `b a` searches the archive folders of all the accounts.
- Monitors (`anthe-monitors.el`): `SPC k m m` mirrors or extends the laptop screen, `SPC k m s` swaps the workspaces of the laptop and the external monitor, `SPC k m p` chooses the primary monitor, `SPC k m d` detects the monitors again. Plugging a monitor in or out is handled without a key.

### 2026-11-13

- New terminal moved from `SPC V` (shift) to `SPC v v`, next to `v n`/`v p`/`v r`. It opens in the popper popup: `multi-vterm` used `switch-to-buffer`, which skips popper and took the current window.
- Contacts under `SPC k p` (`anthe-contacts.el`): `p` find or edit a contact, `n` new, `a` add an address known from mail (the people of the message at point first) to a new contact or an existing one, as a home, work or other address, in chosen groups, `d` delete, `s` sync with the Pi and Infomaniak. A contact opens as a form, `C-c C-c` saves and syncs; its `Categories` field completes the existing groups. The address book also joins mu4e's address completion.

### 2026-11-14

- J.A.R.V.I.S under `SPC k j` (`~/jarvis/emacs/jarvis.el`, loaded only if the private repository exists): `j` shows the HUD, its dashboard, and starts it (it listens for "Hey Jarvis" or "Ok Jarvis", answers the time, the date, stop, mute, language and repeat itself, offline, shows a ring over the screen that follows your voice and then Jarvis's, and, when a request needs the session and it sleeps, asks "Shall I bring the core online?" and starts it on yes, not on weekends; "wake up Jarvis", "switch off Jarvis" by voice); `s` listens to a request now, without the wake words, and stops when you stop talking; `t` opens a small window to type a message from anywhere (`C-c C-c` sends it, `C-c C-k` cancels); `c` cancels listening or waiting and stops it talking; `l` turns listening for "Hey Jarvis" on or off (off closes the microphone); `v` shows the session (`C-u` starts it on weekends); `q` stops the session; `Q` turns the HUD off; `R` restarts it (after a change to its code); `M` switches the session's model (haiku, sonnet, opus...: at once with /model, no restart, and at the next starts until Emacs restarts; by voice "Load Sonnet", "Passe sur Opus"); `m` mutes or unmutes its voice; `L` switches what it hears and speaks between English and French (also by voice: "Hey Jarvis, switch to French", "passe en anglais"); `w` opens an agent-shell in a folder. In the HUD buffer, the same letters without the prefix, `c` cancels, `g` refreshes, `D` plays the core's loading ring and sound, `n`/`p` (or `j`/`k`) move, `TAB` on a reply under JARVIS SAID shows it in full or cuts it again (elsewhere, goes to the next reply). "Ok Jarvis, stop" while it transcribes drops the request.
- Lamps and light scenes (`anthe-control.el`): `SPC k t a` toggles the armchair lamp and `SPC k t p` the ceiling lamp, next to `k t l` the desk lamp; `SPC k t m a` ambiance (desk and armchair lamps warm, ceiling off), `k t m c` coding (dark blue), `k t m s` the small lights (desk and armchair) on or off. The scenes are python-utils' `light_scene.py`, also said to J.A.R.V.I.S ("ambiance mode", "coding mode", "switch the small lights on").

### 2026-11-18

- Themes under `SPC k l` (`anthe-themes.el`): `l` switches between anthe-night-owl and anthe-light-owl (Sarah Drasner's Night Owl Light, as a Doom theme in `themes/anthe-light-owl/`). `+` raises sunlight a level (6 at most), `-` lowers it, `0` turns it off; after the first, `+`, `-` and `0` go on alone. Sunlight raises the contrast of any theme for a bright office or the sun: comments, line numbers and muted text move towards the text colour, the region and current line away from the background. `t` loads any theme with a preview (modus-vivendi, modus-operandi...). The night owl's own face overrides in `config-core.el` now apply to it only, not to the other themes.
- qutebrowser: `d` closes the window and shows the next one (in opening order, as `J`), `D` closes it and shows the previous one (as `K`), to go through the windows and close them quickly. `u` opens the last closed one again. `kill-buffer` still goes back to the buffer shown before.
- agent-shell: only `C-c C-c` sends a prompt, in the shell and in the compose buffer. `RET` is a newline in insert state and moves in normal state (it sent the prompt in normal state). `C-c C-k` interrupts the agent (was `C-c C-c`; `gx` still does too).
- Power off on `SPC q p` (`anthe-control.el`), next to Doom's quit keys: after a yes, the charger goes off if the Tapo strip answers within a few seconds (python-utils' `switch_devices.py` now takes `on` or `off`, so it never switches it back on), Emacs and EXWM quit as on `C-x C-c`, and logind powers off 3 s later. A file left unsaved on purpose cancels it, as for `C-x C-c`.
- A top bar on the EXWM workspaces (`anthe-bar.el`, Emacs's own tab bar): the Doom workspaces on the left, the current one highlighted, a click switches; the date and time in the middle, a click opens the calendar; Bluetooth (headphones by name, with their battery), the network (Wi-Fi name and strength, wired, VPN) and the battery on the right, details on hover. While it shows, the time and battery leave the mode line. `SPC t B` hides or shows it (`SPC t T` was taken by transparency).

### 2026-11-19

- Week calendar on `SPC o a w` (`anthe-week.el`), next to Doom's agenda keys under `SPC o a`: the events of `~/org/calendar.org` (khalel) a column a day, hours down the side, events as blocks, those at the same time side by side, all-day ones on top, a line at the time now. `]`, `[`, `.` move by week, `RET` opens an event, `gr` refreshes, `S` syncs. The dashboard shows the same week first (the next one at the weekend).
- Each monitor has its own dashboard, laid out at its width (`*dashboard*` on the first workspace, `*dashboard: 2*` on the second); a window whose last buffer is closed shows its monitor's. The calendars sync in the background 3 s after startup, then every 5 minutes (`anthe-dashboard-sync-interval`; only their vdirsyncer pairs, those named for a calendar), and the events are imported and the dashboard drawn again only when something changed. `S` in the week syncs at once. Login shows a loading screen (`bin/anthe-splash`): the lock screen's wallpaper and a ring filling as Emacs loads, until EXWM shows Emacs (or a click, or 45 s).
- Work agenda (`SPC o a a w`): whole weeks from Monday, opened scrolled to today with the days before above it; `]` and `[` show the next and previous weeks whole.
- Bar: a click on Bluetooth opens a menu to turn it on or off and to connect or disconnect the paired devices; processors and memory used are shown, a click opens `proced`. A Bluetooth keyboard or mouse connecting gets the keyboard preferences (layout, Caps Lock as Control, repeat rate); the keyboard connecting also connects the mouse.
- `C-h` goes up a directory when completing a file name (vertico), elsewhere it stays the help prefix. qutebrowser's download prompt: in EXWM, Emacs asks where to save (find-file's completion, `C-g` cancels the download); its own prompt has `C-j`/`C-k` through the files and `C-h` up a directory.
- `j`, `k`, `0`, `$` move by screen lines where lines wrap (`evil-respect-visual-line-mode`, in `init.el`), with visual line numbers.
- Week calendar: `+`, or a click on an empty time, adds an event there with khalel's capture (an hour, or all day from the days row); `S` syncs (evil-snipe's `S` had hidden it). The dashboard's week is compact (a row an hour, only the hours with events); recent files and projects left the dashboard. The dashboard agenda (`d`) shows whole weeks scrolled to today, as the PhD one.
- Viewers to try (`anthe-pdf.el`): `SPC k o v` chooses what PDFs open in (pdf-tools, zathura, emacs-reader) and images (image-mode, nsxiv, imv); `SPC m z` in a PDF opens it in zathura at the same page. Their colours, and pdf-view's night mode, are the theme's exactly.

### 2026-11-20

- PDFs open in zathura and images in nsxiv by default (`anthe-pdf.el`; `SPC k o v` chooses pdf-tools, emacs-reader or image-mode instead; imv left). Their buffers are `PDF: NAME` and `Image: NAME`, with pdf-view's keys in normal state, sent to the program (`anthe-viewers.el`): `j`/`k`/`h`/`l` scroll (pan in nsxiv), `C-j`/`C-k` and `J`/`K` the next or previous page or image, `C-d`/`C-u` half a page, `gg`/`G`, `+`/`-`/`=` zoom, `P` fit the page, `W` the width, `H` the height, `r` rotates, `q` closes. zathura: `/` and `?` search (asked in the minibuffer), `n`/`N`, `f` follows a link (its number asked), `C-o` back, `TAB` the outline, `d` two pages, `R` reloads; `SPC m m` night mode, `SPC m g` a page, `SPC m e` opens it in pdf-tools at that page. nsxiv: `RET` thumbnails, `n`/`p`. `i` still passes every key to the program.
- Week calendar: the details of the event under the cursor stay in the echo area while the cursor is on it.
- zathura: `zm` switches between night and light mode (as `SPC m m`). `SPC s l` (and `SPC m l`) opens a web address or DOI of the page shown, its links and those written in its text, in the browser (`SPC s l` follows links elsewhere). nsxiv's keys now reach it (it dropped a key press sent with its release).
- A PDF or image already shown in zathura or nsxiv shows in that buffer again, in the window it is opened from, rather than in a second one (`<2>`). Previews open them in the window previewed in, and close them when the completion ends, but the one chosen: consult's (recent files), and `citar-open`'s, which previews the reference's first PDF after 0.4 s.
- In zathura and nsxiv too, `SPC f` acts on the file shown, as in pdf-view (`anthe-viewers.el`): `D` deletes it and closes the viewer, `R` moves or renames it, `C` copies it, `y` copies its path.
- The window switched into flashes gently (`anthe-windows.el`), with three windows or more on the frame: its text's background goes a little towards the text colour and fades in 0.4 s; not on coming back from the minibuffer, nor in EXWM windows. `M-x anthe/window-flash-mode` turns it off. New zathura and nsxiv windows show in the window they were opened from from the start. Previews (consult, `citar-open`) stay in pdf-view and image-mode; the file chosen opens in zathura or nsxiv.
- Power mode on `SPC k e` (power saver, balanced, performance; power-profiles-daemon), or from the battery on the top bar: a click opens the menu, and a leaf or a rocket next to it shows power saver or performance (`anthe-bar.el`).
- Week calendar: `s` or `/` searches an event, by its title, place, calendar, organiser or description; the coming events first. The week of the one under the cursor shows while choosing, the event highlighted; `RET` stays on it, `C-g` goes back.
- Month calendar: `SPC o a M` (`SPC o a m` is Org's tag search), or `m` from the week view and `w` back, on the day under the cursor. Same keys as the week: `[`/`]` months, `.` this month, `s` or `/` search (the month of the event shows), `+` an all-day event on the day under the cursor, `RET` opens an event, or shows the week of an empty day. All-day events are bars across their days; a day with too many events for the window ends with `+N more`, which lists them when hovered.
- Videos (mp4, mkv, webm, mov, avi…) open in mpv as a `Video: NAME` buffer (`anthe-viewers.el`), driven through mpv's command socket from normal state: `p` or `RET` pause, `.`/`,` and `C-j`/`C-k` a frame forward or back, `l`/`h` 5 s, `j`/`k` 1 s, `L`/`H` a minute, `C-d`/`C-u` 30 s, `gg`/`G`, `[`/`]` speed ×0.9/×1.1, `{`/`}` half or twice, `+`/`-` zoom, `=` back to normal speed and zoom, `r` rotate, `a` A-B loop, `m` mute, `s` saves the frame as a PNG next to the video, `o` shows the frame and time, `q` closes; `SPC m g` goes to a time, `SPC m i` statistics. Counts work (`10.` ten frames). Previews (recent files, find-file) show a frame, the length, size and frame rate, without playing. openwith no longer opens mp4.
- `SPC .` (find-file) and `SPC f f` (find-file-at-point) preview the file selected, as the recent files do (0.4 s).
- `SPC k o w` opens the file of the buffer (or the viewer's, or dired's at point) with another program, chosen in the minibuffer: Emacs' viewers (zathura, pdf-tools, emacs-reader; nsxiv, image-mode; mpv) and the programs whose .desktop file takes its type, the default first. The buffer it was shown in closes. `SPC k o d` still opens it with the default program.
- Notifications ring a gentle bell (freedesktop's `bell.oga` at 30 %, `bin/notify-bell`, run by dunst), but low urgency ones, and once for several arriving together. `SPC z b` turns it off, and on again; it stays so across logins.
- zathura: `o` shows the outline on the side, as pdf-tools': the section the cursor stops on shows, `RET` goes to it, `o` too and closes the outline, `TAB`/`S-TAB` fold, `f` stops following the cursor, `q` closes. `SPC s i` (and `SPC m i`) searches the outline's titles, `SPC s s` (and `SPC m s`) the lines of the text, showing each page as it goes, `C-g` back. `C-j`/`C-k` reach it (exwm-evil had them), and `/` searches again. The outline opens next to the PDF, splitting its window. Search results are in Night Owl's purple, seen through, the current one more; night mode keeps the colours, as pdf-view's. `f` labels the links with letters, as qutebrowser (home row, white on orange, at each link's start), and follows one as soon as its letters are typed; `ESC` or `C-g` cancels. A patched zathura (`rcfiles/zathura/link-hints.patch`, built in `~/.local`).
- `SPC k t d` switches the Pi's USB disk through its power page on the Pi (`pi/nas-power`) rather than the Tapo strip directly: off unmounts it first (stopping Immich), parks it and only then cuts the socket, and refuses while something uses the disk; on waits for it to mount. Works from anywhere on the WireGuard. The page itself, http://10.158.145.1:8095, has the same two buttons and the disk's state and health.
- The top bar shows the USB drives and SD cards plugged in, by label (dimmed if not mounted); hovering tells their size and free space, a click opens a menu to open one in dired, mount or eject it. `SPC k u` ejects one: unmounts all its partitions and powers it off, to unplug it safely (asks which if several). udiskie, started with EXWM, mounts drives as they are plugged in, on `/run/media/anthe/LABEL`, with a notification.
- Lock screen (`bin/anthe-lock`, i3lock-color): `SPC k z` locks. The wallpaper, blurred, with the clock and the date in J.A.R.V.I.S's ring (`rcfiles/i3lock/jarvis-ring.patch`): cyan at rest, amber bars jumping as you type, red if wrong (at once: no delay in `/etc/pam.d/i3lock`), the gauge filling on unlock. Type the password and Enter; `Escape` clears it. Closing the lid still suspends. `SPC k Z` locks the same and keeps the laptop awake until unlocked, lid closed or not, so Claude and the rest work on while you're away. The screen goes off a minute after locking; Shift wakes it. xss-lock, started with EXWM, locks by itself before the laptop sleeps and after 10 minutes idle. `ring=plain` in the script for i3lock-color's own ring.

### 2026-11-22

- Task flow (`anthe-tasks.el`). The open TODOs of the last daily note move to today's under `* Carried over` (with `:SINCE:` and `:CARRIED:`), with a copy of that day's `Stopped` note; it runs when today's daily is opened or captured into, and once a day from 5:00 (agenda or a minute idle).
- `SPC k n s`: the `Stopped` note of the hard stop in today's daily (doing, next step, still open, waiting on me, first thing tomorrow).
- `SPC m r i` in Org, `SPC m i` in the agenda: move the TODO to the Inbox (`~/org/roam/Inbox.org`, renamed from `Tasks.org`, one heading; `SPC X t p` captures there tagged `perso`).
- `#` in a heading offers the tags in use; the one chosen becomes a tag of the heading.
- `SPC m A` (Org, and now the agenda too) archives into `~/org/roam/Log.org`, a date tree in the agenda, the tags kept. `SPC k o A` archives every DONE and KILL of the agenda files (not the dailies), `C-u` the current buffer only.
- Agenda `l` (`SPC o a a l`): what was done, latest first, with the day; `s t` or `\` filters by tag.
- Skip a habit (or any repeating task) to its next time without marking it done, so nothing is logged: `SPC m s` in the agenda, `SPC m d n` in Org (`anthe-tasks-skip`).
- Week and month calendars: an event lasting a day or more (a trip) is a bar on top across its days, with its start time, `… Title` in the weeks after its first; it no longer stretches the hours to midnight. The hover gives its end day.
- Agenda `h` (`SPC o a a h`), Later: what waits, out of the other views (HOLD: after something else, WAIT: on someone, IDEA, and what is scheduled after today), for the weekly review. The dashboard and PhD views no longer list HOLD and IDEA, nor a task scheduled later before its day; the PhD view's Idea section went there.
- `SPC k n d` (and Doom's `SPC n r d t`) shows today's daily note where you were writing in it: no template to choose, the point kept; a note opened afresh shows its end. Still carries over first (`anthe-tasks-today`). The capture templates stay on `SPC n r d n`.
- `SPC o c`: the agent of a project. Choose a project (those with an agent shell first, marked `● agent`); its shell shows in the project's workspace, made as `projectile-switch-project` does, without asking for a file. With no shell yet, Claude starts there and resumes the project's last session. `C-u SPC o c`: in the current workspace (`anthe-agents.el`).
- Dashboard (`anthe-dashboard.el`), drawn by itself now (emacs-dashboard only gives the buffer): cards with round corners, the text in Ubuntu Sans, the week's grid in the fixed font, columns aligned from the window's centre so the variable pitch keeps them straight. Rows: the header (the planet, a greeting, the date, and a status strip: the next event, tasks due this week and late, unread mail as the Unread bookmark counts it, Syncthing's devices, Claude's limits); the week and the tasks side by side from 200 columns (one above the other below); the Cryolist and research news; a footer with the quote and the keys. Drawn again when its window changes width.
  - Keys: `c` calendar, `t` tasks, `m` Cryolist, `r` research news go to the card; `C-j`/`C-k` the next or previous item (an event, a task, a topic, an article), on to the next card after the last. `RET` on a heading opens what the card shows, on an item the item. `TAB` on a list shows all of it or cuts it again. `SPC s l` (link-hint) reaches the numbers of the Cryolist and research news.
  - Calendar: always this week first; `]`/`[` the next and previous week, `.` this one, anywhere on it; `RET` on its heading opens the week calendar there. Compact, an hour before the first event and after the last.
  - Tasks: the open TODOs, no calendar events. A deadline shows from its warning (`-3d` in `<2026-11-30 Mon ++1m -3d>`, else `org-deadline-warning-days`), first; then priority A, scheduled today or before, priority B, the rest. Out: habits, HOLD, WAIT, IDEA, a schedule later, a deadline not yet in its warning. Priority, title (with a state other than TODO), when and category in aligned columns. `RET` goes to the task. On a task, without leaving the dashboard: `,` sets the priority (`+`/`-` up and down), `s` schedules, `D` sets the deadline (`C-u` removes either), `T` changes the state; the file is saved. `p` cycles all, work, personal: a context is the tags in `anthe-dashboard-task-contexts` (work: `phd`, `work`; personal: `perso`, `finances`, `emacs`, `piano`, `music`, `goals`, `system`, `os`), inherited ones too. `d` the dashboard agenda, `w` the PhD agenda.
  - Cryolist: the latest digest from mu (in the background, every ten minutes at most), dated today, yesterday or N days ago. `RET` on its heading or a number opens the Cryolist's digests in mu4e (the `bc` search) with that digest open.
  - Research news: the research feed (`~/org/roam/digest/feed.org`), its new articles by score, then those to read. `RET` on the number opens the PDF if downloaded, else the article; hovering shows the journal, the score and the abstract. `l` to read later (its open PDF goes to `~/library/inbox`), `a` add to the library (the feed's topic), `n` its note in org-roam (added first), `R` read, `x` skip, `o` its entry in the feed. `l`, `a` and `n` sync at once.
- Library (python-utils' `research/library.py`): `~/library/science/TOPIC/` per large topic (glaciology, astronomy, machine-learning, statistics; a new name makes one), each with `TOPIC.bib`, `papers/` and `preprints/` (glaciology also `theses/`, `manuals/`); `~/library/research` and `research.bib` are links to glaciology, for the old paths. Each entry has its topic in `keywords` (a preprint also `preprint`), so citar finds a topic by its name; keys and DOIs are unique across all the bibs. citar reads every topic's bib, `textbooks.bib`, `cheatsheets.bib`, and `~/library/library.bib`, an index written daily of the ebooks, scores, languages and textbooks without an entry (a folder of 8 documents or more, a book in chapters, is one entry with all its files). The references of all, for the map, are in `~/library/science/references.json` (`research/graph.py`).
  - `SPC k c a`: add a DOI (from the region, point or clipboard by default), in the background. It says where the DOI already is, or asks the topic (OpenAlex suggests one), then adds the entry, its PDF (the open one, else the publisher's or Sci-Hub; a preprint only its open one), shows the entry at its keywords, and updates the map and the web app in the background. Also from qutebrowser, `,a`: the DOI selected, of the URL or of the page's meta tags (`qutebrowser/userscripts/add-doi`). Without BibTeX at doi.org yet (a new preprint), from OpenAlex.
  - In a PDF, a reference's DOI: `SPC m a` in pdf-view, `b` in zathura: one of the page's references (all the PDF's if the page has none), chosen, those already in the library marked ✓. With a reference selected (`SPC m a`, or `B` in zathura, which copies the selection): its DOI, else Crossref's match, confirmed (`anthe-bib-add-from-pdf`, `bin/zathura-doi`).
  - `SPC k c q`: add a DOI queued from the phone or the map (`~/org/library-queue.org`, synced); it leaves the queue once added. The dashboard's research news shows how many wait.
  - `SPC k c r`: the articles of my library nearest the entry at point, else one chosen: those it cites, those citing it, those sharing its references or cited with it (`research/graph.py related`); `RET` opens one with citar.
  - `SPC k c v`: the citation map, in the browser (at the entry at point).
  - The library on the phone: https://pi.tail47921c.ts.net:8443 (the tailnet only; to install as an app, then share a link to it to queue its DOI). Search as citar does (every word, any order), topics as chips, an entry with its PDFs, DOI, note and abstract; "To add" queues a DOI or an article's link for the laptop. The map (`map.html`): my articles linked by their citations, in clusters named by their titles' words, and as rings the classics I don't have (cited by 5 of mine or more), with "Add on the laptop". Night Owl. Written by `research/web.py` (`export`, `refresh`: the map too) in `~/library/.web`, after each add and by the feed's daily run; Syncthing sends `~/library` one way to the pi (`/mnt/storage1/anthe/library`), where `libweb/server.py` serves it (`library-web.service`, `web.py deploy` to update it).
  - `SPC k c n`: the org-roam note of the entry at point (a citation, a BibTeX entry), else one chosen; made if none: `NOTER_DOCUMENT` the PDF, links to the PDF, the DOI and the entry, then Summary, Notes and the abstract (from the feed, else OpenAlex) (`anthe-bib.el`, in place of citar-org-roam's).
- Research feed (python-utils' `research/feed.py`, config `rcfiles/research-feed.toml`, a daily timer at 7:00, `rcfiles/systemd/`): the new works of the field's journals and of EGUsphere and ESS Open Archive, from OpenAlex, and the other journals' by search phrases. Scored by the keywords (twice in the title) and by how many works of the topic's bib (`topic` in the config, glaciology) they cite; only with an ice or polar word, never conference abstracts, comments, corrections; datasets only from PANGAEA and USAP-DC. Written to `~/org/roam/digest/feed.org`, the best first, each with its DOI, journal, authors, score, abstract and open PDF. Its states, set in Emacs or on the phone: `LATER` downloads the open PDF to `~/library/inbox`, `ADD` adds to the library as `SPC k c a` does (the inbox PDF moved), then `ADDED`; `READ`; `SKIP`, pruned after a month. Once a week, a preprint of the library published since is replaced by its article (Crossref), in the same bib; its old key kept in `ids` if it changes. Each run also writes `~/library/library.bib`, the map and the web app's data. `python -m python_utils.research.feed fetch|sync|reconcile|run|add DOI`. The Monday Scholar summary (Mistral) no longer runs.
- A project always opens in its own workspace (`+workspaces-on-switch-project-behavior`), never in an empty main one; main is made again if gone, and kept first (`anthe-workflow.el`). A project with a workspace already open goes to it, with `SPC p p` or `SPC o c`: Doom knew it only by a parameter that a recycled or restored workspace lacks, and made a second one ("python/anta_database").
- Backup (`bin/backup`, restic, `rcfiles/systemd/backup.timer` at 21:00 or the next boot): a snapshot of `~` in `pi:/mnt/storage1/anthe/restic`, without caches, reinstallable toolchains and `~/data/isochrones` (`rcfiles/restic/excludes`); 7 daily, 8 weekly, 12 monthly kept, pruned on Sundays. `backup snapshots`, `backup restore latest --include PATH --target DIR`, `backup mount DIR` to browse them; the password in `~/.secrets/restic-password` (keep a copy off the laptop). A notification if it fails.
- Archive (`bin/archive`): `archive put DIR` moves a folder rarely needed to the pi (`/mnt/storage1/anthe/archive`, same path under `~`), checked byte for byte, and leaves a link to `~/nas/DIR`, the archive mounted on demand (`nas.service`, rclone, files read cached up to 20 GB); `archive get DIR` brings it back; `archive ls`. Not in the snapshots: on the pi only, until it has a second disk.
- doom doctor: `anthe-pdf.el` no longer fails in a batch Emacs, which has no colours.
- UBELIX (`anthe-vterm.el`, `bin/hpc-session` on the hpc branch): `SPC k h` shows the `UBELIX` vterm, attached to the tmux session there (made and attached if missing, attached again if left). While attached, the buffer is in Emacs state: every key goes to UBELIX's Emacs or Neovim, also `C-u`, `C-g`, `C-x`, `C-c`, `C-h`, `C-l`, `M-x`, `M-1`…`M-9` (`M-SPC` is the leader, `M-SPC :` the local `M-x`, `C-M-1`…`C-M-9` or `M-SPC TAB` the local workspaces, `C-z` gives the keys back to evil); detached or disconnected, it is `UBELIX (left)`, evil again. In a vterm, `C-b` and the next key go to tmux in normal state too. Neovim in a vterm gets every key while it runs (it tells Emacs).
