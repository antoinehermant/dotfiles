# Neovim

My light editor, on UBELIX above all, in the tmux session of
`bin/hpc-session` (hpc branch). LazyVim, with Doom's keys where I have them
in Emacs, and the Night Owl theme.

| Keys | |
|---|---|
| `SPC .` | find a file from the buffer's folder (oil's in oil): Tab into a folder, Backspace up, Enter opens a file, or a folder in oil, `~` home |
| `-`, `SPC -` | the file's folder in oil (dired: edit and `:w` to rename, move, delete) |
| `SPC f f`, `SPC f r`, `SPC b b`, `SPC b k`, `SPC b s` | files, recent, buffers, kill, save |
| `SPC s s`, `SPC s p`, `SPC /` | search the buffer, the project |
| `SPC p p` | projects |
| `SPC o t`, `SPC o T` | terminal popup, here or at the root |
| `SPC g g` | Neogit (magit) |
| `SPC o c`, `SPC a …` | Claude Code (needs `claude` on the PATH, logged in) |
| `SPC k q b`, `SPC k q q`, `SPC k q g` | sbatch this file, my queue, the group's (`r` in it: reload on/off) |

A `.nc` file opens in ncview (X forwarding: `hpc` connects with it).

On UBELIX, `$NVIM_LOCAL` (set by `hpc-session`) puts the plugins, syntax
parsers and language servers on the login node's local disk, unpacked from
one archive in the home (`bin/nvim-plugins`): the home's network storage is
slow to read many small files, 9 s to start from there, 0.1 s from the local
disk. After `:Lazy sync`, Neovim packs the archive again by itself.
