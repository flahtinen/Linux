#!/bin/bash
set -e

DATE=$(date +%Y%m%d-%H%M%S)
ARCHIVE="/tmp/website-$DATE.tar.gz"
LOG="/var/log/website-backup.log"

echo "[$(date)] Varmuuskopiointi alkaa" >> "$LOG"

tar -czf "$ARCHIVE" -C /var/www html
chown backupuser:backupuser "$ARCHIVE"
chmod 600 "$ARCHIVE"

sudo -u backupuser scp -i /home/backupuser/.ssh/id_ed25519 \
    -o StrictHostKeyChecking=accept-new \
    "$ARCHIVE" backupuser@192.168.1.176:/var/backups/website/

rm -f "$ARCHIVE"

echo "[$(date)] Varmuuskopiointi onnistui: website-$DATE.tar.gz" >> "$LOG"
