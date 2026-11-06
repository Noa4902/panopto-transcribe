@echo off
setlocal
rem Defaults match the documented WSL installation. No username is hard-coded.
if not defined PANOPTO_DISTRO set "PANOPTO_DISTRO=Ubuntu-24.04"
if not defined PANOPTO_LAUNCHER set "PANOPTO_LAUNCHER=~/tools/panopto-transcribe/run-local.sh"
rem Open WSL and prompt there: pasted URLs are never evaluated by cmd.exe.
wsl.exe -d "%PANOPTO_DISTRO%" -- bash -lc "bash %PANOPTO_LAUNCHER% --open-output"
set "result=%ERRORLEVEL%"
if not "%result%"=="0" echo Transcription did not complete. Check the error above.
pause
exit /b %result%
