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
| `SPC j` / `SPC J` | qutebrowser launcher: URLs, bookmarks, history, open windows with preview / same in a new window | `anthe-qutebrowser.el` |
| `SPC ]` / `SPC [` | Next / previous code cell (Python or code-cells buffers) | `anthe-python.el` |
| `SPC r j`, `r b`, `r ]`, `r r` | Send line or region, buffer, cell; restart the shell (Python buffers) | `anthe-python.el` |
| `SPC r p`, `r J`, `r a` | Python REPL, Jupyter REPL, activate env (from anywhere) | `anthe-python.el` |
| `SPC w .` | Resize mode, for Emacs and EXWM windows: `hjkl` move the border, `HJKL` 3× more, `=` balance, `m` maximize, `u` undo, any other key leaves | `anthe-windows.el` |
| `SPC k …` | Rare actions: `k t` toggles (lamp, sound, drive, VPN, charger), `k r b` NAS backup, `k s f` face height, `k d` dashboard, `k o d` open externally, `k o m` system monitor | various |
| `SPC k q q/g` | squeue (HPC config) | `config-hpc.el` |
| `s-<escape>` | `exwm-reset`, the way back if a window gets stuck in char mode | `exwm/exwm-desktop.el` |

In qutebrowser windows (Evil normal state), see `anthe-qutebrowser.el`:
qutebrowser's own keys are sent to it, and prefixes like `g`, `;`, `,` list
the matching qutebrowser bindings at the bottom of the screen.

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
- **HPC.** `SPC k s` (sbatch) replaces the `SPC k s f` prefix from
  `config-core.el` there.
