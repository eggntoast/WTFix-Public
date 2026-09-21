@echo off
setlocal
title WTFix 0.9.0 - uninstall
color 07
cls

for /F "delims=#" %%e in ('"prompt #$E# & for %%e in (1) do rem"') do set "ESC=%%e"
set "CYAN=%ESC%[96m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "RED=%ESC%[91m"
set "DIM=%ESC%[90m"
set "RESET=%ESC%[0m"
set "WTFIX_EXIT=0"

echo.
echo %CYAN%  WTFix 0.9.0%RESET%
echo %DIM%  uninstall%RESET%
echo %DIM%  ---------%RESET%
echo.
echo   this removes launcher preparation and its managed TOC entries.
echo %GREEN%  the addon runtime and all SavedVariables are retained.%RESET%
echo.
choice /C YN /N /M "  remove WTFix preparation now? [y/n] "
if errorlevel 2 (
    echo.
    echo %YELLOW%  cancelled. nothing was removed.%RESET%
    goto :footer
)

echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0WTFix.ps1" -Uninstall
set "WTFIX_EXIT=%ERRORLEVEL%"

echo.
if "%WTFIX_EXIT%"=="0" (
    echo %GREEN%  WTFix preparation removed. Runtime retained.%RESET%
) else (
    echo %RED%  uninstall stopped with exit code: %WTFIX_EXIT%%RESET%
    echo   log: %LOCALAPPDATA%\WTFix\WTFix-last.log
)

:footer
echo.
echo %DIM%  WTFix 0.9.0 ^| NS%RESET%
echo %DIM%  you can safely close this window, or press any key to exit.%RESET%
pause >nul
exit /b %WTFIX_EXIT%
