#!/usr/bin/env bash
#
# Extract music from iPad using libimobiledevice (idevicebackup2).
# 1. Creates an unencrypted backup from the connected device into ./ipad-backup
# 2. Runs the music extractor on that backup
#
# Requires: idevicebackup2, idevice_id (Homebrew: libimobiledevice)
# Connect your iPad via USB and trust this Mac before running.
#
# Usage: ./ipad-music-via-libimobiledevice.sh
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXTRACT_SCRIPT="$SCRIPT_DIR/extract-music-from-ipad-backup.sh"
BACKUP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)/ipad-backup"

echo "Checking for connected iOS device..."
if ! idevice_id -l 2>/dev/null | grep -q .; then
  echo "No device found. Connect your iPad via USB, unlock it, and tap Trust if asked."
  exit 1
fi

echo "Device found. Creating backup to: $BACKUP_DIR"
echo "(This can take several minutes. Do not unplug the device.)"
echo ""

mkdir -p "$BACKUP_DIR"
# Unencrypted backup: no password
idevicebackup2 backup "$BACKUP_DIR"

echo ""
echo "Backup finished. Extracting music..."
echo ""

"$EXTRACT_SCRIPT" "$BACKUP_DIR"
