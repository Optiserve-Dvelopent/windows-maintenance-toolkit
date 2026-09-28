# Windows Maintenance Toolkit

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

Removes files from common temp folders and empties the Recycle Bin.

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
