#!/usr/bin/env bash
#
# Extract music (.m4a, .mp3) from a local iPad backup.
# Run this AFTER creating an unencrypted backup in Finder:
#   Finder → iPad → Back Up Now (with "Encrypt local backup" UNCHECKED)
#
# Usage:
#   ./extract-music-from-ipad-backup.sh                    # use default MobileSync backup
#   ./extract-music-from-ipad-backup.sh --scan             # scan default backup
#   ./extract-music-from-ipad-backup.sh /path/to/backup    # use this backup dir (e.g. idevicebackup2)
#   ./extract-music-from-ipad-backup.sh --scan /path/to/backup
#

set -e

DEST="$HOME/Desktop/Recovered Music"
SCAN_ONLY=false
BACKUP_ROOT=""

if [[ "${1:-}" == "--scan" ]]; then
  SCAN_ONLY=true
  shift
fi
if [[ -d "${1:-}" ]]; then
  BACKUP_ROOT="$1"
fi
if [[ -z "$BACKUP_ROOT" ]]; then
  BACKUP_ROOT="$HOME/Library/Application Support/MobileSync/Backup"
fi

echo "Looking for backups in: $BACKUP_ROOT"
echo ""

if [[ ! -d "$BACKUP_ROOT" ]]; then
  echo "Backup folder not found. Create a backup first (Finder or: idevicebackup2 backup <dir>)."
  exit 1
fi

# One or more backup folders: custom path = single tree; default = one subdir per device
shopt -s nullglob
if [[ "$BACKUP_ROOT" != "$HOME/Library/Application Support/MobileSync/Backup" ]]; then
  backups=("$BACKUP_ROOT")
else
  backups=("$BACKUP_ROOT"/*/)
fi
shopt -u nullglob

if [[ ${#backups[@]} -eq 0 ]]; then
  echo "No backup folders found. Back up your iPad first (unencrypted)."
  exit 1
fi

# Detect audio by magic bytes (backup files often have no extension; file(1) may say application/octet-stream)
is_m4a() {
  local f="$1"
  # MP4/M4A: ... ftyp at offset 4
  [[ $(head -c 12 "$f" 2>/dev/null | od -An -tx1 | tr -d ' \n') == *"66747970"* ]] && return 0
  return 1
}
is_mp3() {
  local f="$1"
  local first
  first=$(head -c 3 "$f" 2>/dev/null | od -An -tx1 | tr -d ' \n')
  # ID3
  [[ "$first" == "494433"* ]] && return 0
  # MPEG frame sync FF E?
  [[ "$first" == "ffe"* ]] || [[ "$first" == "fff"* ]] && return 0
  return 1
}

if $SCAN_ONLY; then
  echo "Scanning file types in backup (this may take a minute)..."
  echo ""
  scan_tmp=$(mktemp)
  audio_candidates=0
  for backup_dir in "${backups[@]}"; do
    [[ -d "$backup_dir" ]] || continue
    while IFS= read -r -d '' f; do
      file -b --mime-type "$f" 2>/dev/null || echo "unknown"
      if is_m4a "$f" || is_mp3 "$f"; then audio_candidates=$((audio_candidates + 1)); fi
    done < <(find "$backup_dir" -type f -print0) >> "$scan_tmp"
  done
  echo "All MIME types in backup:"
  sort "$scan_tmp" | uniq -c | sort -rn | while read -r count mime; do echo "  $count  $mime"; done
  rm -f "$scan_tmp"
  echo ""
  echo "Files detected as audio by magic bytes (m4a/mp3): $audio_candidates"
  if [[ $audio_candidates -eq 0 ]]; then
    echo ""
    echo "No audio files found. Possible reasons:"
    echo "  — Music is from Apple Music (streaming) and is DRM-protected; it is not stored as plain files in the backup."
    echo "  — Music was never synced from this Mac; only synced or downloaded music appears in the backup."
    exit 0
  fi
  echo "Run without --scan to copy these to '$DEST'."
  exit 0
fi

mkdir -p "$DEST"
count_m4a=0
count_mp3=0

for backup_dir in "${backups[@]}"; do
  [[ -d "$backup_dir" ]] || continue
  echo "Searching in backup: $(basename "$backup_dir")"
  while IFS= read -r -d '' f; do
    base=$(basename "$f")
    # Prefer MIME from file(1)
    mime=$(file -b --mime-type "$f" 2>/dev/null) || mime=""
    copied=false
    if [[ "$mime" == "audio/mp4" ]] || [[ "$mime" == "audio/x-m4a" ]] || [[ "$mime" == "audio/aac" ]]; then
      if cp -n "$f" "$DEST/${base}.m4a" 2>/dev/null; then count_m4a=$((count_m4a + 1)); copied=true; fi
    elif [[ "$mime" == "audio/mpeg" ]]; then
      if cp -n "$f" "$DEST/${base}.mp3" 2>/dev/null; then count_mp3=$((count_mp3 + 1)); copied=true; fi
    fi
    # Fallback: detect by magic bytes (backup files often have no extension)
    if [[ "$copied" != "true" ]]; then
      if is_m4a "$f"; then
        if cp -n "$f" "$DEST/${base}.m4a" 2>/dev/null; then count_m4a=$((count_m4a + 1)); fi
      elif is_mp3 "$f"; then
        if cp -n "$f" "$DEST/${base}.mp3" 2>/dev/null; then count_mp3=$((count_mp3 + 1)); fi
      fi
    fi
  done < <(find "$backup_dir" -type f -print0)
done

total=$((count_m4a + count_mp3))
echo ""
echo "Done. Copied $total audio file(s) to: $DEST"
echo "  — .m4a (AAC): $count_m4a"
echo "  — .mp3:       $count_mp3"
if [[ $count_mp3 -eq 0 ]] && [[ $count_m4a -gt 0 ]]; then
  echo ""
  echo "  (No .mp3 is normal: Apple often stores synced music as .m4a only. Import the folder in Music the same way.)"
fi
echo ""
echo "Next steps:"
echo "  1. Open Music → File → Import → select '$DEST'"
echo "  2. File → Library → Show Duplicate Items → remove duplicates"
echo "  3. Connect iPad → Finder → iPad → Music → Sync music onto iPad → Apply"
