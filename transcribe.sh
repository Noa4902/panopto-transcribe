#!/usr/bin/env bash
#
# panopto-transcribe — download a Panopto recording, transcribe it locally, clean up.
# Everything runs on your machine. Zero cost, no API, no media ever leaves your computer.
#
# Usage:
#   ./transcribe.sh "<panopto-url>"
#
# The URL can be a single video or a folder (a link with #folderID=...).
# For a folder, every video inside it is transcribed.
#
# Configuration (override via environment variables):
#   COOKIES        path to your cookies file   (default: cookies.txt)
#   WHISPER_MODEL  path to the whisper model    (default: ~/whisper-models/ggml-large-v3-turbo.bin)
#   LANG_CODE      transcription language       (default: he)
#   OUTDIR         output directory             (default: transcripts)

set -euo pipefail

COOKIES="${COOKIES:-cookies.txt}"
WHISPER_MODEL="${WHISPER_MODEL:-$HOME/whisper-models/ggml-large-v3-turbo.bin}"
LANG_CODE="${LANG_CODE:-he}"
OUTDIR="${OUTDIR:-transcripts}"

die() { echo "❌ $*" >&2; exit 1; }

# --- Preflight checks ---
URL="${1:-}"
[[ -n "$URL" ]] || die "Missing URL. Usage: ./transcribe.sh \"<panopto-url>\""

for cmd in yt-dlp ffmpeg whisper-cli; do
  command -v "$cmd" >/dev/null 2>&1 || die "'$cmd' is not installed. See the README, Installation section."
done

[[ -f "$WHISPER_MODEL" ]] || die "Whisper model not found at $WHISPER_MODEL. See the README, Installation section."

if [[ ! -f "$COOKIES" ]]; then
  die "No cookies file found at $COOKIES.
   This part is on you: install the \"Get cookies.txt LOCALLY\" extension,
   export your Panopto cookies, and save them as cookies.txt here.
   Full instructions in the README."
fi

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
mkdir -p "$OUTDIR"

# --- Step 1: download ---
# Panopto does not serve a clean audio-only format, so we grab the smallest video (-f worst).
echo "⬇️  Downloading from Panopto..."
yt-dlp --cookies "$COOKIES" -f worst \
  -o "$WORKDIR/%(title)s.%(ext)s" "$URL"

# --- Steps 2+3+4: for each video, extract audio -> transcribe -> clean up ---
shopt -s nullglob
videos=("$WORKDIR"/*)
[[ ${#videos[@]} -gt 0 ]] || die "yt-dlp downloaded nothing. Check the URL and that your cookies are still valid."

for video in "${videos[@]}"; do
  base="$(basename "${video%.*}")"
  out="$OUTDIR/$base.txt"

  # Already transcribed -> skip (idempotent: safe to re-run without re-transcribing).
  if [[ -f "$out" ]]; then
    echo "⏭️  Already exists, skipping: $base"
    continue
  fi

  wav="$WORKDIR/$base.wav"
  echo "🎧 Extracting audio: $base"
  ffmpeg -i "$video" -ar 16000 -ac 1 -c:a pcm_s16le "$wav" -y -loglevel error

  echo "📝 Transcribing: $base"
  whisper-cli -m "$WHISPER_MODEL" -l "$LANG_CODE" -f "$wav" -otxt -of "$OUTDIR/$base"

  rm -f "$video" "$wav"
  echo "✅ Saved: $out"
done

echo "🎉 Done. Transcripts are in $OUTDIR/"
