@echo off
setlocal
rem WTFix 0.9.1: the visible PowerShell window owns preparation and dismissal.
rem Do not use /wait or /b: no batch job should remain in that console.
start "WTFix 0.9.1" "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Launcher.ps1"
exit /b %ERRORLEVEL%
