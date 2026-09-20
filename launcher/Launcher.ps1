[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$version = '0.8.8'
$Host.UI.RawUI.WindowTitle = "WTFix $version"

Write-Host ''
Write-Host "  WTFix $version" -ForegroundColor Cyan
Write-Host '  WoW Forever SavedVariables recovery'
Write-Host '  -----------------------------------'
Write-Host ''
Write-Host '  Preparing recovery...'
Write-Host ''

$preparationExit = 1
try {
    # Keep preparation in its own process: WTFix.ps1 intentionally uses exit.
    # The display process performs no recovery work after that process returns.
    & "$PSHOME\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'WTFix.ps1') -Launch
    $preparationExit = $LASTEXITCODE
} catch {
    Write-Host ("  Could not complete preparation: " + $_.Exception.Message) -ForegroundColor Red
}

Write-Host ''
if ($preparationExit -eq 0) {
    # Success means every mandatory step in WTFix.ps1 returned successfully.
    Write-Host '  RECOVERY IS READY' -ForegroundColor Green
    Write-Host '  Recovery input backup: verified' -ForegroundColor Green
    Write-Host '  Disk bridge: prepared and verified' -ForegroundColor Green
    Write-Host ''
    Write-Host '  Battle.net is ready for World of Warcraft: Forever - Beta.'
    Write-Host '  Click Play in Battle.net to start the game.' -ForegroundColor Yellow
} else {
    Write-Host "  PREPARATION DID NOT COMPLETE (exit code $preparationExit)" -ForegroundColor Red
    Write-Host '  Resolve the error above before starting WoW.'
    Write-Host "  Log: $env:LOCALAPPDATA\WTFix\WTFix-last.log"
}
Write-Host ''
Write-Host '  This window only displays the result. You can safely close it.'
Write-Host "  WTFix $version | NS" -ForegroundColor DarkGray

$originalControlC = [Console]::TreatControlCAsInput
try {
    # Ctrl+C becomes a normal key, not a cancellation signal. There is also no
    # waiting CMD batch in this console to show "Terminate batch job (Y/N)?".
    [Console]::TreatControlCAsInput = $true
    # Discard keystrokes left over from preparation: dismissal must be deliberate.
    while ([Console]::KeyAvailable) { [void][Console]::ReadKey($true) }
    Write-Host '  Press Enter or Ctrl+C to close, or use the window close button.'
    do {
        $key = [Console]::ReadKey($true)
        $controlC = $key.Key -eq [ConsoleKey]::C -and ($key.Modifiers -band [ConsoleModifiers]::Control)
    } until ($key.Key -eq [ConsoleKey]::Enter -or $controlC)
} finally {
    [Console]::TreatControlCAsInput = $originalControlC
}
exit $preparationExit
