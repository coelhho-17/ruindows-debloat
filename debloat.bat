@echo off
title Windows Debloat
echo.
echo Iniciando o Windows Debloat...
echo Se aparecer uma janela pedindo confirmacao (UAC), clique em "Sim".
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0debloat.ps1"
