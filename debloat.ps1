# ============================================================
#  Universal Windows 10/11 Debloat & Optimize Script
#  Architecture-agnostic: works on x64, ARM64, VMware, baremetal, and Server
#  Run as Administrator in PowerShell
# ============================================================

# Script configuration
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

# VMware clipboard fix (detect if we're in a VM)
$isVmware = $false
try {
    $vmwareVersion = (Get-ItemProperty "HKLM:\SOFTWARE\VMware, Inc.\VMware Tools" -ErrorAction SilentlyContinue).ToolsVersion
    if ($vmwareVersion) { $isVmware = $true }
} catch {}

if ($isVmware) {
    Write-Host "     Detected VMware environment" -ForegroundColor Green
    $vmClipboard = Get-Service -Name "VMwareClipboard" -ErrorAction SilentlyContinue
    if ($vmClipboard) {
        if (-not $WhatIf) { Restart-Service -Name "VMwareClipboard" -Force }
        Set-Service -Name "VMwareClipboard" -StartupType Automatic
        Write-Host "     VMware Clipboard service restarted." -ForegroundColor Green
    } else {
        Write-Host "     VMware Clipboard service not found — reinstall VMware Tools." -ForegroundColor Yellow
    }
    $vmTools = Get-Service -Name "VMTools" -ErrorAction SilentlyContinue
    if ($vmTools) {
        if (-not $WhatIf) { Restart-Service -Name "VMTools" -Force }
        Write-Host "     VMware Tools service restarted." -ForegroundColor Green
    }
    reg add "HKLM\SOFTWARE\VMware, Inc.\VMware Tools" /v "EnableCopyPaste" /t REG_DWORD /d 1 /f | Out-Null
} else {
    Write-Host "     Not a VMware environment — skipping VMware-specific clipboard fix." -ForegroundColor Gray
}

Write-Host ""

# ── WINDOWS EDITION-AWARE BLOATWARE LISTS ────────────────────
Write-Host "[3/9] Loading bloatware lists for $WindowsEdition edition..." -ForegroundColor Yellow

# Define apps by architecture and edition
$appsX64 = @(
    "Microsoft.BingNews",
    "Microsoft.BingWeather",
    "Microsoft.BingFinance",
    "Microsoft.BingSports",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.People",
    "Microsoft.PowerAutomateDesktop",
    "Microsoft.Teams",
    "Microsoft.Todos",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
    "Microsoft.WindowsSoundRecorder",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxApp",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.YourPhone",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo",
    "MicrosoftTeams",
    "Clipchamp.Clipchamp",
    "Microsoft.GamingApp",
    "Microsoft.MixedReality.Portal",
    "Microsoft.SkypeApp",
    "Microsoft.windowscommunicationsapps",
    "Microsoft.WindowsAlarms",
    "Microsoft.549981C3F5F10"   # Cortana
)

$appsARM64 = @(
    "Microsoft.BingNews",
    "Microsoft.BingWeather",
    "Microsoft.BingFinance",
    "Microsoft.BingSports",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.People",
    "Microsoft.PowerAutomateDesktop",
    "Microsoft.Teams",
    "Microsoft.Todos",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
    "Microsoft.WindowsSoundRecorder",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxApp",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.YourPhone",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo",
    "MicrosoftTeams",
    "Clipchamp.Clipchamp",
    "Microsoft.GamingApp",
    "Microsoft.MixedReality.Portal",
    "Microsoft.SkypeApp",
    "Microsoft.windowscommunicationsapps",
    "Microsoft.WindowsAlarms",
    "Microsoft.549981C3F5F10",   # Cortana
    "Microsoft.Bard",              # Only on ARM64
    "Microsoft.CloudClip"          # Only on ARM64
)

# Edition-specific additional bloat
$editionSpecificApps = @()
switch ($WindowsEdition) {
    'Home' {
        # Home edition has more pre-installed apps
        $editionSpecificApps = @(
            "Microsoft.BingFinance",
            "Microsoft.BingSports",
            "Microsoft.MicrosoftSolitaireCollection",
            "Microsoft.MicrosoftOfficeHub"
        )
    }
    'Pro' {
        $editionSpecificApps = @(
            "Microsoft.BingFinance",
            "Microsoft.BingSports",
            "Microsoft.MicrosoftSolitaireCollection"
        )
    }
    'Enterprise' {
        # Enterprise has least bloat, focus on optional features
        $editionSpecificApps = @()
    }
    'Education' {
        $editionSpecificApps = @(
            "Microsoft.BingFinance",
            "Microsoft.BingSports"
        )
    }
    'Server' {
        $editionSpecificApps = @(
            "Microsoft.BingNews",
            "Microsoft.BingWeather",
            "Microsoft.GetHelp",
            "Microsoft.Getstarted",
            "Microsoft.People",
            "Microsoft.WindowsFeedbackHub",
            "Microsoft.WindowsMaps",
            "Microsoft.WindowsSoundRecorder",
            "Microsoft.Xbox.TCUI",
            "Microsoft.XboxApp",
            "Microsoft.XboxGameOverlay",
            "Microsoft.XboxGamingOverlay",
            "Microsoft.XboxIdentityProvider",
            "Microsoft.XboxSpeechToTextOverlay",
            "Microsoft.YourPhone",
            "Microsoft.ZuneMusic",
            "Microsoft.ZuneVideo",
            "MicrosoftTeams",
            "Clipchamp.Clipchamp",
            "Microsoft.SkypeApp",
            "Microsoft.windowscommunicationsapps",
            "Microsoft.WindowsAlarms",
            "Microsoft.549981C3F5F10"
        )
    }
    default { }
}

# Combine all apps to consider
$allX64Apps = @($appsX64, $editionSpecificApps)[$WindowsEdition -ne 'Enterprise']
$allARM64Apps = @($appsARM64, $editionSpecificApps)[$WindowsEdition -ne 'Enterprise']

Write-Host "     Architecture-specific bloat apps for $architecture:" -ForegroundColor Cyan

# ── ASK USER WHICH APPS TO REMOVE ───────────────────────────
Write-Host "" -ForegroundColor Yellow
Write-Host "[4/9] Select applications to remove..." -ForegroundColor Yellow

$selectedApps = @()

# Ask about system apps first
Write-Host "   The following system apps will be asked for removal:" -ForegroundColor Cyan
Write-Host "   • Microsoft Edge" -ForegroundColor Gray
Write-Host "   • Microsoft Copilot" -ForegroundColor Gray
Write-Host ""

$removeEdge = Read-Host "   Remove Microsoft Edge? (y/n)" -DefaultValue 'n'
if ($removeEdge -match '[Yy]') {
    $selectedApps += "Microsoft.Edge"
    if (-not $WhatIf) { Write-Host "     ✓ Selected: Microsoft Edge" -ForegroundColor Green }
    else { Write-Host "     [WhatIf] Would select: Microsoft Edge" -ForegroundColor DarkGray }
}

$removeCopilot = Read-Host "   Remove Microsoft Copilot? (y/n)" -DefaultValue 'n'
if ($removeCopilot -match '[Yy]') {
    $selectedApps += "Microsoft.Copilot"
    if (-not $WhatIf) { Write-Host "     ✓ Selected: Microsoft Copilot" -ForegroundColor Green }
    else { Write-Host "     [WhatIf] Would select: Microsoft Copilot" -ForegroundColor DarkGray }
}

# Select apps based on architecture
Write-Host "" -ForegroundColor Yellow
Write-Host "   Architecture-specific bloat apps for $architecture:" -ForegroundColor Cyan

$appsToRemove = if ($isARM64) { $allARM64Apps } else { $allX64Apps }

foreach ($app in $appsToRemove) {
    $displayName = ($app -replace '^Microsoft\.', 'Microsoft ')
    $check = Read-Host "   Remove $displayName? (y/n)" -DefaultValue 'n'
    if ($check -match '[Yy]') {
        $selectedApps += $app
        if (-not $WhatIf) { Write-Host "     ✓ Selected: $app" -ForegroundColor Green }
        else { Write-Host "     [WhatIf] Would select: $app" -ForegroundColor DarkGray }
    }
}

Write-Host "" -ForegroundColor Yellow
Write-Host "   Selected $($selectedApps.Count) apps for removal." -ForegroundColor Green
Write-Host ""

# ── REMOVE BLOAT APPS ───────────────────────────────────────
Write-Host "[5/9] Removing selected bloat apps..." -ForegroundColor Yellow

foreach ($app in $selectedApps) {
    $pkg = Get-AppxPackage -Name $app -ErrorAction SilentlyContinue
    if ($pkg) {
        if (-not $WhatIf) { Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction SilentlyContinue }
        Write-Host "     Removed: $app" -ForegroundColor Green
    }
    if (-not $WhatIf) {
        Get-AppxProvisionedPackage -Online |
            Where-Object DisplayName -eq $app |
            Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
        Write-Host "     Unprovisioned: $app" -ForegroundColor Green
    } else {
        Write-Host "     [WhatIf] Would unprovision: $app" -ForegroundColor DarkGray
    }
}

Write-Host ""

# ── DISABLE TELEMETRY ────────────────────────────────────────
Write-Host "[6/9] Disabling telemetry & tracking..." -ForegroundColor Yellow

# Telemetry disabling works on both Windows 10 and 11
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection"   /v AllowTelemetry        /t REG_DWORD /d 0 /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search"   /v AllowCortana           /t REG_DWORD /d 0 /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System"           /v EnableActivityFeed     /t REG_DWORD /d 0 /f | Out-Null
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled           /t REG_DWORD /d 0 /f | Out-Null
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f | Out-Null
reg add "HKCU\SOFTWARE\Microsoft\Personalization\Settings"          /v AcceptedPrivacyPolicy  /t REG_DWORD /d 0 /f | Out-Null
reg add "HKCU\SOFTWARE\Microsoft\InputPersonalization"              /v RestrictImplicitInkCollection /t REG_DWORD /d 1 /f | Out-Null
reg add "HKCU\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" /v HarvestContacts   /t REG_DWORD /d 0 /f | Out-Null

Write-Host "     Telemetry disabled." -ForegroundColor Green
Write-Host ""

# ── DISABLE USELESS SERVICES ─────────────────────────────────
Write-Host "[7/9] Disabling unnecessary services..." -ForegroundColor Yellow

# Services to disable - conditional based on edition
$services = @(
    @{ Name = "DiagTrack";         Desc = "Telemetry" },
    @{ Name = "dmwappushservice";  Desc = "WAP Push" },
    @{ Name = "SysMain";           Desc = "Superfetch" },
    @{ Name = "WSearch";           Desc = "Windows Search" },
    @{ Name = "XblAuthManager";    Desc = "Xbox Auth" },
    @{ Name = "XblGameSave";       Desc = "Xbox Game Save" },
    @{ Name = "XboxNetApiSvc";     Desc = "Xbox Network" },
    @{ Name = "RetailDemo";        Desc = "Retail Demo" },
    @{ Name = "MapsBroker";        Desc = "Maps Broker" },
    @{ Name = "lfsvc";             Desc = "Geolocation" },
    @{ Name = "SharedAccess";      Desc = "Internet Sharing" },
    @{ Name = "wisvc";             Desc = "Windows Insider" },
    @{ Name = "WerSvc";            Desc = "Error Reporting" },
    @{ Name = "wercplsupport";     Desc = "Error Reporting Support" }
)

# Skip Xbox services on Server editions
if ($WindowsEdition -ne 'Server') {
    $services += @(
        @{ Name = "XboxGipSvc";      Desc = "Xbox Gip" },
        @{ Name = "XboxNetClt";      Desc = "Xbox Network Client" }
    )
}

foreach ($svc in $services) {
    $s = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
    if ($s) {
        if (-not $WhatIf) { Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue }
        if (-not $WhatIf) { Set-Service -Name $svc.Name -StartupType Disabled -ErrorAction SilentlyContinue }
        Write-Host "     Disabled: $($svc.Desc) ($($svc.Name))" -ForegroundColor Green
    }
}

Write-Host ""

# ── PERFORMANCE TWEAKS (VMWARE vs BARMETAL) ───────────────────
Write-Host "[8/9] Applying performance tweaks..." -ForegroundColor Yellow

# Power plan (works on both client and server where applicable)
try {
    if (-not $WhatIf) { powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e | Out-Null }
}
catch { Write-Host "     powercfg not available in this environment." -ForegroundColor Gray }

# Disable visual effects
if (-not $WhatIf) {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f | Out-Null
}
Write-Host "     Visual effects disabled." -ForegroundColor Gray

# Disable transparency
if (-not $WhatIf) {
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f | Out-Null
}
Write-Host "     Transparency disabled." -ForegroundColor Gray

# Disable animations
if (-not $WhatIf) {
    reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f | Out-Null
}
reg add "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9012038010000000 /f | Out-Null

# Disable Aero Peek
if (-not $WhatIf) {
    reg add "HKCU\Software\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 0 /f | Out-Null
}

# Faster shutdown
if (-not $WhatIf) {
    reg add "HKCU\Control Panel\Desktop" /v WaitToKillAppTimeout  /t REG_SZ /d 2000  /f | Out-Null
    reg add "HKLM\SYSTEM\CurrentControlSet\Control"               /v WaitToKillServiceTimeout /t REG_SZ /d 2000 /f | Out-Null
}

# Disable hibernation (saves disk space)
if (-not $WhatIf) { powercfg /hibernate off | Out-Null }

# Disable Windows Tips & suggestions
if (-not $WhatIf) {
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338389Enabled /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-353694Enabled /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-353696Enabled /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled       /t REG_DWORD /d 0 /f | Out-Null
}

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
    if (-not $WhatIf) {
        Disable-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue | Out-Null
    }
    Write-Host "     Disabled task: $task" -ForegroundColor Green
}

Write-Host ""

# ── DONE ─────────────────────────────────────────────────────
Write-Host "============================================" -ForegroundColor Cyan
if ($WhatIf) {
    Write-Host "  [WhatIf Mode] All operations would complete." -ForegroundColor Cyan
    Write-Host "  Press Ctrl+C to exit without changes." -ForegroundColor Gray
}
else {
    Write-Host "  All done! Rebooting in 10 seconds..." -ForegroundColor Cyan
    Write-Host "  Press Ctrl+C to cancel reboot." -ForegroundColor Gray
}
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

if (-not $WhatIf) {
    Start-Sleep -Seconds 10
    Restart-Computer -Force
}
else {
    Write-Host "     Exiting WhatIf mode. No changes were applied." -ForegroundColor DarkGray
    Write-Host "     Run without -WhatIf to apply changes." -ForegroundColor DarkGray
}