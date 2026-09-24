# Windows Maintenance Toolkit

A PowerShell toolkit for optimizing, cleaning, and maintaining Windows 11 systems.

The **Windows Maintenance Toolkit** provides a collection of practical system maintenance and performance optimization tasks without relying on third-party "PC booster" software.

## Features

- Clean temporary files
- Clear DNS cache
- Clean Windows component store
- Check and repair Windows system files
- Configure Windows power settings
- Disable unnecessary background game recording
- Enable Windows Storage Sense
- Display system information
- Display configured startup applications
- Run common maintenance tasks from a single PowerShell script

## Requirements

- Windows 11
- PowerShell 5.1 or newer
- Administrator privileges

## Installation

Clone the repository:

```powershell
git clone https://github.com/Optiserve-Dvelopent/windows-maintenance-toolkit.git
```

Enter the repository:

```powershell
cd windows-maintenance-toolkit
```

## Usage

Open **PowerShell as Administrator**.

Temporarily allow script execution for the current PowerShell session:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

Run the toolkit:

```powershell
.\optimize.ps1
```

Alternatively:

```powershell
powershell.exe -ExecutionPolicy Bypass -File ".\optimize.ps1"
```

## What It Does

### Temporary File Cleanup

Removes unnecessary files from common Windows temporary directories.

### DNS Cache Cleanup

Clears the Windows DNS client cache:

```powershell
Clear-DnsClientCache
```

### Windows Component Cleanup

Uses Microsoft's DISM tool to clean up obsolete Windows components:

```powershell
DISM.exe /Online /Cleanup-Image /StartComponentCleanup
```

### System File Check

Runs Windows System File Checker:

```powershell
sfc.exe /scannow
```

SFC checks Windows system files for corruption and attempts to repair detected problems.

### Power Plan

The toolkit attempts to activate the Windows **High Performance** power plan when available.

### Game DVR

Disables Windows background game recording to reduce unnecessary background activity.

### Storage Sense

Enables Windows Storage Sense where supported.

### Startup Applications

Displays applications configured to start automatically with Windows, allowing unnecessary startup programs to be identified.

## Safety

The toolkit is designed to avoid aggressive system modifications.

It does **not**:

- Disable essential Windows services
- Delete personal files
- Disable Windows Defender
- Disable Windows Update
- Install third-party software
- Apply undocumented collections of registry tweaks

System configuration changes can still have unintended effects. Review the script before running it on important systems.

## Project Structure

```text
windows-maintenance-toolkit/
├── optimize.ps1
├── README.md
├── LICENSE
└── .gitignore
```

## Contributing

Contributions, improvements, bug reports, and feature requests are welcome.

When contributing:

1. Keep the toolkit compatible with Windows 11.
2. Avoid unnecessary registry modifications.
3. Do not disable essential Windows security features.
4. Document significant system changes.
5. Test changes before submitting a pull request.

## Disclaimer

This project is provided **as-is**, without warranty.

The authors are not responsible for data loss, system instability, hardware damage, or other issues resulting from the use or modification of this software.

Review the source code and understand what it does before executing it.

## License

This project is licensed under the **MIT License**.

See the [`LICENSE`](LICENSE) file for details.

## Author

**Optiserve Development**

GitHub: [Optiserve-Dvelopent](https://github.com/Optiserve-Dvelopent)
