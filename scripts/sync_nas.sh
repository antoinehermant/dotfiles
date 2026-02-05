#!/usr/bin/env sh

# '''The relative flag allows to preserve the relative path from the source to the destination.
# This requires the /./ in the source. e.g. /home/anthe/phd/bib will be correctly sent to /mnt/storage1/anthe/phd/bib, while we are not syncing the whole phd dir'''
SOURCE="/home/anthe/./roam /home/anthe/./org /home/anthe/./phd/bib"
DESTINATION="pi:/mnt/storage1/anthe"
LOG_FILE="/home/anthe/.sync.log"

if ping -c 1 192.168.0.100 &> /dev/null; then
    echo "$(date): Starting rsync backup..."
    echo "$(date): Starting rsync backup..." > "$LOG_FILE"
    rsync -avz --relative --delete $SOURCE "$DESTINATION" >> "$LOG_FILE" 2>&1
    echo "$(date): Backup completed."
    echo "$(date): Backup completed." >> "$LOG_FILE"
else
    echo "$(date): NAS not reachable, skipping backup."
    echo "$(date): NAS not reachable, skipping backup." >> "$LOG_FILE"
fi
