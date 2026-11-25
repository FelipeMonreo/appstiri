@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\build-android.ps1"
if errorlevel 1 (
  echo.
  echo APK-ul nu a fost generat. Citeste eroarea de mai sus.
  pause
  exit /b 1
)
echo.
pause
