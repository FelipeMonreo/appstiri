@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\export-mac.ps1"
if errorlevel 1 (
  echo.
  echo Arhiva nu a fost creata. Citeste eroarea de mai sus.
  pause
  exit /b 1
)
echo.
pause
