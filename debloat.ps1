# ============================================================
#  Universal Windows 10/11 Debloat & Optimize Script
#  Architecture-agnostic: works on x64, ARM64, VMware, baremetal, and Server
#  Run as Administrator in PowerShell
# ============================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('Home', 'Pro', 'Enterprise', 'Education', 'Server', 'Core')]
    [string] $WindowsEdition = 'Pro',

    [Parameter(Mandatory = $false)]
    [switch] $WhatIf,

    [Parameter(Mandatory = $false)]
    [switch] $VerboseLogging
)

# ── ELEVATION GUARD ─────────────────────────────────────────
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Error: This script must be run as an Administrator."
    exit 1
}

# Core system dependency packages that must never be removed
$ProtectedPackages = @(
    "Microsoft.WindowsStore",
    "Microsoft.UI.Xaml",
    "Microsoft.DesktopAppInstaller",
    "Microsoft.WindowsCalculator",
    "Microsoft.Windows.ShellExperienceHost",
    "Microsoft.Windows.StartMenuExperienceHost",
    "Microsoft.Windows.Cortana",
    "Microsoft.AAD.BrokerPlugin",
    "Microsoft.AccountsControl",
    "Microsoft.LockApp",
    "Microsoft.Windows.ContentDeliveryManager",
    "Microsoft.Windows.PeopleExperienceHost",
    "Microsoft.XboxGameCallableUI"
)

function Test-RegistryKey {
    param([string]$Path)
    return (Test-Path -Path $Path -ErrorAction SilentlyContinue)
}

function Set-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [string]$Type,
        [string]$Value
    )
    try {
        if (-not (Test-RegistryKey -Path $Path)) {
            if (-not $WhatIf) {
                New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
            } else {
                Write-Host "     [WhatIf] Would create key: $Path" -ForegroundColor DarkGray
                return
            }
        }
        if (-not $WhatIf) {
            reg add $Path /v $Name /t $Type /d $Value /f | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "reg.exe returned exit code $LASTEXITCODE" }
        } else {
            Write-Host "     [WhatIf] Would set $Path\$Name = $Value" -ForegroundColor DarkGray
        }
    } catch {
        Write-Warning "Failed to set registry value $Path\$Name : $_"
    }
}

Write-Host "" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Universal Windows 10/11 Debloat & Optimize" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Detect architecture
$isARM64 = ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') -or ($env:PROCESSOR_ARCHITEW6432 -eq 'ARM64')
$architecture = if ($isARM64) { "ARM64" } else { "x64" }
Write-Host "[1/9] Detecting architecture: $architecture" -ForegroundColor Yellow
Write-Host "     Windows Edition: $WindowsEdition" -ForegroundColor Yellow

# ── CLIPBOARD FIX ────────────────────────────────────────────
Write-Host "" -ForegroundColor Yellow
Write-Host "[2/9] Fixing clipboard integration..." -ForegroundColor Yellow

$isVmware = $false
try {
    $vmwareVersion = (Get-ItemProperty "HKLM:\SOFTWARE\VMware, Inc.\VMware Tools" -ErrorAction SilentlyContinue).ToolsVersion
    if ($vmwareVersion) { $isVmware = $true }
} catch { Write-Warning "VMware detection failed: $_" }

if ($isVmware) {
    Write-Host "     Detected VMware environment" -ForegroundColor Green
    try {
        $vmClipboard = Get-Service -Name "VMwareClipboard" -ErrorAction SilentlyContinue
        if ($vmClipboard) {
            if (-not $WhatIf) { Restart-Service -Name "VMwareClipboard" -Force -ErrorAction Stop }
            Set-Service -Name "VMwareClipboard" -StartupType Automatic -ErrorAction Stop
            Write-Host "     VMware Clipboard service restarted." -ForegroundColor Green
        } else {
            Write-Host "     VMware Clipboard service not found — reinstall VMware Tools." -ForegroundColor Yellow
        }
        $vmTools = Get-Service -Name "VMTools" -ErrorAction SilentlyContinue
        if ($vmTools) {
            if (-not $WhatIf) { Restart-Service -Name "VMTools" -Force -ErrorAction Stop }
            Write-Host "     VMware Tools service restarted." -ForegroundColor Green
        }
        if (-not $WhatIf) {
            reg add "HKLM\SOFTWARE\VMware, Inc.\VMware Tools" /v "EnableCopyPaste" /t REG_DWORD /d 1 /f | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "reg.exe returned exit code $LASTEXITCODE" }
        }
    } catch {
        Write-Warning "VMware clipboard fix failed: $_"
    }
} else {
    Write-Host "     Not a VMware environment — skipping VMware-specific clipboard fix." -ForegroundColor Gray
}

Write-Host ""

# ── WINDOWS EDITION-AWARE BLOATWARE LISTS ────────────────────
Write-Host "[3/9] Loading bloatware lists for $WindowsEdition edition..." -ForegroundColor Yellow

$appsX64 = @(
    "Microsoft.BingNews","Microsoft.BingWeather","Microsoft.BingFinance","Microsoft.BingSports",
    "Microsoft.GetHelp","Microsoft.Getstarted","Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftSolitaireCollection","Microsoft.People","Microsoft.PowerAutomateDesktop",
    "Microsoft.Teams","Microsoft.Todos","Microsoft.WindowsFeedbackHub","Microsoft.WindowsMaps",
    "Microsoft.WindowsSoundRecorder","Microsoft.Xbox.TCUI","Microsoft.XboxApp",
    "Microsoft.XboxGameOverlay","Microsoft.XboxGamingOverlay","Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay","Microsoft.YourPhone","Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo","MicrosoftTeams","Clipchamp.Clipchamp","Microsoft.GamingApp",
    "Microsoft.MixedReality.Portal","Microsoft.SkypeApp","Microsoft.windowscommunicationsapps",
    "Microsoft.WindowsAlarms","Microsoft.549981C3F5F10"
)

$appsARM64 = $appsX64 + @("Microsoft.Bard","Microsoft.CloudClip")

$editionSpecificApps = @()
switch ($WindowsEdition) {
    'Home'       { $editionSpecificApps = @("Microsoft.BingFinance","Microsoft.BingSports","Microsoft.MicrosoftSolitaireCollection","Microsoft.MicrosoftOfficeHub") }
    'Pro'        { $editionSpecificApps = @("Microsoft.BingFinance","Microsoft.BingSports","Microsoft.MicrosoftSolitaireCollection") }
    'Enterprise' { $editionSpecificApps = @() }
    'Education'  { $editionSpecificApps = @("Microsoft.BingFinance","Microsoft.BingSports") }
    'Server'     { $editionSpecificApps = @("Microsoft.BingNews","Microsoft.BingWeather","Microsoft.GetHelp","Microsoft.Getstarted","Microsoft.People","Microsoft.WindowsFeedbackHub","Microsoft.WindowsMaps","Microsoft.WindowsSoundRecorder","Microsoft.Xbox.TCUI","Microsoft.XboxApp","Microsoft.XboxGameOverlay","Microsoft.XboxGamingOverlay","Microsoft.XboxIdentityProvider","Microsoft.XboxSpeechToTextOverlay","Microsoft.YourPhone","Microsoft.ZuneMusic","Microsoft.ZuneVideo","MicrosoftTeams","Clipchamp.Clipchamp","Microsoft.SkypeApp","Microsoft.windowscommunicationsapps","Microsoft.WindowsAlarms","Microsoft.549981C3F5F10") }
    default      { $editionSpecificApps = @() }
}

$allX64Apps  = if ($WindowsEdition -eq 'Enterprise') { $appsX64 } else { $appsX64 + $editionSpecificApps }
$allARM64Apps = if ($WindowsEdition -eq 'Enterprise') { $appsARM64 } else { $appsARM64 + $editionSpecificApps }

# ── ASK USER WHICH APPS TO REMOVE ───────────────────────────
Write-Host "" -ForegroundColor Yellow
Write-Host "[4/9] Select applications to remove..." -ForegroundColor Yellow

$selectedApps = @()
Write-Host "   The following system apps will be asked for removal:" -ForegroundColor Cyan
Write-Host "   • Microsoft Edge" -ForegroundColor Gray
Write-Host "   • Microsoft Copilot" -ForegroundColor Gray
Write-Host ""

$removeEdge = Read-Host "   Remove Microsoft Edge? (y/n)" -DefaultValue 'n'
if ($removeEdge -match '[Yy]') {
    $selectedApps += "Microsoft.Edge"
    Write-Host "     ✓ Selected: Microsoft Edge" -ForegroundColor Green
}

$removeCopilot = Read-Host "   Remove Microsoft Copilot? (y/n)" -DefaultValue 'n'
if ($removeCopilot -match '[Yy]') {
    $selectedApps += "Microsoft.Copilot"
    Write-Host "     ✓ Selected: Microsoft Copilot" -ForegroundColor Green
}

$appsToRemove = if ($isARM64) { $allARM64Apps } else { $allX64Apps }
foreach ($app in $appsToRemove) {
    $displayName = ($app -replace '^Microsoft\.', 'Microsoft ')
    $check = Read-Host "   Remove $displayName? (y/n)" -DefaultValue 'n'
    if ($check -match '[Yy]') {
        $selectedApps += $app
        Write-Host "     ✓ Selected: $app" -ForegroundColor Green
    }
}

Write-Host "   Selected $($selectedApps.Count) apps for removal." -ForegroundColor Green
Write-Host ""

# ── REMOVE BLOAT APPS (protected) ───────────────────────────
Write-Host "[5/9] Removing selected bloat apps..." -ForegroundColor Yellow

foreach ($app in $selectedApps) {
    # Protect core system dependencies
    $isProtected = $false
    foreach ($protected in $ProtectedPackages) {
        if ($app -like "*$protected*") { $isProtected = $true; break }
    }
    if ($isProtected) {
        Write-Warning "Skipping protected package: $app"
        continue
    }

    try {
        $pkg = Get-AppxPackage -Name $app -ErrorAction Stop
        if ($pkg) {
            if (-not $WhatIf) {
                Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction Stop
            }
            Write-Host "     Removed: $app" -ForegroundColor Green
        }
    } catch {
        Write-Warning "Failed to remove $app : $_"
    }

    try {
        if (-not $WhatIf) {
            Get-AppxProvisionedPackage -Online -ErrorAction Stop |
                Where-Object DisplayName -eq $app |
                Remove-AppxProvisionedPackage -Online -ErrorAction Stop | Out-Null
        }
        Write-Host "     Unprovisioned: $app" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to unprovision $app : $_"
    }
}

Write-Host ""

# ── DISABLE TELEMETRY ────────────────────────────────────────
Write-Host "[6/9] Disabling telemetry & tracking..." -ForegroundColor Yellow

$telemetryKeys = @(
    @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "AllowTelemetry"; Type = "REG_DWORD"; Value = "0" },
    @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "AllowCortana"; Type = "REG_DWORD"; Value = "0" },
    @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "EnableActivityFeed"; Type = "REG_DWORD"; Value = "0" },
    @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; Name = "Enabled"; Type = "REG_DWORD"; Value = "0" },
    @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"; Name = "AllowTelemetry"; Type = "REG_DWORD"; Value = "0" },
    @{ Path = "HKCU:\SOFTWARE\Microsoft\Personalization\Settings"; Name = "AcceptedPrivacyPolicy"; Type = "REG_DWORD"; Value = "0" },
    @{ Path = "HKCU:\SOFTWARE\Microsoft\InputPersonalization"; Name = "RestrictImplicitInkCollection"; Type = "REG_DWORD"; Value = "1" },
    @{ Path = "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore"; Name = "HarvestContacts"; Type = "REG_DWORD"; Value = "0" }
)

foreach ($k in $telemetryKeys) {
    Set-RegistryValue -Path $k.Path -Name $k.Name -Type $k.Type -Value $k.Value
}
Write-Host "     Telemetry disabled." -ForegroundColor Green
Write-Host ""

# ── DISABLE USELESS SERVICES ─────────────────────────────────
Write-Host "[7/9] Disabling unnecessary services..." -ForegroundColor Yellow

$services = @(
    @{ Name = "DiagTrack"; Desc = "Telemetry" },
    @{ Name = "dmwappushservice"; Desc = "WAP Push" },
    @{ Name = "SysMain"; Desc = "Superfetch" },
    @{ Name = "WSearch"; Desc = "Windows Search" },
    @{ Name = "XblAuthManager"; Desc = "Xbox Auth" },
    @{ Name = "XblGameSave"; Desc = "Xbox Game Save" },
    @{ Name = "XboxNetApiSvc"; Desc = "Xbox Network" },
    @{ Name = "RetailDemo"; Desc = "Retail Demo" },
    @{ Name = "MapsBroker"; Desc = "Maps Broker" },
    @{ Name = "lfsvc"; Desc = "Geolocation" },
    @{ Name = "SharedAccess"; Desc = "Internet Sharing" },
    @{ Name = "wisvc"; Desc = "Windows Insider" },
    @{ Name = "WerSvc"; Desc = "Error Reporting" },
    @{ Name = "wercplsupport"; Desc = "Error Reporting Support" }
)

if ($WindowsEdition -ne 'Server') {
    $services += @(
        @{ Name = "XboxGipSvc"; Desc = "Xbox Gip" },
        @{ Name = "XboxNetClt"; Desc = "Xbox Network Client" }
    )
}

foreach ($svc in $services) {
    try {
        $s = Get-Service -Name $svc.Name -ErrorAction Stop
        if ($s) {
            if (-not $WhatIf) {
                Stop-Service -Name $svc.Name -Force -ErrorAction Stop
                Set-Service -Name $svc.Name -StartupType Disabled -ErrorAction Stop
            }
            Write-Host "     Disabled: $($svc.Desc) ($($svc.Name))" -ForegroundColor Green
        }
    } catch {
        Write-Warning "Service $($svc.Name) not found or could not be disabled: $_"
    }
}

Write-Host ""

# ── PERFORMANCE TWEAKS ───────────────────────────────────────
Write-Host "[8/9] Applying performance tweaks..." -ForegroundColor Yellow

try {
    if (-not $WhatIf) { powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e | Out-Null }
} catch { Write-Host "     powercfg not available in this environment." -ForegroundColor Gray }

$perfKeys = @(
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"; Name = "VisualFXSetting"; Type = "REG_DWORD"; Value = "2" },
    @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Name = "EnableTransparency"; Type = "REG_DWORD"; Value = "0" },
    @{ Path = "HKCU:\Control Panel\Desktop\WindowMetrics"; Name = "MinAnimate"; Type = "REG_SZ"; Value = "0" },
    @{ Path = "HKCU:\Software\Microsoft\Windows\DWM"; Name = "EnableAeroPeek"; Type = "REG_DWORD"; Value = "0" },
    @{ Path = "HKCU:\Control Panel\Desktop"; Name = "WaitToKillAppTimeout"; Type = "REG_SZ"; Value = "2000" },
    @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control"; Name = "WaitToKillServiceTimeout"; Type = "REG_SZ"; Value = "2000" }
)

foreach ($k in $perfKeys) {
    Set-RegistryValue -Path $k.Path -Name $k.Name -Type $k.Type -Value $k.Value
}

if (-not $WhatIf) {
    try { reg add "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9012038010000000 /f | Out-Null } catch { Write-Warning "UserPreferencesMask set failed: $_" }
    try { powercfg /hibernate off | Out-Null } catch { Write-Warning "Hibernate disable failed: $_" }
}

$contentKeys = @(
    @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-338389Enabled"; Type = "REG_DWORD"; Value = "0" },
    @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-353694Enabled"; Type = "REG_DWORD"; Value = "0" },
    @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-353696Enabled"; Type = "REG_DWORD"; Value = "0" },
    @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SilentInstalledAppsEnabled"; Type = "REG_DWORD"; Value = "0" }
)
foreach ($k in $contentKeys) {
    Set-RegistryValue -Path $k.Path -Name $k.Name -Type $k.Type -Value $k.Value
}

Write-Host "     Performance tweaks applied." -ForegroundColor Green
Write-Host ""

# ── DISABLE SCHEDULED TASKS ──────────────────────────────────
Write-Host "[9/9] Disabling telemetry scheduled tasks..." -ForegroundColor Yellow

$tasks = @(
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
    "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
    "\Microsoft\Windows\Autochk\Proxy",
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
    "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
    "\Microsoft\Windows\Feedback\Siuf\DmClient",
    "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload",
    "\Microsoft\Windows\Windows Error Reporting\QueueReporting",
    "\Microsoft\Windows\Application Experience\StartupAppTask"
)

foreach ($task in $tasks) {
    try {
        if (-not $WhatIf) {
            Disable-ScheduledTask -TaskName $task -ErrorAction Stop | Out-Null
        }
        Write-Host "     Disabled task: $task" -ForegroundColor Green
    } catch {
        Write-Warning "Could not disable task $task : $_"
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
if ($WhatIf) {
    Write-Host "  [WhatIf Mode] All operations would complete." -ForegroundColor Cyan
    Write-Host "  Press Ctrl+C to exit without changes." -ForegroundColor Gray
} else {
    Write-Host "  All done! Rebooting in 10 seconds..." -ForegroundColor Cyan
    Write-Host "  Press Ctrl+C to cancel reboot." -ForegroundColor Gray
}
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

if (-not $WhatIf) {
    Start-Sleep -Seconds 10
    try { Restart-Computer -Force -ErrorAction Stop } catch { Write-Warning "Reboot failed: $_" }
} else {
    Write-Host "     Exiting WhatIf mode. No changes were applied." -ForegroundColor DarkGray
    Write-Host "     Run without -WhatIf to apply changes." -ForegroundColor DarkGray
}
