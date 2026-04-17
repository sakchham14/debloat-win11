# Windows 11 ARM Debloat Script

A PowerShell script to remove bloatware, disable telemetry, and optimize Windows 11 ARM for VMware Fusion on Apple Silicon Macs.

---

## What It Does

- Removes 30+ pre-installed bloat apps (Xbox, Teams, Cortana, etc.)
- Disables telemetry and Microsoft tracking
- Disables unnecessary background services
- Applies performance tweaks (no animations, faster shutdown)
- Fixes VMware clipboard so you can copy-paste between Mac and VM
- Pauses Windows Update for 35 days

---

## How to Run

Open **PowerShell as Administrator** inside the Windows VM and run:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
irm "https://raw.githubusercontent.com/sakchham14/debloat-win11/main/debloat-win11.ps1" | iex
```

The script will run automatically and reboot when done.

---

## Requirements

- Windows 11 ARM64
- PowerShell (run as Administrator)
- Internet connection inside the VM

---

## Notes

- This script is intended for use inside a VMware Fusion virtual machine on Apple Silicon (M1/M2/M3/M4)
- It will **automatically reboot** your VM after finishing
- Press `Ctrl+C` before the 10 second countdown if you want to cancel the reboot
