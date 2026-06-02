@echo off
setlocal EnableDelayedExpansion
set "BASE_DIR=%~dp0"
set "APP_PYTHON=%BASE_DIR%portable-files\python\python.exe"
set "FFMPEG_BIN_PATH=%BASE_DIR%portable-files\ffmpeg-7.1.1-essentials_build\bin"

echo Setting up paths...
set "PYTHONPATH=%BASE_DIR%VisoMaster-Fusion"
set "PATH=%FFMPEG_BIN_PATH%;%BASE_DIR%portable-files\git\bin;%PATH%"

echo Launching VisoMaster Fusion with logs redirected to app_output.txt...
pushd "%BASE_DIR%VisoMaster-Fusion"
"%APP_PYTHON%" -u "main.py" > "%BASE_DIR%app_output.txt" 2>&1
popd

echo Done. Check app_output.txt for logs.
pause
