#!/opt/nas-power/venv/bin/python
"""Switch the Pi's USB disk on and off from its Tapo strip socket, smoothly.

A small web page on the WireGuard address (http://10.158.145.1:8095), for
the phone and the laptop (SPC k t d in Emacs, anthe-control.el):

- on: the socket on; the disk mounts by itself as it appears (the udev rule
  90-storage1.rules), and Immich starts with it (immich.service).
- off: Immich stops and the disk unmounts (stopping mnt-storage1.mount
  stops what binds to it first), the disk parks its heads and leaves the
  kernel, and only then the socket goes off. If something still uses the
  disk, nothing is switched off and the page says what.

GET / is the page, GET /status the same as JSON, POST /on and /off the
actions, answered in plain text unless asked from the page.

The strip's credentials are in /etc/nas-power/tapo, lines as
TAPO_USERNAME,<value> (TAPO_PASSWORD and TAPO_STRIPE_IP too), read by
anthe only. Installed to /opt/nas-power with nas-power.service; tapo is in
the venv /opt/nas-power/venv.
"""

import asyncio
import csv
import html
import json
import os
import shutil
import subprocess
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlsplit

from tapo import ApiClient

ADDRESS = ("10.158.145.1", 8095)
CREDENTIALS = "/etc/nas-power/tapo"
SOCKET = "drive_1"  # the socket's name in the Tapo app
DISK = "/dev/disk/by-id/wwn-0x50014ee6ad77c433"  # WD20EZRX
MOUNT = "/mnt/storage1"
MOUNT_UNIT = "mnt-storage1.mount"
MOUNT_WAIT = 90  # seconds for the disk to spin up and mount
TAPO_TIMEOUT = 5

lock = threading.Lock()  # one switch at a time


# The strip

async def _socket(state=None):
    """The socket's state, after switching it to STATE (True or False) if given."""
    with open(CREDENTIALS) as f:
        c = dict(csv.reader(f))
    client = ApiClient(c["TAPO_USERNAME"], c["TAPO_PASSWORD"], timeout_s=TAPO_TIMEOUT)
    strip = await client.p300(c["TAPO_STRIPE_IP"])
    for child in await strip.get_child_device_list():
        if child.nickname == SOCKET:
            if state is not None and state != child.device_on:
                plug = await strip.plug(device_id=child.device_id)
                await (plug.on() if state else plug.off())
                return state
            return child.device_on
    raise LookupError(f"no socket named {SOCKET} on the strip")


def socket(state=None):
    return asyncio.run(_socket(state))


# The disk

def run(*command):
    return subprocess.run(command, capture_output=True, text=True, timeout=120)


def disk_status():
    """Whether the disk is there, spinning and mounted, its space, health and
    temperature. Asked without waking it up: smartctl -n standby doesn't."""
    status = {"present": os.path.exists(DISK), "mounted": os.path.ismount(MOUNT)}
    if status["present"]:
        smart = run("sudo", "-n", "smartctl", "-n", "standby", "-H", "-A", DISK)
        status["spinning"] = "STANDBY" not in smart.stdout
        for line in smart.stdout.splitlines():
            if "overall-health" in line:
                status["health"] = line.rsplit(":", 1)[1].strip()
            elif "Temperature_Celsius" in line:
                status["temperature"] = int(line.split()[9])
            elif "Reallocated_Sector_Ct" in line or "Current_Pending_Sector" in line:
                status.setdefault("bad_sectors", 0)
                status["bad_sectors"] += int(line.split()[9])
    if status["mounted"]:
        usage = shutil.disk_usage(MOUNT)
        status["used_gb"], status["total_gb"] = usage.used // 10**9, usage.total // 10**9
    return status


def status():
    try:
        plug = socket()
    except Exception as e:  # the strip may not answer
        plug = f"unknown ({e})"
    return {"socket": plug, **disk_status()}


def switch_on():
    if socket(True) and os.path.ismount(MOUNT):
        return "The disk is already on and mounted."
    for _ in range(MOUNT_WAIT):
        if os.path.ismount(MOUNT):
            return f"The disk is on and mounted on {MOUNT}."
        time.sleep(1)
    return (f"The socket is on but the disk didn't mount within {MOUNT_WAIT} s: "
            "see journalctl -b -u mnt-storage1.mount on the Pi.")


def switch_off():
    if os.path.ismount(MOUNT):
        # Immich first, even while it is still starting, then the disk
        run("sudo", "-n", "systemctl", "stop", "immich.service", MOUNT_UNIT)
        if os.path.ismount(MOUNT):
            users = run("sudo", "-n", "fuser", "-vm", MOUNT)
            return ("The disk is still in use, so it stays on:\n"
                    + (users.stderr + users.stdout).strip())
    if os.path.exists(DISK):
        device = os.path.basename(os.path.realpath(DISK))
        run("sync")
        # Heads parked before the power goes, then the kernel lets it go,
        # rather than seeing it vanish
        run("sudo", "-n", "/usr/sbin/hd-idle", "-t", f"/dev/{device}")
        run("sudo", "-n", "sh", "-c", f"echo 1 > /sys/block/{device}/device/delete")
        time.sleep(2)
    socket(False)
    return "The disk is unmounted and off."


# The page

PAGE = """<!doctype html>
<html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Pi disk</title>
<style>
 body {{ font-family: sans-serif; max-width: 28em; margin: 2em auto; padding: 0 1em;
        background: #011627; color: #d6deeb; }}
 td {{ padding: .2em .8em .2em 0; }} td:first-child {{ color: #8a9ba8; }}
 button {{ font-size: 1.2em; padding: .5em 1.2em; margin: .5em .5em 0 0; }}
 pre {{ white-space: pre-wrap; background: #0b2942; padding: .8em; }}
 a {{ color: #82aaff; }}
</style></head><body>
<h1>Pi disk</h1>
{message}
<table>{rows}</table>
<form method="post">
 <button formaction="/on">On</button>
 <button formaction="/off">Off</button>
</form>
<p><a href="/">Refresh</a></p>
</body></html>
"""


def page(message=""):
    s = status()
    def yes(value):
        return "yes" if value is True else "no" if value is False else str(value)
    rows = [("Socket", yes(s["socket"])), ("Disk present", yes(s["present"])),
            ("Mounted", yes(s["mounted"]))]
    if s["present"]:
        rows.append(("Spinning", yes(s["spinning"])))
        if "health" in s:
            rows += [("Health", s["health"]), ("Temperature", f"{s.get('temperature', '?')} °C"),
                     ("Bad sectors", s.get("bad_sectors", "?"))]
        else:
            rows.append(("Health", "asked once it spins (not to wake it)"))
    if s["mounted"]:
        rows.append(("Used", f"{s['used_gb']} of {s['total_gb']} GB"))
    return PAGE.format(
        message=f"<pre>{html.escape(message)}</pre>" if message else "",
        rows="".join(f"<tr><td>{k}</td><td>{html.escape(str(v))}</td></tr>" for k, v in rows))


class Handler(BaseHTTPRequestHandler):
    def reply(self, body, kind="text/plain", code=200):
        data = body.encode()
        self.send_response(code)
        self.send_header("Content-Type", f"{kind}; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        path = urlsplit(self.path).path
        if path == "/":
            self.reply(page(), "text/html")
        elif path == "/status":
            self.reply(json.dumps(status()), "application/json")
        else:
            self.reply("Not found\n", code=404)

    def do_POST(self):
        action = {"/on": switch_on, "/off": switch_off}.get(urlsplit(self.path).path)
        if not action:
            return self.reply("Not found\n", code=404)
        # Not from another site the browser happens to be on
        origin = self.headers.get("Origin")
        if origin and urlsplit(origin).netloc != self.headers.get("Host"):
            return self.reply("Forbidden\n", code=403)
        length = int(self.headers.get("Content-Length") or 0)
        self.rfile.read(length)
        if not lock.acquire(blocking=False):
            message = "Already switching, try again in a minute."
        else:
            try:
                message = action()
            except Exception as e:
                message = f"Failed: {e}"
            finally:
                lock.release()
        if "text/html" in self.headers.get("Accept", ""):
            self.reply(page(message), "text/html")
        else:
            self.reply(message + "\n")


if __name__ == "__main__":
    ThreadingHTTPServer(ADDRESS, Handler).serve_forever()
