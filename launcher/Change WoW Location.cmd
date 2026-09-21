@echo off
setlocal
title WTFix 0.9.1 - change WoW location
color 07
cls

for /F "delims=#" %%e in ('"prompt #$E# & for %%e in (1) do rem"') do set "ESC=%%e"
set "CYAN=%ESC%[96m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "RED=%ESC%[91m"
set "DIM=%ESC%[90m"
set "RESET=%ESC%[0m"

echo.
echo %CYAN%  WTFix 0.9.1%RESET%
echo %DIM%  change WoW location%RESET%
echo %DIM%  -------------------%RESET%
echo.
echo   choose the WoW Forever _classic_beta_ folder.
echo %DIM%  it should contain WowB.exe, Interface and WTF.%RESET%
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0WTFix.ps1" -Configure
set "WTFIX_EXIT=%ERRORLEVEL%"

echo.
if "%WTFIX_EXIT%"=="0" (
    echo %GREEN%  location saved.%RESET%
) else (
    echo %RED%  location was not changed. exit code: %WTFIX_EXIT%%RESET%
    echo   log: %LOCALAPPDATA%\WTFix\WTFix-last.log
)

echo.
echo %DIM%  WTFix 0.9.1 ^| NS%RESET%
echo %DIM%  you can safely close this window, or press any key to exit.%RESET%
pause >nul
exit /b %WTFIX_EXIT%
