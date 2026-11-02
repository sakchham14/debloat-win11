# Universal Windows Debloat Script - Complete Guide

## Overview

The `debloat.ps1` script is now **universal** for Windows 10/11, supporting:
- ✅ **All Windows editions:** Home, Pro, Enterprise, Education, Server
- ✅ **All architectures:** x64, ARM64
- ✅ **All platforms:** Client, Server, VMware, baremetal
- ✅ **Safe mode:** WhatIf functionality for previewing changes

---

## Features

### 1. Edition-Aware Bloatware Lists
Different Windows editions have different pre-installed apps:

| Edition | Bloatware Behavior |
|---------|-------------------|
| **Home** | Maximum pre-installed apps (focus on Office/News/Weather apps) |
| **Pro/Enterprise** | Moderate bloat (remove extra news/sports apps) |
| **Education** | Moderate bloat |
| **Server** | Remove ALL non-essential apps (edge, copilot, news, games) |

### 2. Architecture Detection
Automatically detects and adjusts for:
- **x64** Standard Windows
- **ARM64** Windows on ARM
- **VMware** hypervisor optimizations (clipboard, hypervisor service tweaks)

### 3. Safe Operations
- **WhatIf mode** (`-WhatIf`) - Preview all changes without applying
- **Error handling** - Script continues even if individual items fail
- **Service handling** - Safely disables services without crashing

### 4. Performance Optimizations
Universal for Windows 10/11 and variants:
- Disable telemetry & tracking
- Optimize power settings
- Disable unnecessary services
- Remove startup programs
- Disable hibernation (saves disk space)
- Smooth animations and transitions
- Transparency and visual effects

---

## Quick Start

### Minimum Required Permissions
- **Administrator rights**
- Access to run PowerShell scripts

### Basic Usage

```powershell
# Run as Administrator in PowerShell
.\debloat.ps1
```

### Recommended Edition-Specific Usage

```powershell
# Home edition (most basic install)
.\debloat.ps1 -WindowsEdition Home

# Pro/W10/11 Pro
.\debloat.ps1 -WindowsEdition Pro

# Enterprise/W10/11 Enterprise
.\debloat.ps1 -WindowsEdition Enterprise

# Server 2019/2022
.\debloat.ps1 -WindowsEdition Server

# ARM64 Windows on ARM
.\debloat.ps1 -WindowsEdition Home
```

---

## Advanced Options

### WhatIf Mode (Preview)

```powershell
# Preview all changes without applying
.\debloat.ps1 -WhatIf

# Preview with verbose logging
.\debloat.ps1 -WhatIf -VerboseLogging
```

### Edition Selection

```powershell
# Select specific edition
.\debloat.ps1 -WindowsEdition "Pro"

# Use specific edition with WhatIf
.\debloat.ps1 -WindowsEdition "Enterprise" -WhatIf
```

### Verbose Logging

```powershell
# Enable detailed logging
.\debloat.ps1 -VerboseLogging
```

---

## Customization

### 1. Configuration File (JSON)

Edit `debloat-config.json`:

```json
{
  "DefaultEdition": "Pro",
  "DisableTelemetry": true,
  "DisableServices": {
    "DiagTrack": true,
    "WSearch": false
  },
  "AppsToAlwaysRemove": [
    "Microsoft.Edge",
    "Microsoft.Copilot"
  ],
  "PerformanceTweaks": {
    "DisableStartup": true,
    "DisableHibernation": true,
    "DisableTips": true
  }
}
```

### 2. Command-Line Override

```powershell
# Override config file with command line
.\debloat.ps1 -WindowsEdition "Enterprise" -WhatIf
```

---

## Output Explanation

### Scripts Print Colors

| Color | Meaning |
|-------|---------|
| 🔵 Yellow `[1/9]` | Phase start |
| 🟢 Green ✓ | Successfully completed |
| ⚫ Gray (opt) | Optional/cached operation |
| 🔴 Yellow (!) | Warning/notice |

### Success Messages

```
[3/9] Loading bloatware lists for Pro edition...
     Architecture-specific bloat apps for x64:
     [4/9] Select applications to remove...
   Selected 15 apps for removal.

[5/9] Removing selected bloat apps...
     Removed: Microsoft.Edge
     Removed: Microsoft.Copilot
     Removed: Microsoft.BingNews
     ...

[9/9] Disabling telemetry scheduled tasks...
     Disabled task: \Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser
     ...
```

### WhatIf Output

```
[3/9] Loading bloatware lists for Pro edition...
     Architecture-specific bloat apps for x64:
     [4/9] Select applications to remove...
   [WhatIf] Would select: Microsoft.Edge
   [WhatIf] Would select: Microsoft.Copilot
     [WhatIf] Would remove: Microsoft.Edge
     [WhatIf] Would unprovision: Microsoft.Edge

[9/9] Disabling telemetry scheduled tasks...
     [WhatIf] Would disable task: \Microsoft\Windows\...
```

---

## Troubleshooting

### Issue: "Run as Administrator" Required
**Solution:** Right-click PowerShell and select "Run as Administrator"

### Issue: "Script cannot be loaded because running scripts is disabled"
**Solution:**
```powershell
# Enable script execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Issue: Services won't disable
**Reason:** Required for Windows Server 2019+/Windows 11 Pro
**Solution:** Remove from `$services` array in script (adjust search column to `DisplayName`)

### Issue: powercfg not available
**Reason:** Running in container/VM without power features
**Solution:** Ok! Script continues without hibernation disable

### Issue: Some apps not found
**Reason:** App may not be installed on your edition/architecture
**Solution:** That's okay! Script continues silently (ErrorAction SilentlyContinue)

---

## What Gets Removed

### Always Removed (All Editions)
- Microsoft Edge (optional)
- Microsoft Copilot (optional)
- Xbox Services (optional, Server only)
- All telemetry services
- All telemetry scheduled tasks
- Startup applications

### Removed by Edition

| Edition | Comments |
|---------|----------|
| **Home** | Office Hub, News, Weather, Sports, Finance, People, Todos, Edge, Copilot, Games, Bard |
| **Pro** | Office Hub, News, Weather, Sports, Finance, Edge, Copilot, Games |
| **Enterprise** | Optional extra apps, Terminal, XPS Viewer |
| **Server** | ALL client apps (Edge, Copilot, News, Weather, Maps, Games, Cortana, Bard, CloudClip) |

### Optional/Configuration-Based Removals
- Services (configurable)
- Scheduled tasks (configurable)
- Performance tweaks (configurable)

---

## Reverting Changes

### If you need to keep Edge or Copilot:
1. Run script **without** selecting those apps
2. Restore services via Services.msc
3. Re-enable telemetry via `AllowTelemetry` registry key

### Restore hibernation:
```powershell
powercfg /hibernate on
```

### Restore services:
```powershell
# Using Services.msc or:
Get-Service DiagTrack | Set-Service -StartupType Automatic
Get-Service SysMain | Set-Service -StartupType Automatic
```

---

## Performance Impact

### Disk Space Saved
- Hibernation file removal: ~3-6 GB on typical systems
- App package removal: ~500 MB - 2 GB depending on selection

### System Performance Gains
- ⚡ Reduced startup time
- ⚡ Reduced background processes
- ⚡ Lower memory usage
- ⚡ Faster shutdown
- ⚡ Fewer notifications
- ⚺ Reduced startup programs

---

## Testing Recommendations

### 1. Test First in VM
```powershell
# Run in VMware/Parallels preview before production
.\debloat.ps1 -WhatIf
```

### 2. Test Small First
```powershell
# Select minimal apps first
# Focus on Edge/Copilot (non-essential)
```

### 3. Review Before Reboot
```powershell
# Run with -WhatIf twice
# Check list of removed services
# Verify edition-specific selections
```

---

## Known Limitations

1. **Windows Server 2022**: Future-proof for Server 2025
2. **Windows 10 vs 11**: Identical for debloat, UI differences handled
3. **Non-MS apps**: Does not affect third-party applications
4. **Update behavior**: Optimizes update quality; script may not contain all patches

---

## Contributing to the Script

### Adding New Apps

Edit `$appsX64` or `$appsARM64` arrays:

```powershell
$appsX64 = @(
    "Your.App.Package.Name",
    "Another.App.Name"
)
```

### Adding Services

Edit `$services` array:

```powershell
$services += @(
    @{ Name = "YourService"; Desc = "Description of service" }
)
```

### Adding Tasks

Edit `$tasks` array:

```powershell
$tasks += "\Microsoft\Windows\Your\TaskName"
```

---

## License

MIT License - Feel free to modify and distribute

### Credit

- Architecture detection and interactive prompts based on existing open-source debloat scripts
- Edition-aware logic inspired by community debloat projects
- All code is original or derived from MIT-licensed sources

---

## Support

For issues or questions:
1. Check this README first
2. Use WhatIf mode to debug
3. Review individual step logs
4. Test in VM before production

---

## Summary Checklist

- [ ] Run as Administrator
- [ ] Enable script execution policy
- [ ] Test with `-WhatIf` first
- [ ] Select apps you want to remove
- [ ] Review edition-specific selections
- [ ] Test in VM before production
- [ ] Reboot after completion
- [ ] Test system stability
- [ ] Bookmark for future reference

---

**Happy Debloating! 🚀**

*This script optimizes your Windows experience without breaking system functionality.*