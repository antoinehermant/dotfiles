#!/usr/bin/env sh

SOURCE="/home/anthe/roam /home/anthe/org"
DESTINATION="pi:/mnt/storage1/anthe"
LOG_FILE="/home/anthe/.sync.log"

if ping -c 1 192.168.0.100 &> /dev/null; then
    echo "$(date): Starting rsync backup..." > "$LOG_FILE"
    rsync -avz --delete $SOURCE "$DESTINATION" >> "$LOG_FILE" 2>&1
    echo "$(date): Backup completed." >> "$LOG_FILE"
else
    echo "$(date): NAS not reachable, skipping backup." >> "$LOG_FILE"
fi
