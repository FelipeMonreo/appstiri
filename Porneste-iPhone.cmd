@echo off
title Aplicatie stiri - Testare pe iPhone
cd /d "%~dp0"
echo Porneste acest fisier prin dublu clic din File Explorer.
echo Pastreaza fereastra deschisa cat timp testezi pe telefon.
if exist "C:\Python314\python.exe" (
    "C:\Python314\python.exe" "%~dp0scripts\serve_phone.py"
) else (
    python "%~dp0scripts\serve_phone.py"
)
pause
