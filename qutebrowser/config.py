#!/usr/bin/env python3

import os
from typing import Never

config.load_autoconfig()

config.source("qutebrowser-themes/themes/onedark.py")

config.set("colors.webpage.darkmode.enabled", True)

config.set("colors.webpage.darkmode.policy.images", "never")
config.set("fonts.default_size", "11.5pt")

# Rebind arrow keys in popup menus (hints, downloads, etc.)
config.bind("<Ctrl-j>", "completion-item-focus next", mode="command")
config.bind("<Ctrl-k>", "completion-item-focus prev", mode="command")

# The file prompt (downloads) like Emacs' completion: TAB, C-j and C-k go through the
# candidates, C-h goes up a directory. In EXWM, Emacs asks instead (anthe-qutebrowser.el)
config.bind("<Ctrl-j>", "prompt-item-focus next", mode="prompt")
config.bind("<Ctrl-k>", "prompt-item-focus prev", mode="prompt")
config.bind("<Ctrl-h>", "rl-filename-rubout", mode="prompt")

config.bind(",ps", "set content.proxy socks5://localhost:1080;; reload")
config.bind(",pd", "set content.proxy system;; reload")
config.bind(",d", "config-cycle colors.webpage.darkmode.enabled")

# "d" and "D" are Emacs's (anthe-qutebrowser.el): they close the window and show the next or
# previous one. Qutebrowser's own "d" closed it when typing outside insert mode
# config.unbind("d")

config.bind(",ff", "spawn firefox {url}")
# The article of the page to my library, in Emacs (userscripts/add-doi)
config.bind(",a", "spawn --userscript add-doi")

c.bindings.key_mappings = {"<Ctrl-G>": "<Escape>"}

# "gh pism/pism" opens that repo, "gh antoinehermant" a profile
c.url.searchengines["gh"] = "https://github.com/{unquoted}"
# "ph 2025 christmas" shows the photos of 2025 tagged christmas, in Immich on
# the Pi, through its search bar (pi/immich-bar)
c.url.searchengines["ph"] = "http://10.158.145.1:2284/bar/?q={}"

# Paste the clipboard like Emacs' yank
config.bind("<Ctrl-y>", "insert-text {clipboard}", mode="insert")
config.bind("<Ctrl-y>", "cmd-set-text -a {clipboard}", mode="command")

# qutebrowser.el config
c.tabs.tabs_are_windows = True
c.tabs.show = "multiple"
c.statusbar.show = "always"
c.new_instance_open_target = "tab-silent"
config.source("emacs_theme.py")

# DuckDuckGo and the bars in its colours, see-through (look.py); also sourced
# at the end of emacs_theme.py, so that they follow a change of theme
config.source(os.path.expanduser("~/.dotfiles/qutebrowser/look.py"))
# config.source("emacs_rpc.py")
# config.source("emacs_hooks.py")
# config.bind("o", "emacs '(qutebrowser-launcher)'")
# config.bind("O", "emacs '(qutebrowser-launcher-tab)'")
# config.bind("wo", "emacs '(qutebrowser-launcher-window)'")
# config.bind("W", "emacs '(qutebrowser-launcher-private)'")
# config.bind("go", "emacs '(qutebrowser-launcher \"{url:pretty}\")'")
# config.bind("gO", "emacs '(qutebrowser-launcher-tab \"{url:pretty}\")'")

# config.set('content.dns.override_system_dns', False)

# Enable uBlock Origin filters
# config.set('content.blocking.method', 'both')
# config.set('content.blocking.adblock.lists', [
# 'https://easylist.to/easylist/easylist.txt',
# 'https://easylist.to/easylist/easyprivacy.txt',
# 'https://easylist.to/easylist/fanboy-social.txt',
# 'https://secure.fanboy.co.nz/fanboy-annoyance.txt',
# 'https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt',
# 'https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters-2020.txt',
# 'https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/legacy.txt',
# 'https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/privacy.txt',
# 'https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/annoyances.txt',
# 'https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/badware.txt',
# 'https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/resource-abuse.txt',
# 'https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/unbreak.txt',
# ])

# config.set('content.blocking.adblock.lists', [
#     # ... (keep the existing lists)
#     'https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/youtube.txt',
# ])

# config.set('content.proxy', f'socks://localhost:1080')
