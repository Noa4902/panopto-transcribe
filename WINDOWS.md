# Windows (via WSL) — experimental

> ⚠️ **Not tested by the author.** The verified, supported path is macOS — see [README.md](README.md). These Windows instructions run the **exact same `transcribe.sh`** inside WSL (Linux on Windows), so the core is the same proven pipeline. What hasn't been confirmed is the install steps below. **If you try this, please open an issue or message me with what worked and what didn't.**

The one real difference from macOS: there's no Metal acceleration on Windows, so transcription runs on the CPU and is slower. It still works. If you have an NVIDIA GPU, whisper.cpp can be built with CUDA for a big speed-up (not covered here).

---

## 1. Install WSL

In **PowerShell as Administrator**:

```powershell
wsl --install
```

Reboot when prompted, then open the **Ubuntu** app and finish setting up your Linux username and password. Everything below runs inside that Ubuntu terminal.

## 2. Install the tools

```bash
sudo apt update
sudo apt install -y ffmpeg git build-essential cmake python3-pip
pip install -U yt-dlp
```

## 3. Build whisper.cpp and get the model

```bash
git clone https://github.com/ggerganov/whisper.cpp
cd whisper.cpp
cmake -B build && cmake --build build --config Release

# download the model used by this tool
bash ./models/download-ggml-model.sh large-v3-turbo

# put the whisper binary on your PATH so transcribe.sh can find it
sudo ln -s "$(pwd)/build/bin/whisper-cli" /usr/local/bin/whisper-cli
cd ..
```

> Older whisper.cpp builds produce a binary called `main` instead of `whisper-cli`. If `build/bin/whisper-cli` doesn't exist, link `build/bin/main` instead, or update whisper.cpp.

## 4. Get the tool and your cookies

```bash
git clone https://github.com/yayayam-uxui/panopto-transcribe
cd panopto-transcribe
chmod +x transcribe.sh
```

Export your Panopto cookies exactly as in the [README](README.md#-your-one-responsibility-cookies) (same Chrome extension), and save the file as `cookies.txt` inside this folder. Saving it from Windows into the cloned folder works — WSL can read it.

## 5. Run it

Point `WHISPER_MODEL` at the model you downloaded, then run:

```bash
WHISPER_MODEL=~/whisper.cpp/models/ggml-large-v3-turbo.bin ./transcribe.sh "<panopto-url>"
```

Transcripts land in `transcripts/`, same as on macOS.

---

## If something breaks

- **`whisper-cli: command not found`** — the symlink in step 3 didn't take. Check that `build/bin/whisper-cli` exists and re-run the `ln -s` line.
- **`yt-dlp downloaded nothing`** — your cookies are expired. Re-export them.
- **Very slow** — expected on CPU. A 90-minute lecture can take a while. Leave it running.
