@echo off
title Roopsy Salon Localhost Server
echo ========================================================
echo Starting Roopsy Localhost Web Server...
echo ========================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-server.ps1"
pause
