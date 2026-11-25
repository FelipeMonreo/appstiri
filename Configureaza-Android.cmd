@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\setup-android.ps1"
if errorlevel 1 (
  echo.
  echo Configurarea a esuat. Citeste eroarea de mai sus.
  pause
  exit /b 1
)
echo.
pause
