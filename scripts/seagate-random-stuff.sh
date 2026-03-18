#!/usr/bin/env bash
# 1. Create "random stuff", move everything not in organized (and not system) into it.
# 2. Delete from "random stuff" any file that is a duplicate of a file in organized.
# 3. Inside "random stuff", organize by file type (folders named by type).
# Usage: ./seagate-random-stuff.sh [--dry-run]

set -euo pipefail

DRIVE="/Volumes/Seagate"
ORGANIZED="$DRIVE/organized"
RANDOM_STUFF="$DRIVE/random stuff"
DRY_RUN=false

ORGANIZE_ONLY=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --organize-only) ORGANIZE_ONLY=true ;;
    -h|--help)
      echo "Usage: $0 [--dry-run] [--organize-only]"
      echo "  --organize-only  Skip move and delete; only organize random stuff by type"
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

[[ -d "$DRIVE" ]] || { echo "Seagate drive not found at $DRIVE"; exit 1; }
[[ -d "$ORGANIZED" ]] || { echo "organized folder not found"; exit 1; }

if ! "$ORGANIZE_ONLY"; then
echo "=== Creating 'random stuff' and moving remaining content ==="
run mkdir -p "$RANDOM_STUFF"

# Skip system/hidden and our own folders
skip_item() {
  case "$1" in
    .*|organized|"random stuff"|\$RECYCLE.BIN|"System Volume Information") return 0 ;;
    *) return 1 ;;
  esac
}

for item in "$DRIVE"/*; do
  [[ -e "$item" ]] || continue
  base=$(basename "$item")
  skip_item "$base" && continue
  [[ "$item" == "$ORGANIZED" ]] && continue
  [[ "$item" == "$RANDOM_STUFF" ]] && continue
  run mv "$item" "$RANDOM_STUFF/"
  echo "  Moved: $base"
done

echo ""
echo "=== Removing duplicates of organized content from random stuff ==="
# Build set of size:basename from organized (parallel stat for speed)
echo "  Building size+name set from organized..."
SIZELIST=$(mktemp)
find "$ORGANIZED" -type f ! -name "._*" -print0 2>/dev/null | xargs -0 -n 1 -P 8 sh -c 's=$(stat -f "%z" "$1" 2>/dev/null); [ -n "$s" ] && echo "${s}:$(basename "$1")"' _ | sort -u > "$SIZELIST"
count_hashes=$(wc -l < "$SIZELIST")
echo "  Found $count_hashes unique size+name entries in organized."

# Delete from random stuff any file with same size+basename as in organized
deleted=0
while IFS= read -r -d '' f; do
  [[ -f "$f" ]] || continue
  [[ "$f" == */.Trashes/* ]] && continue
  size=$(stat -f "%z" "$f" 2>/dev/null) || continue
  base=$(basename "$f")
  key="${size}:${base}"
  if grep -qFx "$key" "$SIZELIST" 2>/dev/null; then
    run rm -f "$f"
    ((deleted++)) || true
    [[ $((deleted % 1000)) -eq 0 ]] && echo "  Deleted $deleted duplicates..."
  fi
done < <(find "$RANDOM_STUFF" -type f ! -name "._*" -print0 2>/dev/null)
rm -f "$SIZELIST"
echo "  Deleted $deleted duplicate files."

fi
echo ""
echo "=== Organizing random stuff by file type ==="
get_type_folder() {
  local ext
  ext=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  case "$ext" in
    pdf) echo "PDF" ;;
    doc|docx) echo "Documents" ;;
    xls|xlsx) echo "Spreadsheets" ;;
    ppt|pptx) echo "Presentations" ;;
    txt|rtf) echo "Text" ;;
    zip|rar|7z|tar|gz) echo "Archives" ;;
    jpg|jpeg|png|gif|bmp|tiff|heic) echo "Images" ;;
    mp3|m4a|opus|ogg|wav|flac) echo "Audio" ;;
    mp4|mov|avi|mkv|m4v|wmv) echo "Videos" ;;
    *) echo "Other" ;;
  esac
}

for type_dir in PDF Documents Spreadsheets Presentations Text Archives Images Audio Videos Other; do
  run mkdir -p "$RANDOM_STUFF/$type_dir"
done

n=0
while IFS= read -r f; do
  [[ -f "$f" ]] || continue
  dir=$(dirname "$f")
  parent=$(basename "$dir")
  case "$parent" in
    PDF|Documents|Spreadsheets|Presentations|Text|Archives|Images|Audio|Videos|Other) continue ;;
  esac
  base=$(basename "$f")
  [[ "$base" == ._* ]] && continue
  ext="${base##*.}"
  [[ "$base" == "$ext" ]] && ext=""
  type_dir=$(get_type_folder "$ext")
  dest="$RANDOM_STUFF/$type_dir/$base"
  if [[ -f "$dest" ]]; then
    name="${base%.*}"
    i=1
    while [[ -f "$RANDOM_STUFF/$type_dir/$name ($i).$ext" ]]; do ((i++)) || true; done
    dest="$RANDOM_STUFF/$type_dir/$name ($i).$ext"
  fi
  if run mv "$f" "$dest"; then
    ((n++)) || true
    [[ $((n % 500)) -eq 0 ]] && echo "  Organized $n files..."
  else
    echo "  Skip: $base" >&2
  fi
done < <(find "$RANDOM_STUFF" -type f ! -name "._*" ! -path "*/.Trashes/*" 2>/dev/null)

echo "  Removing empty directories..."
find "$RANDOM_STUFF" -depth -type d -empty 2>/dev/null | while IFS= read -r d; do
  [[ "$d" != "$RANDOM_STUFF" ]] && run rmdir "$d" 2>/dev/null || true
done

echo ""
echo "=== Done ==="
echo "Random stuff: $RANDOM_STUFF"
if "$DRY_RUN"; then
  echo "Run without --dry-run to apply."
fi
