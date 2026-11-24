@echo off
rem Keep this file ASCII-only: cmd misparses multi-byte text in blocks after chcp 65001.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\install_windows.ps1"
pause
