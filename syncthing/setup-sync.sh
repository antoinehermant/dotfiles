#!/bin/bash
# Sync ~/org between laptop <-> pi (hub) <-> phone (OrgNote) with Syncthing.
# Run on the laptop: ./setup-sync.sh laptop
# Run for the pi:    ./setup-sync.sh pi   (installs over ssh)
set -euo pipefail

STIGNORE=~/.dotfiles/syncthing/stignore
# On the pi ~/org is a link used by the drive backup, so sync elsewhere (SD card)
PI_ORG_DIR=sync/org

case "${1:-}" in
    laptop)
        sudo apt install -y syncthing
        systemctl --user enable --now syncthing
        mkdir -p ~/org
        cp "$STIGNORE" ~/org/.stignore
        sleep 5
        echo "Laptop device ID: $(syncthing cli show system | grep -o '"myID": *"[^"]*"' | cut -d'"' -f4)"
        ;;
    pi)
        ssh pi "sudo apt install -y syncthing && sudo systemctl enable --now syncthing@\$USER && mkdir -p ~/$PI_ORG_DIR"
        scp "$STIGNORE" "pi:$PI_ORG_DIR/.stignore"
        sleep 5
        echo "Pi device ID: $(ssh pi syncthing cli show system | grep -o '"myID": *"[^"]*"' | cut -d'"' -f4)"
        echo "Pi GUI: ssh -L 8385:localhost:8384 pi, then open http://localhost:8385"
        ;;
    *)
        echo "Usage: $0 laptop|pi" >&2
        exit 1
        ;;
esac
