<div dir="rtl">

# תמלול ב-Windows עם WSL: מסלולי NVIDIA ו-CPU

[English](WINDOWS_GPU_CPU.md) | **עברית**

מדריך משלים ל-[הוראות Windows המקוריות](WINDOWS.md), המבוסס על הפרויקט של [Yam Meir](https://github.com/yayayam-uxui/panopto-transcribe). תרומת התיעוד: [Noa4902](https://github.com/Noa4902). מנגנון ההורדה והתמלול המקורי נשאר ללא שינוי.

## בחירת מסלול

| מסלול | דרישות | מה נבדק |
| --- | --- | --- |
| NVIDIA, בהמשך המדריך | כרטיס NVIDIA תואם ודרייבר Windows מתאים | נבדק במחשב אחד עם RTX 3070 Ti: בדיקת CUDA מקומית והרצאת Panopto אחת |
| CPU בלבד, בסוף המדריך | זיכרון RAM מספיק; אין צורך ב-NVIDIA או CUDA | **לא נבדק על ידי תורמת המדריך**; מבוסס על הוראות הפרויקט ו-whisper.cpp |

במסלול CPU יש לדלג על התקנת CUDA ועל בניית גרסת GPU. אין במדריך הבטחה לזמני עיבוד או להתקנה מוצלחת במסלול שלא נבדק.

## סביבת NVIDIA שנבדקה

| רכיב | הגרסה שנצפתה |
| --- | --- |
| מערכת מארחת | Windows 11, ‏64-bit |
| סביבת Linux | Ubuntu 24.04 LTS בתוך WSL; המערכת דיווחה 24.04.5 |
| מעבד | AMD Ryzen 5 5600 |
| כרטיס מסך | NVIDIA GeForce RTX 3070 Ti, ‏8GB VRAM |
| דרייבר Windows | 610.88; ב-WSL הוצג 610.57.01 |
| CUDA Toolkit | 12.9.86 |
| מהדר | GCC/G++ 13.3 |
| glibc | 2.39 |
| whisper.cpp | v1.8.2 |
| מזהה גרסת הקוד | `4979e04f5dcaccb36057e059bbaed8a2f5288315` |
| מודל | `ggml-large-v3-turbo.bin` |
| yt-dlp | 2026.10.26 |

קובץ הדוגמה JFK תומלל ונשמר כ-TXT. הפלט זיהה את הכרטיס וציין במפורש `using CUDA0 backend`. לאחר מכן הושלם גם עיבוד הקלטת Panopto שדורשת התחברות, כשהשפה מוגדרת לעברית, ונוצר TXT.

איכות העברית לא הוערכה באופן עצמאי. עיבוד תיקיות, הפעלה מתוזמנת וריצה מלאה נוספת דרך קובץ ההפעלה של Windows לא אומתו. בדיקת הדוגמה, באורך 11 שניות, נמשכה כ-1.1 שניות כולל טעינת המודל; אין להסיק ממנה את זמן העיבוד של הרצאה מלאה.

## 1. התקנת Ubuntu בגרסה מוגדרת

פתחו PowerShell ב-Windows **כמנהלי מערכת** והריצו:

</div>

```powershell
wsl --install -d Ubuntu-24.04
```

<div dir="rtl">

אם נדרשת הפעלה מחדש, שמרו עבודה והפעילו מחדש. אם ההפצה טרם הותקנה, הריצו שוב את הפקודה. בהפעלה הראשונה צרו משתמש וסיסמת Linux; בזמן הקלדת הסיסמה לא יופיעו תווים.

אפשר להתקין לצד Ubuntu אחר, בלי למחוק אותו. כדי לפתוח במפורש את הסביבה הנכונה:

</div>

```powershell
wsl -d Ubuntu-24.04
```

<div dir="rtl">

בתוך Ubuntu הריצו:

</div>

```bash
cat /etc/os-release
nvidia-smi
```

<div dir="rtl">

ודאו שמופיע `VERSION_ID="24.04"` ושכרטיס NVIDIA מזוהה. גרסת CUDA שמציג `nvidia-smi` מציינת יכולת של הדרייבר, ולא מוכיחה שהמהדר מותקן. אם הכרטיס אינו מזוהה, יש לפתור את הגישה אליו דרך Windows ו-WSL לפני ההמשך.

## 2. התקנת התלויות ו-CUDA Toolkit

מכאן הפקודות רצות בתוך **Ubuntu**, אלא אם מצוין אחרת.

</div>

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

<div dir="rtl">

זו הורדה של כמה ג׳יגה. בדקו את המקום הפנוי בכונן Windows הפיזי, ולא רק את הנפח הווירטואלי הגדול שמציג WSL.

**אין להתקין דרייבר תצוגה של NVIDIA ל-Linux בתוך WSL.** הגישה לכרטיס מגיעה מהדרייבר של Windows. יש להימנע מחבילות הכוללות דרייברים, כמו `cuda` או `cuda-drivers`.

בדקו את הגרסאות:

</div>

```bash
/usr/local/cuda-12.9/bin/nvcc --version
gcc-13 --version | head -n 1
ldd --version | head -n 1
```

<div dir="rtl">

בשילוב שנבדק הופיעו CUDA 12.9, ‏GCC 13.3 ו-glibc 2.39. התקנת GCC 13 לצד המהדר הקיים אינה מחייבת לשנות את מהדר ברירת המחדל.

## 3. בניית whisper.cpp עם האצת NVIDIA

הפקודות מניחות שהתיקייה `~/tools/whisper.cpp` עדיין לא קיימת. אם קיימת התקנה, בדקו אותה לפני שממשיכים; אין צורך למחוק או לדרוס אותה.

</div>

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

<div dir="rtl">

**הערך 86 מתאים לכרטיס RTX 3070 Ti שנבדק.** לכרטיס אחר יש לבחור את ערך CUDA compute capability המתאים לו.

הודעת `detached HEAD` צפויה כשמורידים גרסה מתויגת. הודעה על היעדר `ccache` מתייחסת לכלי אופציונלי בלבד. הבנייה מוגבלת לשתי עבודות במקביל לצמצום השימוש בזיכרון; לסביבת WSL שנבדקה הוקצו כ-7.7GiB RAM.

## 4. הורדת מודל ובדיקת תמלול על ה-GPU

</div>

```bash
cd ~/tools/whisper.cpp &&
bash ./models/download-ggml-model.sh large-v3-turbo &&
mkdir -p ~/tools/transcription-tests &&
./build-cuda/bin/whisper-cli \
  -m models/ggml-large-v3-turbo.bin \
  -f samples/jfk.wav -l en -otxt \
  -of "$HOME/tools/transcription-tests/jfk-$(date +%Y%m%d-%H%M%S)"
```

<div dir="rtl">

המודל בגודל כ-1.6GB. הצלחת הבנייה אינה מספיקה: בפלט בדיקת התמלול יש לוודא שהכרטיס מזוהה, שמופיע `using CUDA0 backend` ושנוצר TXT קריא.

קובץ הדוגמה באנגלית. בהמשך נגדיר עברית להרצאות.

## 5. הורדת הפרויקט והתקנת yt-dlp

גם כאן הפקודות מניחות שתיקיית היעד חדשה.

</div>

```bash
cd ~/tools &&
git clone https://github.com/yayayam-uxui/panopto-transcribe.git &&
cd panopto-transcribe &&
python3 -m venv .venv &&
.venv/bin/python -m pip install --upgrade yt-dlp
```

<div dir="rtl">

הסביבה הווירטואלית מפרידה את החבילות מ-Python של המערכת. הפקודה מתקינה את גרסת yt-dlp הזמינה בזמן ההרצה; גרסת הבדיקה מופיעה בטבלה לעיל.

## 6. שמירת Cookies מחוץ לקוד

</div>

```bash
mkdir -p "$HOME/.config/panopto-transcribe"
chmod 700 "$HOME/.config/panopto-transcribe"
```

<div dir="rtl">

לפי הוראות ה-README המקורי, השתמשו בתוסף **Get cookies.txt LOCALLY**. התחברו ל-Panopto בדפדפן וייצאו Cookies של אתר Panopto הנוכחי בלבד, ולא של כל אתרי הדפדפן.

העבירו את הקובץ לתיקייה הפרטית ושנו את שמו ל-`cookies.txt`. **אין לפרסם את הקובץ או תוכנו בצ׳אט, בצילומי מסך, ב-Issues, ב-Pull Requests או בלוגים.** הוא יכול לאפשר גישה לחשבון.

בסייר הקבצים של Windows אפשר לפתוח את הנתיב הבא:

</div>

```text
\\wsl.localhost\Ubuntu-24.04\home\YOUR_LINUX_USERNAME\.config\panopto-transcribe
```

<div dir="rtl">

החליפו את `YOUR_LINUX_USERNAME` בשם המשתמש שיצרתם ב-Ubuntu. לאחר השמירה בדקו קיום והרשאות בלי להציג תוכן:

</div>

```bash
chmod 600 "$HOME/.config/panopto-transcribe/cookies.txt" &&
test -s "$HOME/.config/panopto-transcribe/cookies.txt" &&
echo "Cookies file exists and is not empty"
```

<div dir="rtl">

הבדיקה מוכיחה שהקובץ קיים ואינו ריק, ולא שההתחברות תקפה. אם ה-Cookies יפוגו, יידרש ייצוא מחודש. מיקומם מחוץ לריפוזיטורי אינו תלוי רק בהגנת `.gitignore`.

## 7. יצירת סקריפט הפעלה מקומי

צרו קובץ בשם `run-local.sh` בתוך `~/tools/panopto-transcribe` עם התוכן הבא. אין לדרוס סקריפט מותאם שכבר קיים בלי לבדוק אותו.

</div>

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

<div dir="rtl">

לאחר השמירה הריצו:

</div>

```bash
cd ~/tools/panopto-transcribe
chmod +x run-local.sh
bash -n run-local.sh
./run-local.sh
```

<div dir="rtl">

בהתקנה שנבדקה היו הודעות מקבילות בעברית. כאן ההודעות באנגלית כדי להימנע מתצוגת עברית הפוכה בחלון Windows; שינוי הניסוח לא הורץ בנפרד.

התחילו בהקלטה בודדת שיש לכם הרשאה לגשת אליה. ודאו שמופיעות הודעות `Saved` ו-`Done`, ופתחו את התמלול. עצם ניסיון ההורדה אינו בדיקת Panopto מוצלחת.

## 8. הפעלה בלחיצה כפולה ב-Windows

בפנקס הרשימות שמרו את הקוד הבא בשם `Panopto-Transcribe.bat`. בחלון השמירה בחרו **כל הקבצים / All files** וקידוד UTF-8. אפשר לשמור בשולחן העבודה או בתיקייה נוחה אחרת.

החליפו בשני המקומות את `YOUR_LINUX_USERNAME` בשם המשתמש שלכם ב-Linux.

</div>

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

<div dir="rtl">

בבדיקה קובץ ההפעלה הגיע בהצלחה לבקשת הקישור. פתיחת התיקייה האוטומטית לאחר ריצה מלאה עדיין דורשת אימות. בשימוש רגיל אין צורך להפעיל כמנהלי מערכת.

התמלולים נשמרים ב-`~/tools/panopto-transcribe/transcripts`. אפשר לגשת מסייר הקבצים באמצעות אותו נתיב רשת של WSL, כשהסיומת היא `tools\panopto-transcribe\transcripts`, וליצור אליו קיצור דרך. הקבצים נשארים בסביבת WSL עד שמעתיקים אותם למיקום אחר.

## מגבלות הסקריפט המקורי

- תיקיות נתמכות לפי תיעוד הפרויקט, אבל לא נבדקו בהתקנה הזו. הסקריפט מוריד תחילה את המדיה של התיקייה ורק אז מתמלל ברצף; תיקיות גדולות עשויות לדרוש מקום זמני רב.
- הדילוג על TXT קיים מתבצע **אחרי ההורדה**. אין רשימת מזהי הרצאות למניעת הורדה מוקדמת.
- שמות הפלט מבוססים על כותרות. הרצאות עם שם זהה עלולות להתנגש, ו-TXT חלקי מכישלון קודם עלול לגרום לדילוג בהרצה חוזרת. אין הגנה מלאה מפני כל מקרי הדריסה או הפלט החלקי.
- מנגנון הניקוי מוחק מדיה זמנית ביציאה, גם במקרים רבים של כישלון, ולא רק אחרי הצלחה. עצירה חריגה עדיין עלולה להשאיר קבצים זמניים.
- לא נוספו תזמון שבועי, סינון תאריכים, תור ניסיונות חוזרים או נעילה בין תהליכים. יש להימנע מהרצת כמה חלונות במקביל, במיוחד לאותה הרצאה.
- איכות התמלול בעברית, הפרדת דוברים וזמני עיבוד של הרצאות מלאות דורשים הערכה נוספת.

## פתרון התקלה שבה נתקלנו

ניסיון קודם עם Ubuntu 26.04, ‏glibc 2.43 ו-CUDA 12.9 נכשל בבדיקת מהדר CUDA בגלל הצהרות מתנגשות של `cospi`, ‏`sinpi` ו-`rsqrt` וגרסאות ה-float שלהן.

החלפת GCC בלבד לא פתרה זאת. בסביבת Ubuntu 24.04 נפרדת עם glibc 2.39 הבנייה הצליחה בלי לערוך קובצי מערכת או כותרות CUDA. אין לערוך את כותרות המתמטיקה של המערכת כדי לבצע את המדריך.

## מסלול CPU בלבד - לא נבדק

**הוראות המסלול הזה לא הורצו ולא אומתו על ידי תורמת המדריך.** גם הוראות Windows המקוריות מסומנות כניסיוניות. זהו מסלול מתועד אפשרי; אין התחייבות לביצועים או הערכת זמן להרצאה.

1. התקינו ופתחו Ubuntu 24.04 לפי סעיף 1. דלגו על `nvidia-smi`; כרטיס מסך אינו נדרש.
2. התקינו את הכלים ללא CUDA:

</div>

```bash
sudo apt-get update &&
sudo apt-get install -y --no-install-recommends \
  git ffmpeg build-essential cmake python3-venv curl ca-certificates
```

<div dir="rtl">

3. בנו גרסת CPU. השכפול מניח תיקייה חדשה; אם הקוד קיים, בדקו והשתמשו בו במקום לשכפל שוב.

</div>

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

<div dir="rtl">

4. בחרו מודל רב-לשוני בהתאם לזיכרון הזמין. לניסוי ראשוני על המעבד, `small` הוא חלופה קטנה יותר ל-`large-v3-turbo`, עם פשרה שונה בין מהירות לדיוק. לעברית אין לבחור מודל שמסתיים ב-`.en`. איכות העברית של המודלים לא הוערכה במדריך.

</div>

```bash
cd ~/tools/whisper.cpp &&
bash ./models/download-ggml-model.sh small &&
mkdir -p ~/tools/transcription-tests &&
./build-cpu/bin/whisper-cli \
  -m models/ggml-small.bin \
  -f samples/jfk.wav -l en -otxt \
  -of "$HOME/tools/transcription-tests/jfk-cpu-$(date +%Y%m%d-%H%M%S)"
```

<div dir="rtl">

5. המשיכו לסעיפים 5 ו-6 להתקנת הפרויקט, yt-dlp וה-Cookies. בסקריפט מסעיף 7 החליפו את שתי השורות הבאות:

</div>

```bash
export PATH="$PWD/.venv/bin:$HOME/tools/whisper.cpp/build-cpu/bin:$PATH"
export WHISPER_MODEL="$HOME/tools/whisper.cpp/models/ggml-small.bin"
```

<div dir="rtl">

השאירו `LANG_CODE=he`. קובץ ה-BAT והוראות תיקיית הפלט נשארים כפי שהם. מומלץ לקורא לאמת הקלטה קצרה בעברית לפני עיבוד הרצאות מלאות; זו בדיקה לביצוע אצל הקורא ולא בדיקה שכבר בוצעה במסגרת התרומה.

## מקורות וקרדיט

- [הפרויקט המקורי של Yam Meir](https://github.com/yayayam-uxui/panopto-transcribe)
- [הוראות Windows המקוריות](WINDOWS.md)
- [whisper.cpp v1.8.2](https://github.com/ggml-org/whisper.cpp/tree/v1.8.2)
- [מדריך NVIDIA ל-CUDA בתוך WSL](https://docs.nvidia.com/cuda/wsl-user-guide/)
- [הוראות התקנת CUDA 12.9 ב-Linux](https://docs.nvidia.com/cuda/archive/12.9.1/cuda-installation-guide-linux/index.html)

זהו דיווח על תצורה אחת שנבדקה. טבלת התאימות הארכיונית של NVIDIA מונה מהדורות משנה מסוימות של Ubuntu; אין להסיק מהניסיון הזה הסמכה רשמית לכל מהדורה חדשה יותר או לכל כרטיס.

</div>
