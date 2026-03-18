#!/usr/bin/env bash
# Organize Seagate drive: create organized/ with MP3, whatsapp audios, Images (by year), Videos
# Usage: ./organize-seagate.sh [--dry-run]
# Copies files (does not move). Excludes .Trashes, .Spotlight, ._* files.

set -euo pipefail

DRIVE="/Volumes/Seagate"
ORGANIZED="$DRIVE/organized"
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    -h|--help)
      echo "Usage: $0 [--dry-run]"
      exit 0 ;;
  esac
done

run() {
  if "$DRY_RUN"; then
    echo "[DRY-RUN] $*"
  else
    "$@"
  fi
}

# Copy file to dest, avoid overwrite by adding (1), (2) if needed. Skip if same file exists.
safe_copy() {
  local src="$1"
  local dest="$2"
  local base dir
  base="$(basename "$src")"
  dir="$(dirname "$dest")"
  dest="$dir/$base"
  if [[ -f "$dest" ]]; then
    # Same size = likely same file, skip to save time on resume
    if [[ "$(stat -f "%z" "$src" 2>/dev/null)" == "$(stat -f "%z" "$dest" 2>/dev/null)" ]]; then
      return 0
    fi
    local name="${base%.*}" ext="${base##*.}"
    [[ "$name" == "$ext" ]] && ext=""
    local i=1
    while [[ -f "$dir/$name ($i).$ext" ]]; do ((i++)) || true; done
    dest="$dir/$name ($i).$ext"
  fi
  run cp "$src" "$dest"
}

[[ -d "$DRIVE" ]] || { echo "Seagate drive not found at $DRIVE"; exit 1; }

echo "=== Creating organized structure on $DRIVE ==="
run mkdir -p "$ORGANIZED/MP3"
run mkdir -p "$ORGANIZED/whatsapp audios"
run mkdir -p "$ORGANIZED/Images"
run mkdir -p "$ORGANIZED/Videos"

# Normalize any files already in organized root (from previous runs)
for f in "$ORGANIZED"/*; do
  [ -f "$f" ] || continue
  base="$(basename "$f")"
  case "$base" in
    ._*) continue ;;
  esac
  ext="${base##*.}"
  lower="$(printf "%s" "$ext" | tr "A-Z" "a-z")"
  dest_dir=""
  case "$lower" in
    mp3) dest_dir="$ORGANIZED/MP3" ;;
    opus|ogg|m4a) dest_dir="$ORGANIZED/whatsapp audios" ;;
    jpg|jpeg|png|heic|gif|bmp|tiff) dest_dir="$ORGANIZED/Images" ;;
    mp4|mov|avi|mkv|m4v) dest_dir="$ORGANIZED/Videos" ;;
    *) ;;
  esac
  if [ -n "$dest_dir" ]; then
    run mkdir -p "$dest_dir"
    run mv "$f" "$dest_dir/"
  fi
done

echo ""
echo "=== Copying MP3 files ==="
count=0
while IFS= read -r -d '' f; do
  [[ -f "$f" ]] || continue
  case "$f" in
    */.Trashes/*|*/.Spotlight*|*/.fseventsd*|*/\$RECYCLE*|*/System\ Volume\ Information/*) continue ;;
  esac
  safe_copy "$f" "$ORGANIZED/MP3/"
  ((count++)) || true
  [[ $((count % 200)) -eq 0 ]] && echo "  ... $count MP3s"
done < <(find "$DRIVE" -type f -iname "*.mp3" ! -name "._*" -print0 2>/dev/null)
echo "  Done: $count MP3 files"

echo ""
echo "=== Copying WhatsApp audio files (whatsapp audios) ==="
count=0
while IFS= read -r -d '' f; do
  [[ -f "$f" ]] || continue
  case "$f" in
    */.Trashes/*|*/.Spotlight*|*/.fseventsd*) continue ;;
  esac
  safe_copy "$f" "$ORGANIZED/whatsapp audios/"
  ((count++)) || true
  [[ $((count % 500)) -eq 0 ]] && echo "  ... $count WhatsApp audio"
done < <(find "$DRIVE" -type f -path "*WhatsApp*" \( -iname "*.opus" -o -iname "*.ogg" -o -iname "*.m4a" \) ! -name "._*" -print0 2>/dev/null)
echo "  Done: $count WhatsApp audio files"

echo ""
echo "=== Copying images (sorted by year taken) ==="
get_year() {
  local f="$1"
  # Use birth time (when file was created) - fast, works on external drives
  local ts
  ts="$(stat -f "%B" "$f" 2>/dev/null)" || ts="$(stat -f "%m" "$f" 2>/dev/null)"
  date -r "$ts" "+%Y" 2>/dev/null || echo "Unknown"
}
count=0
while IFS= read -r -d '' f; do
  [[ -f "$f" ]] || continue
  case "$f" in
    */.Trashes/*|*/.Spotlight*|*/.fseventsd*) continue ;;
  esac
  year="$(get_year "$f")"
  [[ -z "$year" ]] && year="Unknown"
  run mkdir -p "$ORGANIZED/Images/$year"
  safe_copy "$f" "$ORGANIZED/Images/$year/"
  ((count++)) || true
  [[ $((count % 1000)) -eq 0 ]] && echo "  ... $count images"
done < <(find "$DRIVE" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.heic" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.tiff" \) ! -name "._*" -print0 2>/dev/null)
echo "  Done: $count image files"

echo ""
echo "=== Copying video files ==="
count=0
while IFS= read -r -d '' f; do
  [[ -f "$f" ]] || continue
  case "$f" in
    */.Trashes/*|*/.Spotlight*|*/.fseventsd*) continue ;;
  esac
  safe_copy "$f" "$ORGANIZED/Videos/"
  ((count++)) || true
  [[ $((count % 500)) -eq 0 ]] && echo "  ... $count videos"
done < <(find "$DRIVE" -type f \( -iname "*.mp4" -o -iname "*.mov" -o -iname "*.avi" -o -iname "*.mkv" -o -iname "*.m4v" \) ! -name "._*" -print0 2>/dev/null)
echo "  Done: $count video files"

echo ""
echo "=== Done ==="
echo "Organized folder: $ORGANIZED"
if "$DRY_RUN"; then
  echo "Run without --dry-run to apply."
fi
