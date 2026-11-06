#!/usr/bin/env bash
# Local WSL launcher; run with bash, so executable permissions are optional.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
fail() { printf "Error: %s\n" "$*" >&2; exit 1; }
open_output=0
if [[ "${1:-}" == "--open-output" ]]; then open_output=1; shift; fi
[[ $# -le 1 ]] || fail "Usage: bash run-local.sh [--open-output] [Panopto-URL]"
WHISPER_BUILD="${WHISPER_BUILD:-build-cuda}"
export PATH="$ROOT/.venv/bin:$HOME/tools/whisper.cpp/$WHISPER_BUILD/bin:$PATH"
export WHISPER_MODEL="${WHISPER_MODEL:-$HOME/tools/whisper.cpp/models/ggml-large-v3-turbo.bin}"
export COOKIES="${COOKIES:-$HOME/.config/panopto-transcribe/cookies.txt}"
export LANG_CODE="${LANG_CODE:-he}"
export OUTDIR="${OUTDIR:-$ROOT/transcripts}"
for tool in yt-dlp ffmpeg whisper-cli; do
  command -v "$tool" >/dev/null 2>&1 || fail "Missing $tool. Follow WINDOWS_GPU_CPU.md."
done
[[ -f "$ROOT/transcribe.sh" ]] || fail "transcribe.sh must be beside this launcher."
[[ -s "$WHISPER_MODEL" ]] || fail "Model not found: $WHISPER_MODEL"
[[ -s "$COOKIES" ]] || fail "Missing cookies file: $COOKIES. Export locally; never share it."
chmod 600 "$COOKIES" || fail "Cannot restrict cookies file permissions."
url="${1:-}"
if [[ -z "$url" ]]; then
  read -r -p "Paste a direct Panopto recording/folder URL, then press Enter: " url || fail "No input received."
fi
[[ -n "$url" ]] || fail "No URL provided."
if [[ "$url" == *"/mod/lti/"* ]]; then
  fail "This is a Moodle link. Open in Panopto (outward-arrow icon), then copy the Panopto URL."
fi
bash "$ROOT/transcribe.sh" "$url"
# Folder opening is optional and must not turn a successful transcription into failure.
if [[ "$open_output" == 1 ]]; then
  if command -v explorer.exe >/dev/null 2>&1 && command -v wslpath >/dev/null 2>&1; then
    if ! output_windows="$(wslpath -w "$OUTDIR")" || ! explorer.exe "$output_windows"; then
      printf "Transcript saved. Open the output folder manually: %s\n" "$OUTDIR" >&2
    fi
  else
    printf "Transcript saved. Output folder: %s\n" "$OUTDIR"
  fi
fi
