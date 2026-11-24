# qutebrowser's look, after Emacs's theme (emacs_theme.py, exported by
# qutebrowser.el when the theme changes, sources this at its end:
# anthe-qutebrowser.el); sourced by config.py too.
#
# pylint: disable=undefined-variable

# DuckDuckGo in the colours of Emacs's theme: its settings as URL parameters,
# colours in bare hex.  The dark mode stays off there, it would recolour them
def duckduckgo_url():
    def hex_(colour):
        return colour.lstrip("#")

    # Not the bars' background, made see-through below
    bg = c.colors.messages.info.bg
    r, g, b = (int(hex_(bg)[i:i + 2], 16) for i in (0, 2, 4))
    dark = 0.299 * r + 0.587 * g + 0.114 * b < 128
    params = {
        "kae": "d" if dark else "-1",
        "k7": hex_(bg),                                  # background
        "kj": hex_(bg),                                  # header
        "k8": hex_(c.colors.completion.fg),              # text
        "k9": hex_(c.colors.completion.match.fg),        # links
        "kaa": hex_(c.colors.statusbar.url.hover.fg),    # visited links
        "kx": hex_(c.colors.statusbar.url.fg),           # URLs
    }
    return "https://duckduckgo.com/?q={}&" + "&".join(f"{k}={v}" for k, v in params.items())


c.url.searchengines["DEFAULT"] = duckduckgo_url()
config.set("colors.webpage.darkmode.enabled", False, "*://duckduckgo.com/*")

# The window see-through where a page or the bars leave it so, the wallpaper
# blurred behind as Emacs's (picom): the bars at Emacs's alpha-background
# (85 %, anthe-transparency.el).  Takes a :restart
c.window.transparent = True


def translucent(colour, alpha=0.85):
    if not (isinstance(colour, str) and colour.startswith("#") and len(colour) == 7):
        return colour
    r, g, b = (int(colour[i:i + 2], 16) for i in (1, 3, 5))
    return f"rgba({r}, {g}, {b}, {alpha})"


for name in ("statusbar.normal.bg", "statusbar.insert.bg", "statusbar.command.bg",
             "statusbar.passthrough.bg", "statusbar.caret.bg",
             "completion.odd.bg", "completion.even.bg", "completion.category.bg"):
    config.set(f"colors.{name}", translucent(config.get(f"colors.{name}")))
