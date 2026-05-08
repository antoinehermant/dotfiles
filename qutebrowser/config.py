#!/usr/bin/env python3

from typing import Never


config.load_autoconfig()

config.source('qutebrowser-themes/themes/onedark.py')

config.set("colors.webpage.darkmode.enabled", True)
config.set("colors.webpage.darkmode.policy.images", "never")
config.set("fonts.default_size", "14pt")

# Rebind arrow keys in popup menus (hints, downloads, etc.)
config.bind('<Ctrl-j>', 'completion-item-focus next', mode='command')
config.bind('<Ctrl-k>', 'completion-item-focus prev', mode='command')

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
