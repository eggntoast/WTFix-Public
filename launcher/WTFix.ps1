[CmdletBinding()]
param(
    [switch]$Launch,
    [switch]$Configure,
    [switch]$Uninstall,
    [switch]$DirectWowB
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

$WTFixVersion = "0.9.0"
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$StateRoot = Join-Path $env:LOCALAPPDATA "WTFix"
$ConfigPath = Join-Path $StateRoot "config.json"
$LogPath = Join-Path $StateRoot "WTFix-last.log"
$BackupRoot = Join-Path $StateRoot "toc-backups"
$SourceAddonRoot = Join-Path $ScriptRoot "AddOn\WTFix"
$SourceCompanionRoot = Join-Path $ScriptRoot "Companion\WTFix_Data"
$BridgeProtocol = 1

New-Item -ItemType Directory -Path $StateRoot -Force | Out-Null
New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
Set-Content -LiteralPath $LogPath -Value "" -Encoding UTF8

function Write-Log {
    param(
        [string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::Gray
    )

    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8
    Write-Host $Message -ForegroundColor $Color
}

function Write-LogOnly {
    param([string]$Message)
    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8
}

function Save-Config {
    param([hashtable]$Config)
    $Config | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $ConfigPath -Encoding UTF8
}

function Load-Config {
    if (-not (Test-Path -LiteralPath $ConfigPath)) {
        return @{}
    }

    try {
        $obj = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
        $result = @{}
        if ($obj.WowPath) { $result.WowPath = [string]$obj.WowPath }
        if ($obj.BattleNetPath) { $result.BattleNetPath = [string]$obj.BattleNetPath }
        if ($obj.LastAccountFolder) { $result.LastAccountFolder = [string]$obj.LastAccountFolder }
        return $result
    }
    catch {
        Write-Log "Saved WTFix setup could not be used. Nothing in WoW was changed; WTFix will ask for the paths again." Yellow
        return @{}
    }
}

function Test-WowPath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }

    return (
        (Test-Path -LiteralPath (Join-Path $Path "WowB.exe") -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Path "Interface\AddOns") -PathType Container) -and
        (Test-Path -LiteralPath (Join-Path $Path "WTF") -PathType Container)
    )
}

function Normalize-WowPath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $null }

    $candidate = [System.IO.Path]::GetFullPath($Path.Trim())
    if (Test-WowPath $candidate) { return $candidate }

    $betaChild = Join-Path $candidate "_classic_beta_"
    if (Test-WowPath $betaChild) { return $betaChild }

    return $null
}

function Find-WowCandidates {
    $candidates = New-Object System.Collections.Generic.List[string]

    foreach ($nearby in @($ScriptRoot, (Split-Path -Parent $ScriptRoot))) {
        $normalized = Normalize-WowPath $nearby
        if ($normalized -and -not $candidates.Contains($normalized)) {
            $candidates.Add($normalized)
        }
    }

    foreach ($base in @($env:ProgramFiles, ${env:ProgramFiles(x86)})) {
        if ([string]::IsNullOrWhiteSpace($base)) { continue }
        $candidate = Join-Path $base "World of Warcraft\_classic_beta_"
        if (Test-WowPath $candidate) {
            $resolved = [System.IO.Path]::GetFullPath($candidate)
            if (-not $candidates.Contains($resolved)) {
                $candidates.Add($resolved)
            }
        }
    }

    return $candidates.ToArray()
}

function Select-WowFolder {
    Write-Host ""
    Write-Host "First-time setup" -ForegroundColor Cyan
    Write-Host "WTFix needs to know where WoW Forever is installed."
    Write-Host "In the folder window, go to your World of Warcraft folder and select:"
    Write-Host ""
    Write-Host "  _classic_beta_" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Pick the folder that contains WowB.exe, Interface and WTF."
    Write-Host "WTFix only remembers the path. Nothing is moved or deleted." -ForegroundColor DarkGray
    Write-Host ""

    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "Select the WoW Forever _classic_beta_ folder (the folder containing WowB.exe)"
    $dialog.ShowNewFolderButton = $false

    $result = $dialog.ShowDialog()
    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
        throw "No WoW Forever folder was selected."
    }

    $normalized = Normalize-WowPath $dialog.SelectedPath
    if (-not $normalized) {
        throw "That folder is not a valid WoW Forever installation. WTFix expects WowB.exe, Interface\AddOns and WTF."
    }

    return $normalized
}

function Resolve-WowPath {
    param([hashtable]$Config, [switch]$ForcePicker)

    if (-not $ForcePicker -and $Config.ContainsKey("WowPath")) {
        $saved = Normalize-WowPath $Config.WowPath
        if ($saved) {
            return $saved
        }
        Write-Log "Saved WoW path is no longer valid."
    }

    if (-not $ForcePicker) {
        $auto = @(Find-WowCandidates)
        if ($auto.Count -eq 1) {
            Write-Log "Auto-detected WoW Forever: $($auto[0])"
            return $auto[0]
        }
        if ($auto.Count -gt 1) {
            Write-Log "More than one automatic WoW Forever candidate was found. Asking for a folder."
        }
    }

    return Select-WowFolder
}

function Test-BattleNetPath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }

    return [string]::Equals(
        [System.IO.Path]::GetFileName($Path),
        "Battle.net.exe",
        [System.StringComparison]::OrdinalIgnoreCase
    )
}

function Get-RunningBattleNetPath {
    foreach ($process in @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like "Battle.net*" })) {
        try {
            $path = [string]$process.Path
            if (Test-BattleNetPath $path) {
                return [System.IO.Path]::GetFullPath($path)
            }
        }
        catch {}
    }
    return $null
}

function Find-BattleNetCandidates {
    $candidates = New-Object System.Collections.Generic.List[string]

    $running = Get-RunningBattleNetPath
    if ($running -and -not $candidates.Contains($running)) {
        $candidates.Add($running)
    }

    foreach ($base in @(${env:ProgramFiles(x86)}, $env:ProgramFiles)) {
        if ([string]::IsNullOrWhiteSpace($base)) { continue }
        $candidate = Join-Path $base "Battle.net\Battle.net.exe"
        if (Test-BattleNetPath $candidate) {
            $resolved = [System.IO.Path]::GetFullPath($candidate)
            if (-not $candidates.Contains($resolved)) {
                $candidates.Add($resolved)
            }
        }
    }

    return $candidates.ToArray()
}

function Select-BattleNetExecutable {
    Write-Host ""
    Write-Host "Battle.net" -ForegroundColor Cyan
    Write-Host "WTFix uses Battle.net so WoW keeps your normal logged-in session."
    Write-Host "In the file window, select Battle.net.exe."
    Write-Host "It is usually inside the Battle.net installation folder."
    Write-Host "WTFix only remembers the path. It does not touch your Battle.net login." -ForegroundColor DarkGray
    Write-Host ""

    Add-Type -AssemblyName System.Windows.Forms

    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = "Select Battle.net.exe"
    $dialog.Filter = "Battle.net.exe|Battle.net.exe|Executable files (*.exe)|*.exe"
    $dialog.FileName = "Battle.net.exe"
    $dialog.CheckFileExists = $true
    $dialog.Multiselect = $false

    $result = $dialog.ShowDialog()
    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
        throw "No Battle.net executable was selected."
    }

    if (-not (Test-BattleNetPath $dialog.FileName)) {
        throw "The selected Battle.net executable does not exist."
    }

    return [System.IO.Path]::GetFullPath($dialog.FileName)
}

function Resolve-BattleNetPath {
    param([hashtable]$Config)

    $running = Get-RunningBattleNetPath
    if ($running) {
        Write-Log "Detected running Battle.net client."
        return $running
    }

    if ($Config.ContainsKey("BattleNetPath") -and (Test-BattleNetPath $Config.BattleNetPath)) {
        return [System.IO.Path]::GetFullPath($Config.BattleNetPath)
    }

    if ($Config.ContainsKey("BattleNetPath")) {
        Write-Log "Saved Battle.net path is no longer valid."
    }

    $auto = @(Find-BattleNetCandidates)
    if ($auto.Count -eq 1) {
        Write-Log "Auto-detected Battle.net."
        return $auto[0]
    }

    if ($auto.Count -gt 1) {
        Write-Log "More than one Battle.net candidate was found. Asking for Battle.net.exe."
    }
    else {
        Write-Log "Battle.net was not found automatically. Asking for Battle.net.exe."
    }

    return Select-BattleNetExecutable
}

function Start-BattleNetForever {
    param([string]$BattleNetPath)

    if (-not (Test-BattleNetPath $BattleNetPath)) {
        throw "Battle.net.exe was not found."
    }

    $wasRunning = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like "Battle.net*" }).Count -gt 0
    # Only select the Battle.net product. Do not pass --gamepath here.
    # Battle.net owns install/version discovery and update handling.
    $argument = '--game=wow_classic_beta'

    Write-Log "Opening Battle.net on WoW Forever Beta." Cyan
    Start-Process -FilePath $BattleNetPath -ArgumentList $argument -WorkingDirectory (Split-Path -Parent $BattleNetPath) | Out-Null

    if ($wasRunning) {
        Write-LogOnly "Battle.net was already running; WTFix sent the Forever Beta product selection to it."
    }
    else {
        Write-LogOnly "Battle.net was started with the Forever Beta product selection."
    }
}

function Get-AccountFolders {
    param([string]$WowPath)
    $accountRoot = Join-Path $WowPath "WTF\Account"
    if (-not (Test-Path -LiteralPath $accountRoot -PathType Container)) {
        return @()
    }

    return @(
        Get-ChildItem -LiteralPath $accountRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object {
                (Test-Path -LiteralPath (Join-Path $_.FullName "SavedVariables") -PathType Container -ErrorAction SilentlyContinue) -or
                (@(Get-ChildItem -LiteralPath $_.FullName -Directory -ErrorAction SilentlyContinue).Count -gt 0)
            } |
            Sort-Object Name
    )
}

function Select-AccountFolder {
    param([object[]]$Accounts, [hashtable]$Config)

    if ($Accounts.Count -eq 0) {
        Write-Log "No WoW account folders were found yet. Cold-start bootstrap will be empty for this launch."
        return $null
    }

    if ($Accounts.Count -eq 1) {
        return $Accounts[0]
    }

    Write-Host ""
    Write-Host "WTFix found more than one WoW account folder."
    Write-Host "Choose the account you intend to use for this launch:"
    Write-Host ""

    $defaultIndex = 1
    for ($i = 0; $i -lt $Accounts.Count; $i++) {
        $marker = " "
        if ($Config.ContainsKey("LastAccountFolder") -and $Accounts[$i].Name -eq $Config.LastAccountFolder) {
            $defaultIndex = $i + 1
            $marker = "*"
        }
        Write-Host ("{0} {1}. {2}" -f $marker, ($i + 1), $Accounts[$i].Name)
    }

    while ($true) {
        $answer = Read-Host "Account [$defaultIndex]"
        if ([string]::IsNullOrWhiteSpace($answer)) {
            return $Accounts[$defaultIndex - 1]
        }

        $number = 0
        if ([int]::TryParse($answer, [ref]$number) -and $number -ge 1 -and $number -le $Accounts.Count) {
            return $Accounts[$number - 1]
        }

        Write-Host "Enter a number from 1 to $($Accounts.Count)."
    }
}

function Get-TextInfo {
    param([string]$Path)

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $encoding = $null
    $hasBom = $false

    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $encoding = New-Object System.Text.UTF8Encoding($true)
        $hasBom = $true
    }
    elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        $encoding = New-Object System.Text.UnicodeEncoding($false, $true)
        $hasBom = $true
    }
    elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
        $encoding = New-Object System.Text.UnicodeEncoding($true, $true)
        $hasBom = $true
    }
    else {
        try {
            $strictUtf8 = New-Object System.Text.UTF8Encoding($false, $true)
            [void]$strictUtf8.GetString($bytes)
            $encoding = New-Object System.Text.UTF8Encoding($false)
        }
        catch {
            $encoding = [System.Text.Encoding]::GetEncoding(1252)
        }
    }

    $text = $encoding.GetString($bytes)
    if ($hasBom -and $text.Length -gt 0 -and [int]$text[0] -eq 0xFEFF) {
        $text = $text.Substring(1)
    }

    $newline = "`r`n"
    if ($text.Contains("`r`n")) { $newline = "`r`n" }
    elseif ($text.Contains("`n")) { $newline = "`n" }
    elseif ($text.Contains("`r")) { $newline = "`r" }

    return [pscustomobject]@{
        Text = $text
        Encoding = $encoding
        HasBom = $hasBom
        Newline = $newline
    }
}

function Write-TextInfo {
    param([string]$Path, [string]$Text, $Info)

    $encoding = $Info.Encoding
    [byte[]]$body = $encoding.GetBytes($Text)

    if ($Info.HasBom) {
        [byte[]]$preamble = $encoding.GetPreamble()
        $combined = New-Object byte[] ($preamble.Count + $body.Count)
        [Array]::Copy($preamble, 0, $combined, 0, $preamble.Count)
        [Array]::Copy($body, 0, $combined, $preamble.Count, $body.Count)
        [System.IO.File]::WriteAllBytes($Path, $combined)
    }
    else {
        [System.IO.File]::WriteAllBytes($Path, $body)
    }
}

function Parse-VariableNames {
    param([string]$Value, [string]$AddonName, [string]$Scope)

    $valid = New-Object System.Collections.Generic.List[string]
    foreach ($raw in ($Value -split ',')) {
        $name = $raw.Trim()
        if ($name -eq "") { continue }

        if ($name -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') {
            Write-LogOnly "Skipped unsupported $Scope variable '$name' in $AddonName."
            continue
        }

        if (-not $valid.Contains($name)) {
            $valid.Add($name)
        }
    }

    return $valid.ToArray()
}

function Get-AddonDefinitions {
    param([string]$AddOnsRoot)

    $definitions = New-Object System.Collections.Generic.List[object]

    foreach ($folder in @(Get-ChildItem -LiteralPath $AddOnsRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name)) {
        if ($folder.Name -in @("WTFix", "WTFix_Data")) { continue }

        $accountVars = New-Object System.Collections.Generic.List[string]
        $characterVars = New-Object System.Collections.Generic.List[string]
        $relevantTocs = New-Object System.Collections.Generic.List[string]

        foreach ($toc in @(Get-ChildItem -LiteralPath $folder.FullName -File -Filter "*.toc" -ErrorAction SilentlyContinue)) {
            $info = Get-TextInfo $toc.FullName
            $tocRelevant = $false

            foreach ($line in ($info.Text -split "`r`n|`n|`r")) {
                if ($line -match '^\s*##\s*SavedVariables\s*:\s*(.*)$') {
                    foreach ($name in @(Parse-VariableNames $Matches[1] $folder.Name "account")) {
                        if (-not $accountVars.Contains($name)) { $accountVars.Add($name) }
                    }
                    $tocRelevant = $true
                }
                elseif ($line -match '^\s*##\s*SavedVariablesPerCharacter\s*:\s*(.*)$') {
                    foreach ($name in @(Parse-VariableNames $Matches[1] $folder.Name "character")) {
                        if (-not $characterVars.Contains($name)) { $characterVars.Add($name) }
                    }
                    $tocRelevant = $true
                }
            }

            if ($tocRelevant) {
                $relevantTocs.Add($toc.FullName)
            }
        }

        if ($accountVars.Count -eq 0 -and $characterVars.Count -eq 0) { continue }

        $definitions.Add([pscustomobject]@{
            Name = $folder.Name
            Folder = $folder.FullName
            AccountVars = $accountVars.ToArray()
            CharacterVars = $characterVars.ToArray()
            Tocs = $relevantTocs.ToArray()
        })
    }

    return $definitions.ToArray()
}

function Backup-Toc {
    param([string]$AddonName, [string]$TocPath)

    $hash = (Get-FileHash -LiteralPath $TocPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $destDir = Join-Path $BackupRoot $AddonName
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    $dest = Join-Path $destDir ("{0}-{1}" -f $hash, [System.IO.Path]::GetFileName($TocPath))

    if (-not (Test-Path -LiteralPath $dest)) {
        Copy-Item -LiteralPath $TocPath -Destination $dest -Force
    }
}

function Split-DependencyList {
    param([string]$Value)
    return @($Value -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
}

function Patch-Toc {
    param([string]$AddonName, [string]$TocPath)

    $info = Get-TextInfo $TocPath
    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($line in ($info.Text -split "`r`n|`n|`r")) { $lines.Add($line) }

    $markerIndex = -1
    $optionalIndex = -1
    $alreadyListed = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*##\s*X-WTFix-Managed\s*:\s*1\s*$') {
            $markerIndex = $i
        }
        if ($lines[$i] -match '^(\s*##\s*OptionalDeps\s*:\s*)(.*)$') {
            if ($optionalIndex -lt 0) { $optionalIndex = $i }
            foreach ($dep in @(Split-DependencyList $Matches[2])) {
                if ($dep -ieq "WTFix") { $alreadyListed = $true }
            }
        }
    }

    if ($alreadyListed -and $markerIndex -lt 0) {
        Write-LogOnly "Left $AddonName unchanged because its TOC already lists WTFix without a WTFix management marker."
        return $false
    }

    if ($alreadyListed -and $markerIndex -ge 0) {
        return $false
    }

    Backup-Toc $AddonName $TocPath

    if ($optionalIndex -ge 0) {
        $optionalMatch = [regex]::Match($lines[$optionalIndex], '^(\s*##\s*OptionalDeps\s*:\s*)(.*)$')
        if (-not $optionalMatch.Success) {
            throw "Could not parse OptionalDeps in $TocPath"
        }
        $prefix = $optionalMatch.Groups[1].Value
        $deps = New-Object System.Collections.Generic.List[string]
        foreach ($dep in @(Split-DependencyList $optionalMatch.Groups[2].Value)) { $deps.Add($dep) }
        $deps.Add("WTFix")
        $lines[$optionalIndex] = $prefix + ($deps -join ", ")

        if ($markerIndex -lt 0) {
            $lines.Insert($optionalIndex + 1, "## X-WTFix-Managed: 1")
        }
    }
    else {
        $insertAt = 0
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^\s*##') {
                $insertAt = $i + 1
                continue
            }
            if ($lines[$i].Trim() -eq "") {
                if ($insertAt -eq $i) { $insertAt = $i + 1 }
                continue
            }
            break
        }
        $lines.Insert($insertAt, "## OptionalDeps: WTFix")
        if ($markerIndex -lt 0) {
            $lines.Insert($insertAt + 1, "## X-WTFix-Managed: 1")
        }
    }

    $newText = $lines -join $info.Newline
    Write-TextInfo $TocPath $newText $info
    Write-LogOnly "Patched load order: $AddonName -> $([System.IO.Path]::GetFileName($TocPath))"
    return $true
}

function Unpatch-Toc {
    param([string]$AddonName, [string]$TocPath)

    $info = Get-TextInfo $TocPath
    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($line in ($info.Text -split "`r`n|`n|`r")) { $lines.Add($line) }

    $managed = $false
    foreach ($line in $lines) {
        if ($line -match '^\s*##\s*X-WTFix-Managed\s*:\s*1\s*$') {
            $managed = $true
            break
        }
    }

    if (-not $managed) { return $false }

    Backup-Toc $AddonName $TocPath

    $output = New-Object System.Collections.Generic.List[string]
    foreach ($line in $lines) {
        if ($line -match '^\s*##\s*X-WTFix-Managed\s*:\s*1\s*$') {
            continue
        }

        if ($line -match '^(\s*##\s*OptionalDeps\s*:\s*)(.*)$') {
            $prefix = $Matches[1]
            $deps = @(Split-DependencyList $Matches[2] | Where-Object { $_ -ine "WTFix" })
            if ($deps.Count -gt 0) {
                $output.Add($prefix + ($deps -join ", "))
            }
            continue
        }

        $output.Add($line)
    }

    Write-TextInfo $TocPath ($output -join $info.Newline) $info
    Write-LogOnly "Removed WTFix load-order entry: $AddonName -> $([System.IO.Path]::GetFileName($TocPath))"
    return $true
}

function Remove-CompanionAddon {
    param([string]$AddOnsRoot)
    $root = [IO.Path]::GetFullPath((Join-Path $AddOnsRoot "WTFix_Data"))
    $item = Get-Item -LiteralPath $root -Force -ErrorAction SilentlyContinue
    if (-not $item) { return }
    if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw "WTFix_Data root is not an ordinary directory. Refusing to follow or replace it."
    }
    # Enumerate one level at a time. Never recurse into a directory link, even
    # one not created by WTFix. Delete only the link itself, not its target.
    $stack = New-Object System.Collections.Generic.Stack[string]
    $directories = New-Object System.Collections.Generic.List[string]
    $stack.Push($root)
    while ($stack.Count -gt 0) {
        $directory = $stack.Pop()
        if ($directory -ne $root -and -not $directory.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase)) {
            throw "Companion removal path escaped the WTFix_Data directory."
        }
        $directories.Add($directory)
        foreach ($child in @(Get-ChildItem -LiteralPath $directory -Force)) {
            if ($child.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                if ($child.PSIsContainer) { [IO.Directory]::Delete($child.FullName, $false) }
                else { [IO.File]::Delete($child.FullName) }
            } elseif ($child.PSIsContainer) {
                $stack.Push($child.FullName)
            } else {
                [IO.File]::Delete($child.FullName)
            }
        }
    }
    for ($i = $directories.Count - 1; $i -ge 0; $i--) { [IO.Directory]::Delete($directories[$i], $false) }
}

function Install-DiskBridge {
    param([string]$RuntimeAddonRoot, $AccountFolder)
    if (-not $AccountFolder) { throw "No WoW account folder exists. Log in once, exit WoW, then run the launcher." }
    $target = [IO.Path]::GetFullPath((Join-Path $AccountFolder.FullName "SavedVariables"))
    New-Item -ItemType Directory -Path $target -Force | Out-Null
    $link = [IO.Path]::GetFullPath((Join-Path $RuntimeAddonRoot "Disk"))
    $existing = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
    if ($existing) {
        if ($existing.LinkType -ne 'Junction') { throw "Disk bridge path is occupied by an unmanaged file or directory." }
        [IO.Directory]::Delete($link, $false)
    }
    New-Item -ItemType Junction -Path $link -Target $target -ErrorAction Stop | Out-Null
    $actual = Get-Item -LiteralPath $link -Force
    if ($actual.LinkType -ne 'Junction' -or [IO.Path]::GetFullPath([string]@($actual.Target)[0]) -ine $target) {
        throw "Disk bridge target verification failed. WoW was not started."
    }

    # A fixed TOC file must exist even on a first install. Create only our own
    # missing file, exclusively; never truncate/replace existing SavedVariables.
    $primary = Join-Path $target 'WTFix.lua'
    if (-not (Test-Path -LiteralPath $primary -PathType Leaf)) {
        $stream = [IO.File]::Open($primary, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try {
            $bytes = [Text.Encoding]::UTF8.GetBytes("WTFIX_DB = {}`n")
            $stream.Write($bytes, 0, $bytes.Length)
        } finally { $stream.Dispose() }
        Write-Log "Initialized missing WTFix SavedVariables file for the disk bridge."
    }
    if ((Get-FileHash -LiteralPath $primary).Hash -ne (Get-FileHash -LiteralPath (Join-Path $link 'WTFix.lua')).Hash) {
        throw "Disk bridge file verification failed. WoW was not started."
    }
    Write-Log "Disk bridge prepared and verified for the selected account."
}

function Install-RuntimeAddon {
    param([string]$AddOnsRoot)

    $dest = Join-Path $AddOnsRoot "WTFix"
    if (Test-Path -LiteralPath $dest) {
        Assert-BridgeCompatibility $dest 'WTFix.toc'
        return $dest
    }
    if (-not (Test-Path -LiteralPath $SourceAddonRoot -PathType Container)) {
        throw "WTFix runtime is not installed. Install the compatible addon package or use WTFix-Full."
    }
    Assert-BridgeCompatibility $SourceAddonRoot 'WTFix.toc'
    New-Item -ItemType Directory -Path $dest | Out-Null

    foreach ($item in @(Get-ChildItem -LiteralPath $SourceAddonRoot -Force)) {
        Copy-Item -LiteralPath $item.FullName -Destination $dest -Recurse -Force
    }

    return $dest
}

function Assert-BridgeCompatibility {
    param([string]$Root, [string]$TocName)
    $item = Get-Item -LiteralPath $Root -Force -ErrorAction Stop
    if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "WTFix installation root must be an ordinary directory." }
    $toc = Join-Path $Root $TocName
    $text = if (Test-Path -LiteralPath $toc -PathType Leaf) { [IO.File]::ReadAllText($toc) } else { '' }
    $matchesProtocol = [regex]::Matches($text, '(?m)^## X-WTFix-Bridge-Protocol:\s*(\d+)\s*$')
    if ($matchesProtocol.Count -ne 1 -or [int]$matchesProtocol[0].Groups[1].Value -ne $BridgeProtocol) {
        throw "Incompatible WTFix installation: update the runtime and launcher to compatible bridge-protocol versions. Existing runtime files were not replaced. See README for migration from 0.8.7."
    }
}

function Install-CompanionAddon {
    param([string]$AddOnsRoot)
    Assert-BridgeCompatibility (Join-Path $AddOnsRoot 'WTFix') 'WTFix.toc'
    $dest = Join-Path $AddOnsRoot 'WTFix_Data'
    Assert-BridgeCompatibility $SourceCompanionRoot 'WTFix_Data.toc'
    if (Test-Path -LiteralPath $dest) { Assert-BridgeCompatibility $dest 'WTFix_Data.toc' }
    Remove-CompanionAddon $AddOnsRoot
    New-Item -ItemType Directory -Path $dest | Out-Null
    foreach ($item in @(Get-ChildItem -LiteralPath $SourceCompanionRoot -Force)) {
        Copy-Item -LiteralPath $item.FullName -Destination $dest -Recurse -Force
    }
    return $dest
}

function Get-PreparedCharacters {
    param($AccountFolder)
    # Directory membership is conservative evidence, NOT an authenticated account ID.
    # Forever's native realm ID differs from the WTF folder number. Require a
    # unique normalized name across ALL local account/realm character folders.
    $rows = @()
    foreach ($account in @(Get-ChildItem -LiteralPath $AccountFolder.Parent.FullName -Directory)) {
        foreach ($realm in @(Get-ChildItem -LiteralPath $account.FullName -Directory | Where-Object { $_.Name -ne 'SavedVariables' })) {
            foreach ($character in @(Get-ChildItem -LiteralPath $realm.FullName -Directory)) {
                $key = $character.Name.Replace(' ', '').Replace('-', '')
                $rows += [pscustomobject]@{ Account=$account.FullName; Realm=$realm.Name; Name=$character.Name; Key=$key }
            }
        }
    }
    $result = @($rows | Where-Object { $_.Account -eq $AccountFolder.FullName } | Where-Object {
        $key = $_.Key
        @($rows | Where-Object { $_.Key -eq $key }).Count -eq 1
    })
    if ($result.Count -eq 0) { throw "No uniquely identifiable character folders for this account. Log into a character once, exit, then prepare the correct account." }
    return $result
}

function Write-BridgeEvidence {
    param($AccountFolder, [string]$PreparationId)
    $path = Join-Path $AccountFolder.FullName 'SavedVariables\WTFix_Bridge.lua'
    $item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
    if ($item -and (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -or $item.PSIsContainer -or
        -not [IO.File]::ReadAllText($path).StartsWith('-- WTFix bridge protocol 1'))) { throw "Bridge evidence path is occupied by unmanaged data." }
    $text = "-- WTFix bridge protocol 1`nWTFIX_BRIDGE_EVIDENCE = { protocol = $BridgeProtocol, id = $(ConvertTo-LuaString $PreparationId) }`n"
    $pending = $path + '.' + [Guid]::NewGuid().ToString('N') + '.tmp'
    try {
        [IO.File]::WriteAllText($pending, $text, (New-Object Text.UTF8Encoding($false)))
        if ($item) { [IO.File]::Replace($pending, $path, [Management.Automation.Language.NullString]::Value) }
        else { [IO.File]::Move($pending, $path) }
    } finally { if (Test-Path -LiteralPath $pending) { Remove-Item -LiteralPath $pending -Force } }
}

function ConvertTo-LuaString {
    param([string]$Value)
    if ($null -eq $Value) { return '""' }

    $escaped = $Value.Replace('\', '\\').Replace('"', '\"').Replace("`r", '\r').Replace("`n", '\n').Replace("`t", '\t')
    return '"' + $escaped + '"'
}

function ConvertTo-LuaByteString {
    param([byte[]]$Bytes)
    # SavedVariables are Lua byte streams, not text in the Windows code page.
    # Encode the OUTER Lua literal only. The runtime receives the original source
    # bytes and its data-only parser then reads the INNER SavedVariables literals.
    # Three decimal digits prevent a following ASCII digit extending an escape.
    $escaped = New-Object 'string[]' 256
    for ($i = 0; $i -lt 256; $i++) {
        $escaped[$i] = if ($i -ge 32 -and $i -le 126 -and $i -ne 34 -and $i -ne 92) {
            [string][char]$i
        } else { '\' + $i.ToString('D3', [Globalization.CultureInfo]::InvariantCulture) }
    }
    $literal = New-Object System.Text.StringBuilder
    [void]$literal.Append('"')
    foreach ($byte in $Bytes) { [void]$literal.Append($escaped[$byte]) }
    [void]$literal.Append('"')
    return $literal.ToString()
}

function Backup-RecoveryInputs {
    param($AccountFolder)
    if (-not $AccountFolder) { return }

    # Append-only, content-addressed copies. Never rotate the only good backup
    # away when a stale runtime has subsequently written the primary file.
    $historyRoot = Join-Path $StateRoot "snapshot-history"
    $objectsRoot = Join-Path $historyRoot "objects"
    New-Item -ItemType Directory -Path $objectsRoot -Force | Out-Null
    $records = @()
    foreach ($file in @(Get-ChildItem -LiteralPath $AccountFolder.FullName -Recurse -File |
        Where-Object { $_.Directory.Name -eq "SavedVariables" -and $_.Name -match '\.lua(\.bak)?$' })) {
        $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        $destination = Join-Path $objectsRoot ($hash + ".lua")
        if (-not (Test-Path -LiteralPath $destination)) {
            [System.IO.File]::Copy($file.FullName, $destination, $false)
        }
        if ((Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash -ne $hash) {
            throw "Recovery input backup verification failed. Launch stopped."
        }
        $records += [pscustomobject]@{
            RelativePath = $file.FullName.Substring($AccountFolder.FullName.Length + 1)
            SHA256 = $hash
            Length = $file.Length
            LastWriteTimeUtc = $file.LastWriteTimeUtc.ToString("o")
        }
    }
    $manifest = [pscustomobject]@{
        Version = $WTFixVersion
        AccountPath = $AccountFolder.FullName
        CreatedAtUtc = [DateTime]::UtcNow.ToString("o")
        Files = @($records)
    }
    $manifestName = (Get-Date -Format "yyyyMMdd-HHmmss") + "-" + [Guid]::NewGuid().ToString("N") + ".json"
    $manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $historyRoot $manifestName) -Encoding UTF8
    Write-Log "Recovery input backup verified: $($records.Count) file(s)."
}

function Add-PrivateSavedVariablesBlock {
    param(
        [System.Text.StringBuilder]$Builder,
        [string]$Path,
        [string]$AfterSource
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }

    $source = ConvertTo-LuaByteString ([System.IO.File]::ReadAllBytes($Path))
    $label = ConvertTo-LuaString ([System.IO.Path]::GetFileName($Path))
    [void]$Builder.AppendLine("do")
    [void]$Builder.AppendLine("  local __wtfix_env, __wtfix_error = ns.ReadSavedVariables($source)")
    [void]$Builder.AppendLine("  if __wtfix_env then")
    [void]$Builder.AppendLine($AfterSource)
    [void]$Builder.AppendLine("  else")
    [void]$Builder.AppendLine("    WTFIX_BOOTSTRAP.warnings[#WTFIX_BOOTSTRAP.warnings + 1] = $label .. ': ' .. tostring(__wtfix_error)")
    [void]$Builder.AppendLine("  end")
    [void]$Builder.AppendLine("end")
    return $true
}

function Generate-Bootstrap {
    param(
        [string]$RuntimeAddonRoot,
        [object[]]$Definitions,
        $AccountFolder,
        [string]$PreparationId,
        [object[]]$Characters
    )

    $builder = New-Object System.Text.StringBuilder
    [void]$builder.AppendLine("-- Generated by WTFix $WTFixVersion before launch. Do not edit.")
    [void]$builder.AppendLine("WTFIX_PREPARATION = { protocol = $BridgeProtocol, id = $(ConvertTo-LuaString $PreparationId), binding = `"unique-character-name`", characters = {")
    foreach ($character in $Characters) {
        [void]$builder.AppendLine("{ realm = $(ConvertTo-LuaString $character.Realm), name = $(ConvertTo-LuaString $character.Name) },")
    }
    [void]$builder.AppendLine("} }")
    [void]$builder.AppendLine("WTFIX_PREPARATION.bootstrap = function(ns)")
    [void]$builder.AppendLine("WTFIX_BOOTSTRAP = {")
    [void]$builder.AppendLine("  generated = true,")
    [void]$builder.AppendLine("  diskBridge = true,")
    [void]$builder.AppendLine("  launcherVersion = $(ConvertTo-LuaString $WTFixVersion),")
    [void]$builder.AppendLine("  targets = {},")
    [void]$builder.AppendLine("  snapshot = nil,")
    [void]$builder.AppendLine("  config = nil,")
    [void]$builder.AppendLine("  warnings = {},")
    [void]$builder.AppendLine("  fallback = { account = {}, characters = {} },")
    [void]$builder.AppendLine("}")
    [void]$builder.AppendLine("")

    foreach ($def in $Definitions) {
        [void]$builder.AppendLine("WTFIX_BOOTSTRAP.targets[$(ConvertTo-LuaString $def.Name)] = {")
        [void]$builder.Append("  account = {")
        foreach ($name in $def.AccountVars) { [void]$builder.Append("$(ConvertTo-LuaString $name),") }
        [void]$builder.AppendLine("},")
        [void]$builder.Append("  character = {")
        foreach ($name in $def.CharacterVars) { [void]$builder.Append("$(ConvertTo-LuaString $name),") }
        [void]$builder.AppendLine("},")
        [void]$builder.AppendLine("}")
    }

    [void]$builder.AppendLine("")

    $accountSnapshots = 0
    $characterSnapshots = 0
    $protectedSnapshotFound = $false

    if ($AccountFolder) {
        $accountSVRoot = Join-Path $AccountFolder.FullName "SavedVariables"
        $wtfixSource = Join-Path $accountSVRoot "WTFix.lua"

        # Primary wins ties; a valid strictly newer backup recovers the shutdown
        # rollback observed in 0.8.3. Config prefers primary independently.
        foreach ($candidatePath in @($wtfixSource, ($wtfixSource + ".bak"))) {
            $wtfixAfter = "    ns.ImportBootstrapSnapshot(__wtfix_env, $(ConvertTo-LuaString ([IO.Path]::GetFileName($candidatePath))))"
            if (Add-PrivateSavedVariablesBlock $builder $candidatePath $wtfixAfter) {
                $protectedSnapshotFound = $true
            }
        }

        foreach ($def in $Definitions) {
            if ($def.AccountVars.Count -eq 0) { continue }
            $source = Join-Path $accountSVRoot ($def.Name + ".lua")
            $after = "  WTFIX_BOOTSTRAP.fallback.account[$(ConvertTo-LuaString $def.Name)] = __wtfix_env"
            if (Add-PrivateSavedVariablesBlock $builder $source $after) {
                $accountSnapshots++
            }
        }

        $characterSVDirs = @(
            Get-ChildItem -LiteralPath $AccountFolder.FullName -Directory -Recurse -ErrorAction SilentlyContinue |
                Where-Object {
                    $_.Name -eq "SavedVariables" -and
                    $_.FullName -ne $accountSVRoot
                }
        )

        foreach ($svDir in $characterSVDirs) {
            $characterDir = $svDir.Parent
            if (-not $characterDir -or -not $characterDir.Parent) { continue }

            $realmFolder = $characterDir.Parent.Name
            $characterName = $characterDir.Name
            $characterHeaderWritten = $false
            $recordIndex = 0

            foreach ($def in $Definitions) {
                if ($def.CharacterVars.Count -eq 0) { continue }
                $source = Join-Path $svDir.FullName ($def.Name + ".lua")
                if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { continue }

                if (-not $characterHeaderWritten) {
                    [void]$builder.AppendLine("do")
                    [void]$builder.AppendLine("  local __record = {")
                    [void]$builder.AppendLine("    realmFolder = $(ConvertTo-LuaString $realmFolder),")
                    [void]$builder.AppendLine("    characterName = $(ConvertTo-LuaString $characterName),")
                    [void]$builder.AppendLine("    addons = {},")
                    [void]$builder.AppendLine("  }")
                    [void]$builder.AppendLine("  WTFIX_BOOTSTRAP.fallback.characters[#WTFIX_BOOTSTRAP.fallback.characters + 1] = __record")
                    $characterHeaderWritten = $true
                }

                $after = "    __record.addons[$(ConvertTo-LuaString $def.Name)] = __wtfix_env"
                [void](Add-PrivateSavedVariablesBlock $builder $source $after)
                $characterSnapshots++
                $recordIndex++
            }

            if ($characterHeaderWritten) {
                [void]$builder.AppendLine("end")
            }
        }
    }

    [void]$builder.AppendLine("end")
    $bootstrapPath = Join-Path $RuntimeAddonRoot "BootstrapData.lua"
    $pendingPath = Join-Path $RuntimeAddonRoot ("BootstrapData-" + [Guid]::NewGuid().ToString("N") + ".tmp")
    try {
        [System.IO.File]::WriteAllText($pendingPath, $builder.ToString(), (New-Object System.Text.UTF8Encoding($false)))
        if (Test-Path -LiteralPath $bootstrapPath) {
            [System.IO.File]::Replace($pendingPath, $bootstrapPath, [System.Management.Automation.Language.NullString]::Value)
        } else {
            [System.IO.File]::Move($pendingPath, $bootstrapPath)
        }
    } finally {
        if (Test-Path -LiteralPath $pendingPath) { Remove-Item -LiteralPath $pendingPath -Force }
    }

    $snapshotLabel = if ($protectedSnapshotFound) { "snapshot candidates (validated in-game)" } else { "disk fallback" }
    Write-Log "Recovery prepared: $snapshotLabel, $accountSnapshots account file(s), $characterSnapshots character file(s)." Green
}

function Assert-WowNotRunning {
    $running = @(Get-Process -Name "WowB" -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) {
        throw "WoW Forever is already running. Close WowB.exe before WTFix changes addon files."
    }
}

function Invoke-Uninstall {
    $config = Load-Config
    if (-not $config.ContainsKey("WowPath")) {
        Write-Log "No configured WoW path was found. Nothing was changed in WoW."
        return
    }

    $wowPath = Normalize-WowPath $config.WowPath
    if (-not $wowPath) {
        throw "The saved WoW path is no longer valid. Use Change WoW Location.cmd first if the game was moved."
    }

    Assert-WowNotRunning

    $addOnsRoot = Join-Path $wowPath "Interface\AddOns"
    $managedTocs = @(
        Get-ChildItem -LiteralPath $addOnsRoot -Recurse -File -Filter "*.toc" -ErrorAction SilentlyContinue |
            Where-Object {
                (Get-Content -LiteralPath $_.FullName -Raw -ErrorAction SilentlyContinue) -match '(?m)^\s*##\s*X-WTFix-Managed\s*:\s*1\s*$'
            }
    )

    foreach ($toc in $managedTocs) {
        Unpatch-Toc $toc.Directory.Name $toc.FullName | Out-Null
    }

    Remove-CompanionAddon $addOnsRoot
    Write-Log "Preparation removed. Runtime retained for its addon manager. All SavedVariables were retained."
    Write-Host "Local recovery history, configuration, logs and TOC backups are retained at: $StateRoot"
}

try {
    Write-Log "WTFix $WTFixVersion"

    if ($Uninstall) {
        Invoke-Uninstall
        exit 0
    }

    $config = Load-Config
    $wowPath = Resolve-WowPath $config -ForcePicker:$Configure
    $config.WowPath = $wowPath

    if ($Configure) {
        Save-Config $config
        Write-Log "Saved WoW Forever location: $wowPath"
        exit 0
    }

    if (-not $Launch) {
        $Launch = $true
    }

    Assert-WowNotRunning

    $addOnsRoot = Join-Path $wowPath "Interface\AddOns"
    # Compatibility preflight precedes preparation, junction and managed TOC writes.
    $runtimeRoot = Join-Path $addOnsRoot 'WTFix'
    if (Test-Path -LiteralPath $runtimeRoot) { Assert-BridgeCompatibility $runtimeRoot 'WTFix.toc' }
    elseif (Test-Path -LiteralPath $SourceAddonRoot -PathType Container) { Assert-BridgeCompatibility $SourceAddonRoot 'WTFix.toc' }
    else { throw "WTFix runtime is missing. Install the compatible addon package or use WTFix-Full, then run the launcher." }
    Assert-BridgeCompatibility $SourceCompanionRoot 'WTFix_Data.toc'
    $dataRoot = Join-Path $addOnsRoot 'WTFix_Data'
    if (Test-Path -LiteralPath $dataRoot) { Assert-BridgeCompatibility $dataRoot 'WTFix_Data.toc' }

    $accounts = @(Get-AccountFolders $wowPath)
    Write-Log "Detected WoW account folders: $($accounts.Count)"
    $selectedAccount = Select-AccountFolder $accounts $config
    if (-not $selectedAccount) { throw "No WoW account folder exists. Log in once, exit WoW, then run the launcher." }
    $preparedCharacters = @(Get-PreparedCharacters $selectedAccount)
    if ($selectedAccount) {
        $config.LastAccountFolder = $selectedAccount.Name
        Write-Log "Selected one of $($accounts.Count) account folder(s) for this launch."
    }
    Backup-RecoveryInputs $selectedAccount

    $addOnsRoot = Join-Path $wowPath "Interface\AddOns"
    $runtimeRoot = Install-RuntimeAddon $addOnsRoot
    $dataRoot = Install-CompanionAddon $addOnsRoot
    Install-DiskBridge $dataRoot $selectedAccount
    $preparationId = [Guid]::NewGuid().ToString('N')
    Write-BridgeEvidence $selectedAccount $preparationId

    $definitions = @(Get-AddonDefinitions $addOnsRoot)
    Write-Log "Detected $($definitions.Count) addon(s) using standard SavedVariables." Cyan
    foreach ($def in $definitions) {
        Write-LogOnly "Protecting $($def.Name): account=$($def.AccountVars.Count), character=$($def.CharacterVars.Count)"
    }

    $patched = 0
    foreach ($def in $definitions) {
        foreach ($tocPath in $def.Tocs) {
            try {
                if (Patch-Toc $def.Name $tocPath) { $patched++ }
            }
            catch {
                Write-Log "Skipped TOC patch for $($def.Name): $($_.Exception.Message)"
            }
        }
    }
    Write-Log "Load-order updates this run: $patched"

    $battleNetPath = $null
    if (-not $DirectWowB) {
        $battleNetPath = Resolve-BattleNetPath $config
        $config.BattleNetPath = $battleNetPath
    }

    Save-Config $config
    Generate-Bootstrap $dataRoot $definitions $selectedAccount $preparationId $preparedCharacters

    if ($DirectWowB) {
        $exe = Join-Path $wowPath "WowB.exe"
        Write-Log "DEBUG: launching WowB.exe directly because -DirectWowB was explicitly requested."
        Start-Process -FilePath $exe -WorkingDirectory $wowPath | Out-Null
    }
    else {
        Start-BattleNetForever $battleNetPath
    }

    exit 0
}
catch {
    Write-Log ("ERROR: " + $_.Exception.Message) Red
    exit 1
}
