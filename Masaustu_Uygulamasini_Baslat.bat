@echo off
set PORT=8085
set BUILD_DIR=C:\flutter_build\antigravity

start /b "" python -m http.server %PORT% --bind 127.0.0.1 --directory "%BUILD_DIR%"

ping 127.0.0.1 -n 2 >nul

if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
    start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" --app="http://127.0.0.1:%PORT%" --window-size=1150,750
) else (
    start http://127.0.0.1:%PORT%
)
