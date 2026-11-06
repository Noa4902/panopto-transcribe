# panopto-transcribe

Turn any Panopto lecture recording into a clean text transcript. **Fully local, free, no API.**

Built for students who can't make every lecture but refuse to fall behind. Point it at a Panopto video (or a whole folder), and it downloads, transcribes, and cleans up after itself. Your audio never leaves your machine.

yt-dlp downloads the recording, ffmpeg pulls the audio, and whisper.cpp writes the transcript. Everything runs on your laptop.

---

## Why

Every lecture at most universities is recorded on Panopto, but a recording you never watch is a gap you never close. Transcribing a 90-minute lecture by hand is hopeless, and cloud transcription services cost money and send your university content to a third party. This tool runs the entire pipeline on your own machine using [whisper.cpp](https://github.com/ggerganov/whisper.cpp), so it's free, private, and fast (~11x real-time on Apple Silicon).

## Features

- **Local and private.** Audio is processed on your machine and deleted afterward. Nothing is uploaded.
- **Free.** No API keys, no per-minute billing.
- **Folder-aware.** Pass a Panopto folder link and it transcribes every recording in it.
- **Idempotent.** Re-run it anytime; already-transcribed videos are skipped.
- **Tidy.** Video and audio files are removed after transcription, so your disk never balloons.

---

## Prerequisites (macOS)

You need three tools and one model file. Install the tools with [Homebrew](https://brew.sh):

```bash
brew install yt-dlp ffmpeg whisper-cpp
```

Then download a Whisper model (this one balances speed and quality well):

```bash
mkdir -p ~/whisper-models
curl -L -o ~/whisper-models/ggml-large-v3-turbo.bin \
  https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin
```

> The model is ~1.6 GB. You only download it once.

## Windows setup / התקנה ב-Windows

Community setup guides contributed by [Noa4902](https://github.com/Noa4902), based on Yam Meir's original project:

- **[English guide](WINDOWS_GPU_CPU.md)**
- **[מדריך בעברית](WINDOWS_GPU_CPU_HE.md)**

| Route | Validation status |
| --- | --- |
| NVIDIA GPU through WSL and Ubuntu 24.04 | Tested on one RTX 3070 Ti system: CUDA inference and one authenticated Panopto recording completed |
| CPU-only, without NVIDIA or CUDA | Documented alternative; **not tested by the contributor** |

The guides include private cookie storage outside the repository and instructions for creating a Windows double-click launcher. The launcher reached the URL prompt in testing; automatic folder opening after a full run has not yet been confirmed. The original transcription script is unchanged.

<div dir="rtl">

**למשתמשי Windows:** המדריך בעברית כולל התקנה, הגדרת תמלול לעברית והפעלה באמצעות הדבקת קישור. מסלול NVIDIA נבדק במחשב אחד; מסלול CPU לא נבדק על ידי תורמת המדריך. ההסברים כוללים גם את מגבלות הכלי ומה עדיין לא אומת.

</div>

The original author's [Windows instructions](WINDOWS.md) remain available and are labeled experimental. These community tests do not establish compatibility with every Windows computer or GPU.

---

## ⚠️ Your one responsibility: cookies

Panopto recordings are behind a login, so the tool needs **your** session cookies to access them. **You generate these yourself. They are never included in this repo and must never be shared.**

1. Install the **[Get cookies.txt LOCALLY](https://chromewebstore.google.com/detail/cclelndahbckbenkjhflpdbgdldlbecc)** Chrome extension (open source, exports locally, sends nothing to any server).
2. Open your university's Panopto site and sign in.
3. Click the extension, choose **Export**, then pick your Panopto domain.
4. Save the file it gives you as **`cookies.txt`** in this folder.

That's it. See [`cookies.example.txt`](cookies.example.txt) for the exact format.

> **Your cookies are your password.** This repo's `.gitignore` already blocks `cookies.txt` so you can't commit it by accident. Never upload or share it.

---

## Usage

Make the script executable once:

```bash
chmod +x transcribe.sh
```

Transcribe a single recording:

```bash
./transcribe.sh "https://YOUR-SCHOOL.cloud.panopto.eu/Panopto/Pages/Viewer.aspx?id=..."
```

Transcribe an entire folder (relies on yt-dlp's Panopto folder support):

```bash
./transcribe.sh "https://YOUR-SCHOOL.cloud.panopto.eu/Panopto/Pages/Sessions/List.aspx#folderID=..."
```

Transcripts land in `transcripts/` as `.txt` files.

### Options

Override any default with an environment variable:

```bash
# Different language (default is Hebrew):
LANG_CODE=en ./transcribe.sh "<url>"

# Different model or output folder:
WHISPER_MODEL=~/whisper-models/ggml-base.bin OUTDIR=out ./transcribe.sh "<url>"
```

| Variable        | Default                                       | Purpose                  |
| --------------- | --------------------------------------------- | ------------------------ |
| `COOKIES`       | `cookies.txt`                                 | Path to your cookies     |
| `WHISPER_MODEL` | `~/whisper-models/ggml-large-v3-turbo.bin`    | Whisper model file       |
| `LANG_CODE`     | `he`                                          | Transcription language   |
| `OUTDIR`        | `transcripts`                                 | Output directory         |

---

## How it works

For each recording, the script runs four steps:

1. **Download.** `yt-dlp` fetches the smallest available video stream (Panopto has no clean audio-only format).
2. **Extract audio.** `ffmpeg` converts it to 16 kHz mono WAV, the format Whisper expects.
3. **Transcribe.** `whisper-cli` produces a `.txt` transcript.
4. **Clean up.** The video and WAV are deleted, leaving only the transcript.

---

## Troubleshooting

- **`yt-dlp downloaded nothing`.** Your cookies are probably expired. Re-export them (see above).
- **`'whisper-cli' is not installed`.** Run `brew install whisper-cpp`.
- **Wrong language in the transcript.** Set `LANG_CODE` to your lecture's language (e.g. `en`, `es`).

---

## Responsible use

This is a study aid. Use it only on recordings you are entitled to access, for your own learning. Respect your institution's terms of service and the copyright of lecturers and content owners. Don't redistribute transcripts or recordings you don't have the right to share.

---

## License

[MIT](LICENSE) © Yam Meir
