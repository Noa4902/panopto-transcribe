# Transcribing Panopto Recordings

A Windows installation and usage guide with WSL, including NVIDIA GPU and CPU options.

[English](WINDOWS_GPU_CPU.md) | [עברית](WINDOWS_GPU_CPU_HE.md)

This supplements [WINDOWS.md](WINDOWS.md). The original transcription pipeline is unchanged.

## Choose a route

| Route | Requirements | Validation status |
| --- | --- | --- |
| NVIDIA GPU, below | Compatible NVIDIA GPU and Windows driver | Tested on one RTX 3070 Ti system, including local CUDA inference and one authenticated Panopto recording |
| [CPU-only instructions](#cpu-only-route-not-tested) | No NVIDIA GPU or CUDA required; sufficient system RAM | Not tested by this contributor; adapted from the original Windows instructions and whisper.cpp build instructions |

Only the NVIDIA route was tested. Do not follow its CUDA installation steps for the CPU route. No speed or successful-installation claim is made for the CPU route.

## NVIDIA route: what was tested

| Component | Observed configuration |
| --- | --- |
| Host | Windows 11, x86-64 |
| WSL distribution | Ubuntu 24.04 LTS; reported image 24.04.5 |
| CPU | AMD Ryzen 5 5600 |
| GPU | NVIDIA GeForce RTX 3070 Ti, 8 GB VRAM |
| Windows NVIDIA driver | 610.88, exposed to WSL as 610.57.01 |
| CUDA Toolkit | 12.9.86 |
| Host compiler | GCC/G++ 13.3 |
| glibc | 2.39 |
| whisper.cpp | v1.8.2, commit 4979e04f5dcaccb36057e059bbaed8a2f5288315 |
| Model | ggml-large-v3-turbo.bin |
| yt-dlp | 2026.10.26 |

The local JFK audio sample completed and wrote TXT output. Its log explicitly reported `using CUDA0 backend` and identified the RTX 3070 Ti. A real authenticated Panopto recording subsequently completed with Hebrew selected and produced a TXT file. Hebrew transcript quality was not independently evaluated. Folder processing, scheduled operation, and a second complete run through the Windows launcher have not been confirmed.

The 11-second sample took about 1.1 seconds including model loading. Do not extrapolate that result to full lectures; download time and recording content also matter.

## 1. Install the specific Ubuntu release

In Windows PowerShell **as Administrator**:

```powershell
wsl --install -d Ubuntu-24.04
```

Restart Windows if requested, then run the command again if the distribution has not yet installed. Complete Ubuntu's first-run username and password setup. The Linux password is entered invisibly. This distribution can coexist with another Ubuntu installation; there is no need to unregister or delete it.

Open the intended distribution explicitly when necessary:

```powershell
wsl -d Ubuntu-24.04
```

Inside Ubuntu:

```bash
cat /etc/os-release
nvidia-smi
```

Confirm `VERSION_ID="24.04"` and that your NVIDIA GPU appears. The CUDA version displayed by `nvidia-smi` describes driver capability; it does not prove the CUDA compiler is installed. If the GPU is unavailable, resolve Windows driver/WSL support before proceeding.

## 2. Install tools and CUDA Toolkit only

All remaining shell blocks run in **Ubuntu**, except those explicitly marked Windows.

```bash
sudo apt-get update &&
sudo apt-get install -y --no-install-recommends \
  git ffmpeg build-essential cmake python3-venv curl ca-certificates \
  gcc-13 g++-13 &&
mkdir -p ~/tools/cuda-setup &&
cd ~/tools/cuda-setup &&
curl -fLO https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-keyring_1.1-1_all.deb &&
sudo dpkg -i cuda-keyring_1.1-1_all.deb &&
sudo apt-get update &&
sudo apt-get install -y --no-install-recommends cuda-toolkit-12-9
```

This is a multi-gigabyte download. Check free space on the physical Windows drive, not only the large virtual capacity reported inside WSL. Do not install a Linux NVIDIA display driver in WSL: the Windows driver provides GPU access. In particular, avoid driver-containing CUDA meta-packages such as `cuda` or `cuda-drivers`.

Verify:

```bash
/usr/local/cuda-12.9/bin/nvcc --version
gcc-13 --version | head -n 1
ldd --version | head -n 1
```

The tested combination reported CUDA 12.9, GCC 13.3, and glibc 2.39. Installing GCC 13 alongside the default compiler does not require changing the system compiler default.

## 3. Build whisper.cpp with CUDA

These commands assume `~/tools/whisper.cpp` does not already exist. If it exists, inspect it rather than deleting or overwriting an installation.

```bash
cd ~/tools &&
git clone --branch v1.8.2 --depth 1 https://github.com/ggml-org/whisper.cpp.git &&
cd whisper.cpp &&
cmake -S . -B build-cuda \
  -DCMAKE_BUILD_TYPE=Release \
  -DGGML_CUDA=ON \
  -DWHISPER_BUILD_TESTS=OFF \
  -DCMAKE_C_COMPILER=/usr/bin/gcc-13 \
  -DCMAKE_CXX_COMPILER=/usr/bin/g++-13 \
  -DCMAKE_CUDA_COMPILER=/usr/local/cuda-12.9/bin/nvcc \
  -DCMAKE_CUDA_HOST_COMPILER=/usr/bin/g++-13 \
  -DCMAKE_CUDA_ARCHITECTURES=86 &&
cmake --build build-cuda --config Release -j 2
```

**Architecture `86` is specific to this RTX 3070 Ti setup.** For another GPU, select its supported CUDA compute capability. The detached-HEAD notice is expected when cloning a tag. Missing `ccache` is an optional acceleration warning. Two build jobs limit peak memory usage; WSL had about 7.7 GiB RAM available in this installation.

## 4. Download the model and verify actual GPU inference

```bash
cd ~/tools/whisper.cpp &&
bash ./models/download-ggml-model.sh large-v3-turbo &&
mkdir -p ~/tools/transcription-tests &&
./build-cuda/bin/whisper-cli \
  -m models/ggml-large-v3-turbo.bin \
  -f samples/jfk.wav -l en -otxt \
  -of "$HOME/tools/transcription-tests/jfk-$(date +%Y%m%d-%H%M%S)"
```

The model download is about 1.6 GB. Successful compilation alone is not proof of GPU inference. Confirm the inference log names your GPU, reports `using CUDA0 backend`, and saves a readable TXT transcript. The sample is English; lecture language is set to Hebrew below.

## 5. Install panopto-transcribe and yt-dlp

These commands also assume a new destination directory:

```bash
cd ~/tools &&
git clone https://github.com/yayayam-uxui/panopto-transcribe.git &&
cd panopto-transcribe &&
python3 -m venv .venv &&
.venv/bin/python -m pip install --upgrade yt-dlp
```

The virtual environment avoids system-Python package installation. The tested yt-dlp version is listed above; this command installs the currently available version.

## 6. Keep session cookies outside the repository

```bash
mkdir -p "$HOME/.config/panopto-transcribe"
chmod 700 "$HOME/.config/panopto-transcribe"
```

Follow the original README's instructions for **Get cookies.txt LOCALLY**. Sign in to Panopto in the browser and export cookies for the current Panopto site only, not all browser sites. Move the export to `cookies.txt` in the private directory above. Do not paste cookies into issues, pull requests, chat messages, screenshots, or logs. Cookies can grant account access.

In Windows Explorer, the directory is:

```text
\\wsl.localhost\Ubuntu-24.04\home\YOUR_LINUX_USERNAME\.config\panopto-transcribe
```

Replace `YOUR_LINUX_USERNAME` with the username created in Ubuntu. Then check existence without displaying contents:

```bash
chmod 600 "$HOME/.config/panopto-transcribe/cookies.txt" &&
test -s "$HOME/.config/panopto-transcribe/cookies.txt" &&
echo "Cookies file exists and is not empty"
```

This check does not validate whether the session is still authenticated. Cookies may expire and require a fresh export. Keeping the file outside the repository avoids relying solely on `.gitignore`.

## Ready-to-download launcher files

- [run-local.sh](run-local.sh): save beside `transcribe.sh` in `~/tools/panopto-transcribe` inside Ubuntu.
- [Panopto-Transcribe.bat](Panopto-Transcribe.bat): save on the Windows Desktop or another convenient Windows folder.

Open each file and use GitHub's **Download raw file** button; avoid saving the HTML page or adding a `.txt` extension. These files are on this documentation branch; cloning the original upstream repository does not include them. Keep an existing local launcher as a backup before replacing it.

The BAT defaults to `Ubuntu-24.04` and `~/tools/panopto-transcribe/run-local.sh`; no Linux username needs editing. It prompts for the URL inside Ubuntu and opens the output folder after success. For a custom installation, edit only the trusted distribution/launcher configuration lines; the documented launcher path contains no spaces. The shell launcher locates the repository from its own directory and defaults to Hebrew and the CUDA build. It also rejects Moodle LTI links with a direct-Panopto-link explanation.

For the untested CPU route, set `WHISPER_BUILD=build-cpu` and the appropriate `WHISPER_MODEL` inside `run-local.sh` before its default assignments; alternatively use the manual CPU substitutions below.

**Validation:** these downloadable launchers add path handling and preflight checks beyond the previously used local versions. Their full execution has not yet been verified. The editing environment blocked Bash execution, so even the attempted syntax check could not run. After saving in Ubuntu, run `bash -n ~/tools/panopto-transcribe/run-local.sh` and test one recording before normal use. Existing working installations do not need to replace their launcher.

The manual snippets below remain available as an alternative.

## 7. Add a local launcher

### Use a direct Panopto link

Paste a link copied from **Panopto itself**, not the Moodle page that embeds it. Moodle links such as `/mod/lti/view.php?id=...` can redirect the downloader to the university login page and fail with `Unsupported URL`.

If the recordings appear inside Moodle:

1. Open the course's recording list in your browser and sign in normally.
2. Click **Open in Panopto / Open in a new window**, shown as a square with an outward arrow (↗). In the tested folder view, it was next to **Subscribe**.
3. Copy the address from the newly opened Panopto tab. For one recording, open its Panopto viewer or use its Share / Copy link option.
4. Paste that direct link into the launcher.

Typical direct links are:

- Recording: `https://YOUR-SCHOOL.cloud.panopto.eu/Panopto/Pages/Viewer.aspx?id=...`
- Folder: `https://YOUR-SCHOOL.cloud.panopto.eu/Panopto/Pages/Sessions/List.aspx#folderID=...`

The domain and URL parameters can vary. A link merely opening successfully in your signed-in browser does not prove the downloader can access it. The cookie session must also be valid. Folder media is currently downloaded before transcription begins; start with a single recording for the first test.

Create `run-local.sh` inside `~/tools/panopto-transcribe` with the following contents. Do not overwrite an existing customized launcher without reviewing it.

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$HOME/tools/panopto-transcribe"

export PATH="$PWD/.venv/bin:$HOME/tools/whisper.cpp/build-cuda/bin:$PATH"
export WHISPER_MODEL="$HOME/tools/whisper.cpp/models/ggml-large-v3-turbo.bin"
export COOKIES="$HOME/.config/panopto-transcribe/cookies.txt"
export LANG_CODE=he
export OUTDIR="$PWD/transcripts"

url="${1:-}"
if [[ -z "$url" ]]; then
  read -r -p "Paste a Panopto recording or folder URL, then press Enter: " url
fi
[[ -n "$url" ]] || { echo "No URL provided." >&2; exit 1; }
[[ -s "$COOKIES" ]] || { echo "Missing cookies file: $COOKIES" >&2; exit 1; }
chmod 600 "$COOKIES"
bash ./transcribe.sh "$url"
```

Then:

```bash
cd ~/tools/panopto-transcribe
chmod +x run-local.sh
bash -n run-local.sh
./run-local.sh
```

The working installation used equivalent Hebrew prompt/error text. English prompts here avoid right-to-left rendering problems in Windows terminals; these wording changes have not been rerun separately. Start with one authorized recording. Check the final `Saved`/`Done` messages and read the resulting transcript. Do not treat an attempted download as a successful Panopto test.

## 8. Optional Windows double-click launcher

In Notepad, save this as `Panopto-Transcribe.bat`, selecting **All files** and UTF-8. Replace both occurrences of `YOUR_LINUX_USERNAME` with your Linux username. Save it on the Desktop or in a convenient local folder.

```bat
@echo off
chcp 65001 >nul
wsl.exe -d Ubuntu-24.04 -- bash /home/YOUR_LINUX_USERNAME/tools/panopto-transcribe/run-local.sh
if errorlevel 1 (
  echo Transcription did not complete. Check the error above.
) else (
  explorer.exe "\\wsl.localhost\Ubuntu-24.04\home\YOUR_LINUX_USERNAME\tools\panopto-transcribe\transcripts"
)
pause
```

The launcher successfully reached the URL prompt in the tested installation. Automatic folder opening after a complete run still needs confirmation. Run without Administrator privileges for normal use.

TXT files are in `~/tools/panopto-transcribe/transcripts`. The Explorer path is the same as above, ending in `tools\panopto-transcribe\transcripts`. You can create a Windows folder shortcut to that path. The files remain in WSL unless you copy them elsewhere.

## Known limitations of the original script

- Folder links are documented upstream, but were not tested in this setup. The current script downloads the folder's media before transcribing sequentially; large folders can use substantial temporary disk space.
- Existing TXT files are skipped only **after downloading**. There is no pre-download recording-ID archive.
- Output filenames depend on titles, so identical titles can collide. A partial TXT left by a failed inference may also be skipped on a retry. The existence check is not a complete transactional/no-overwrite guarantee.
- Temporary media is removed by the EXIT trap, including on many failures, not only after success. Abrupt termination may still leave temporary files.
- No weekly scheduling, date-range filtering, retry queue, or cross-process lock has been added. Avoid running several launchers simultaneously, especially for the same recording.
- Transcript quality, speaker separation, and lecture-scale speed still need evaluation with representative Hebrew lectures.

## Troubleshooting: CUDA math declaration errors

An earlier attempt with Ubuntu 26.04, glibc 2.43, and CUDA 12.9 failed during CUDA compiler identification with conflicting exception specifications for `cospi`, `sinpi`, and `rsqrt` (and their float variants). Switching GCC alone did not resolve it. The separate Ubuntu 24.04 / glibc 2.39 environment built successfully without patching system or CUDA headers. Do not edit system math headers to follow this guide.

## CPU-only route (not tested)

**These CPU-specific instructions have not been executed or validated by this contributor.** The original project's Windows guide is also labeled experimental. They are provided as a documented alternative, not a tested configuration. CPU inference can take substantially longer; no lecture-duration estimate is available.

1. Install and open Ubuntu 24.04 using section 1 above. Skip `nvidia-smi`: a GPU is not required.
2. Inside Ubuntu, install the tools without CUDA:

```bash
sudo apt-get update &&
sudo apt-get install -y --no-install-recommends \
  git ffmpeg build-essential cmake python3-venv curl ca-certificates
```

3. Build a CPU-only whisper.cpp. The clone assumes a fresh directory; if the repository already exists, inspect and reuse it rather than repeating the clone.

```bash
mkdir -p ~/tools &&
cd ~/tools &&
git clone --branch v1.8.2 --depth 1 https://github.com/ggml-org/whisper.cpp.git &&
cd whisper.cpp &&
cmake -S . -B build-cpu \
  -DCMAKE_BUILD_TYPE=Release \
  -DGGML_CUDA=OFF \
  -DWHISPER_BUILD_TESTS=OFF &&
cmake --build build-cpu --config Release -j 2
```

4. Choose a multilingual model appropriate for available memory. For an initial CPU test, `small` is a smaller alternative to `large-v3-turbo`, with different speed and accuracy tradeoffs. Do not choose an `.en` model for Hebrew. This guide does not establish Hebrew accuracy for either model.

```bash
cd ~/tools/whisper.cpp &&
bash ./models/download-ggml-model.sh small &&
mkdir -p ~/tools/transcription-tests &&
./build-cpu/bin/whisper-cli \
  -m models/ggml-small.bin \
  -f samples/jfk.wav -l en -otxt \
  -of "$HOME/tools/transcription-tests/jfk-cpu-$(date +%Y%m%d-%H%M%S)"
```

5. Follow sections 5 and 6 for panopto-transcribe, yt-dlp, and private cookies. In the section 7 launcher, substitute these two lines:

```bash
export PATH="$PWD/.venv/bin:$HOME/tools/whisper.cpp/build-cpu/bin:$PATH"
export WHISPER_MODEL="$HOME/tools/whisper.cpp/models/ggml-small.bin"
```

Keep `LANG_CODE=he`. The Windows BAT launcher and output-folder instructions are otherwise the same. Verify a short authorized Hebrew recording before processing full lectures. These are instructions for the reader to validate, not tests already performed by the contributor.

## References

- [Original Windows instructions](WINDOWS.md)
- [whisper.cpp v1.8.2](https://github.com/ggml-org/whisper.cpp/tree/v1.8.2)
- [NVIDIA CUDA on WSL guide](https://docs.nvidia.com/cuda/wsl-user-guide/)
- [CUDA 12.9 Linux installation guide](https://docs.nvidia.com/cuda/archive/12.9.1/cuda-installation-guide-linux/index.html)

This reports one observed configuration. NVIDIA's archived qualification table lists specific Ubuntu point releases; do not interpret this successful community test as certification of every later point release or GPU.
