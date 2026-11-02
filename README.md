# Windows Debloat Script

**One-click Windows optimization script for 10/11/Server**

---

## What It Does

- **Auto-detects** your Windows edition (Home/Pro/Enterprise/Server)
- **Removes bloat apps** (Xbox, Teams, Cortana, Edge, Copilot)
- **Disables telemetry** and tracking
- **Optimizes performance** (faster shutdown, no animations)
- **Fixes clipboard** for VMware users
- **Works on x64 & ARM64** (including Apple Silicon)

---

## How to Run

### Option 1: Download & Run (Easiest)
```powershell
# In PowerShell as Administrator:
Set-ExecutionPolicy Bypass -Scope Process -Force
irm "https://raw.githubusercontent.com/sakchham14/debloat-win11/main/debloat.ps1" | iex
```

### Option 2: Local File
```powershell
# If you saved the script locally:
.\debloat.ps1
```

### Option 3: Preview Mode (Safe)
```powershell
# See what it would do without actually doing it:
.\debloat.ps1 -WhatIf
```

---

## Advanced Options

| Parameter | Description | Example |
|-----------|-------------|---------|
| `-WhatIf` | Preview changes without applying | `.\debloat.ps1 -WhatIf` |
| `-VerboseLogging` | Show detailed output | `.\debloat.ps1 -VerboseLogging` |
| `-WindowsEdition` | Specify edition (auto-detected) | `.\debloat.ps1 -WindowsEdition Enterprise` |

---

## Supported Systems

| System | Editions | Architecture |
|--------|----------|-------------|
| Windows 11 | Home, Pro, Enterprise, Education | x64, ARM64 |
| Windows 10 | Home, Pro, Enterprise, Education | x64, ARM64 |
| Windows Server 2019+ | Server | x64, ARM64 |

---

## Notes

- **Auto-reboot** - The script reboots automatically after 10 seconds
- **Ctrl+C** - Press to cancel reboot if needed
- **WhatIf mode** - Always test with `-WhatIf` first
- **VMware users** - Clipboard copy-paste will work better
- **Server editions** - Xbox services are skipped automatically