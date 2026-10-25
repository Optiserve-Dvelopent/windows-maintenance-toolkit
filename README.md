# Windows Maintenance Toolkit

![GitHub Release](https://img.shields.io/github/v/release/Optiserve-Dvelopent/windows-maintenance-toolkit?display_name=release)
![PowerShell CI](https://github.com/Optiserve-Dvelopent/windows-maintenance-toolkit/actions/workflows/powershell.yml/badge.svg)
![Last Commit](https://img.shields.io/github/last-commit/Optiserve-Dvelopent/windows-maintenance-toolkit)

A lightweight PowerShell utility for routine Windows maintenance and cleanup. This project provides a menu-driven script that helps clean temporary files, clear cached data, repair system files, and apply a few common maintenance actions without relying on third-party optimizer software.

## What this project does

The script in `optimize.ps1` offers a simple interactive menu with these options:

- System information
- Clean temporary files and recycle bin
- Clear DNS cache
- Clean the Windows component store with DISM
- Run SFC to check system files
- Switch to the High Performance power plan
- Disable Game DVR background capture
- Enable Storage Sense
- Exit the tool

Each action is logged to `logs/maintenance.log`.

## Requirements

- Windows 10 or Windows 11
- PowerShell 5.1 or newer
- Administrator privileges

## Project structure

```text
    windows-maintenance-toolkit/
     ├── optimize.ps1
     ├── README.md
     ├── LICENSE
     ├── .gitignore
     └── logs/               (created on first run)
         └── maintenance.log
```

## Usage

Open PowerShell as Administrator and run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\optimize.ps1
```

You can also run it directly without changing your session policy:

```powershell
powershell.exe -ExecutionPolicy Bypass -File ".\optimize.ps1"
```

## Included maintenance tasks

### Temporary cleanup

Before removing files from common temp folders, shows the number of temporary
files found and the estimated space that will be recovered. Cleanup proceeds
only after confirmation; declining leaves the temp files, Recycle Bin, and DNS
cache unchanged.

### Recovery options

The recovery menu can create a Windows restore point, return to the Balanced
power plan, re-enable Game DVR, or disable Storage Sense.
### SMART drive health

Shows each detected physical drive's Windows health and operational status, plus
SMART failure-prediction state when the device and its driver make that data
available. This check is read-only.
### DNS cache reset

Uses:

```powershell
Clear-DnsClientCache
```

### Component store cleanup

Runs:

```powershell
DISM.exe /Online /Cleanup-Image /StartComponentCleanup
```

### System file validation

Runs:

```powershell
sfc.exe /scannow
```

### Power plan

Attempts to enable the High Performance power scheme using:

```powershell
powercfg /setactive SCHEME_MAX
```

### Game DVR

Disables Game DVR capture settings in the current user profile.

### Storage Sense

Enables Windows Storage Sense if supported by the system.

## Safety notes

This tool is intentionally conservative and does not install third-party software or disable vital Windows protections. However, changing power settings, clearing caches, and cleaning system components can still affect system behavior. Review the script before running it on important or production systems.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Notes

- The script creates the `logs` directory automatically if it does not exist.
- Actions are written to a log file for troubleshooting and review.
- The interface is menu-based and designed for interactive local maintenance tasks.

![Repo Size](https://img.shields.io/github/repo-size/Optiserve-Dvelopent/windows-maintenance-toolkit)
