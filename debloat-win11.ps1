# ============================================================
#  Windows 11 ARM Debloat Script
#  For VMware Fusion on Apple Silicon
#  Run as Administrator in PowerShell
# ============================================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Windows 11 ARM Debloat & Optimize Script" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ── CLIPBOARD FIX (VMware Tools) ────────────────────────────
Write-Host "[1/7] Fixing VMware clipboard (copy-paste)..." -ForegroundColor Yellow

# Restart VMware clipboard service
$vmClipboard = Get-Service -Name "VMwareClipboard" -ErrorAction SilentlyContinue
if ($vmClipboard) {
    Restart-Service -Name "VMwareClipboard" -Force
    Set-Service  -Name "VMwareClipboard" -StartupType Automatic
    Write-Host "     VMware Clipboard service restarted." -ForegroundColor Green
} else {
    Write-Host "     VMware Clipboard service not found — reinstall VMware Tools." -ForegroundColor Red
}

# Restart VMware Tools service
$vmTools = Get-Service -Name "VMTools" -ErrorAction SilentlyContinue
if ($vmTools) {
    Restart-Service -Name "VMTools" -Force
    Write-Host "     VMware Tools service restarted." -ForegroundColor Green
}

# Enable clipboard via registry
reg add "HKLM\SOFTWARE\VMware, Inc.\VMware Tools" /v "EnableCopyPaste" /t REG_DWORD /d 1 /f | Out-Null

Write-Host ""

# ── REMOVE BLOAT APPS ───────────────────────────────────────
Write-Host "[2/7] Removing bloat apps..." -ForegroundColor Yellow

$apps = @(
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

foreach ($app in $apps) {
    $pkg = Get-AppxPackage -Name $app -ErrorAction SilentlyContinue
    if ($pkg) {
        Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction SilentlyContinue
        Write-Host "     Removed: $app" -ForegroundColor Green
    }
    Get-AppxProvisionedPackage -Online |
        Where-Object DisplayName -eq $app |
        Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
}

Write-Host ""

# ── DISABLE TELEMETRY ────────────────────────────────────────
Write-Host "[3/7] Disabling telemetry & tracking..." -ForegroundColor Yellow

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
Write-Host "[4/7] Disabling unnecessary services..." -ForegroundColor Yellow

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

foreach ($svc in $services) {
    $s = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
    if ($s) {
        Stop-Service    -Name $svc.Name -Force        -ErrorAction SilentlyContinue
        Set-Service     -Name $svc.Name -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "     Disabled: $($svc.Desc) ($($svc.Name))" -ForegroundColor Green
    }
}

Write-Host ""

# ── PERFORMANCE TWEAKS ───────────────────────────────────────
Write-Host "[5/7] Applying performance tweaks..." -ForegroundColor Yellow

# Power plan — Balanced (saves heat on M4 Air)
powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e | Out-Null

# Disable visual effects
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f | Out-Null

# Disable transparency
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f | Out-Null

# Disable animations
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f | Out-Null
reg add "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9012038010000000 /f | Out-Null

# Disable Aero Peek
reg add "HKCU\Software\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 0 /f | Out-Null

# Faster shutdown
reg add "HKCU\Control Panel\Desktop" /v WaitToKillAppTimeout  /t REG_SZ /d 2000  /f | Out-Null
reg add "HKLM\SYSTEM\CurrentControlSet\Control"               /v WaitToKillServiceTimeout /t REG_SZ /d 2000 /f | Out-Null

# Disable hibernation (saves disk space in VM)
powercfg /hibernate off | Out-Null

# Disable Windows Tips & suggestions
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338389Enabled /t REG_DWORD /d 0 /f | Out-Null
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-353694Enabled /t REG_DWORD /d 0 /f | Out-Null
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-353696Enabled /t REG_DWORD /d 0 /f | Out-Null
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled       /t REG_DWORD /d 0 /f | Out-Null

Write-Host "     Performance tweaks applied." -ForegroundColor Green
Write-Host ""

# ── DISABLE SCHEDULED TASKS ──────────────────────────────────
Write-Host "[6/7] Disabling telemetry scheduled tasks..." -ForegroundColor Yellow

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
    Disable-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue | Out-Null
    Write-Host "     Disabled task: $task" -ForegroundColor Green
}

Write-Host ""

# ── PAUSE WINDOWS UPDATE ─────────────────────────────────────
Write-Host "[7/7] Pausing Windows Update (35 days)..." -ForegroundColor Yellow

$pauseDate = (Get-Date).AddDays(35).ToString("yyyy-MM-ddTHH:mm:ssZ")
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v PauseUpdatesExpiryTime   /t REG_SZ /d $pauseDate /f | Out-Null
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v PauseFeatureUpdatesEndTime /t REG_SZ /d $pauseDate /f | Out-Null
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v PauseQualityUpdatesEndTime /t REG_SZ /d $pauseDate /f | Out-Null

# Stop Windows Update service temporarily
Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
Set-Service  -Name "wuauserv" -StartupType Manual -ErrorAction SilentlyContinue

Write-Host "     Windows Update paused." -ForegroundColor Green
Write-Host ""

# ── DONE ─────────────────────────────────────────────────────
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  All done! Rebooting in 10 seconds..." -ForegroundColor Cyan
Write-Host "  Press Ctrl+C to cancel reboot." -ForegroundColor Gray
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Start-Sleep -Seconds 10
Restart-Computer -Force
