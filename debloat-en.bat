@echo off
title Windows Debloat
echo.
echo Starting Windows Debloat...
echo If a permission window (UAC) appears, click "Yes".
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0debloat-en.ps1"
