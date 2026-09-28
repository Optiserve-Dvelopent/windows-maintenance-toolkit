[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingWriteHost',
    '',
    Justification = 'Interactive console script uses Write-Host for colored status output.'
)]
param()

# ============================================================
# Windows Maintenance Toolkit v1.1
# ============================================================

# ============================================================
# Logging
# ============================================================

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDirectory = Join-Path $scriptRoot "logs"
$logFile = Join-Path $logDirectory "maintenance.log"

if (-not (Test-Path $logDirectory)) {
    New-Item `
        -Path $logDirectory `
        -ItemType Directory `
        -Force |
    Out-Null
}

function Write-AppLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] [$Level] $Message"

    try {
        Add-Content `
            -Path $logFile `
            -Value $entry `
            -ErrorAction Stop
    }
    catch {
        Write-Verbose "Logging fehlgeschlagen: $($_.Exception.Message)"
    }
}

# ============================================================
# Administratorprüfung
# ============================================================

$isAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $isAdmin) {

    Write-Host ""
    Write-Host `
        "Bitte PowerShell als Administrator starten." `
        -ForegroundColor Red
    Write-Host ""

    exit 1
}

Write-AppLog `
    "Windows Maintenance Toolkit gestartet." `
    "INFO"

# ============================================================
# Header
# ============================================================

Clear-Host

Write-Host ""
Write-Host `
    "========================================" `
    -ForegroundColor Cyan

Write-Host `
    " Windows Maintenance Toolkit v1.1" `
    -ForegroundColor Cyan

Write-Host `
    "========================================" `
    -ForegroundColor Cyan

Write-Host ""

# ============================================================
# 1. Systeminformationen
# ============================================================

function Show-SystemInfo {

    Clear-Host

    Write-Host `
        "========================================" `
        -ForegroundColor Cyan

    Write-Host `
        " Systeminformationen" `
        -ForegroundColor Cyan

    Write-Host `
        "========================================" `
        -ForegroundColor Cyan

    Write-Host ""

    Write-AppLog `
        "Systeminformationen werden abgerufen."

    try {

        $os = Get-CimInstance Win32_OperatingSystem

        $cpu = Get-CimInstance Win32_Processor |
        Select-Object -First 1

        $ram = [math]::Round(
            $os.TotalVisibleMemorySize / 1MB,
            1
        )

        $disk = Get-CimInstance Win32_LogicalDisk `
            -Filter "DeviceID='C:'"

        Write-Host "Windows: $($os.Caption)"
        Write-Host "CPU:     $($cpu.Name)"
        Write-Host "RAM:     $ram GB"

        Write-AppLog `
            "Windows: $($os.Caption)"

        Write-AppLog `
            "CPU: $($cpu.Name)"

        Write-AppLog `
            "RAM: $ram GB"

        if ($disk) {

            $freeSpace = [math]::Round(
                $disk.FreeSpace / 1GB,
                1
            )

            $totalSpace = [math]::Round(
                $disk.Size / 1GB,
                1
            )

            Write-Host `
                "Storage: $freeSpace GB frei / $totalSpace GB"

            Write-AppLog `
                "Storage: $freeSpace GB frei / $totalSpace GB"
        }
        else {

            Write-Host `
                "Storage: C: konnte nicht ermittelt werden." `
                -ForegroundColor DarkYellow

            Write-AppLog `
                "C: Speicher konnte nicht ermittelt werden." `
                "WARNING"
        }

        Write-Host ""

        Write-Host `
            "Systeminformationen erfolgreich abgerufen." `
            -ForegroundColor Green

        Write-AppLog `
            "Systeminformationen erfolgreich abgerufen." `
            "SUCCESS"
    }
    catch {

        Write-Host ""

        Write-Host `
            "Fehler beim Abrufen der Systeminformationen." `
            -ForegroundColor Red

        Write-AppLog `
            "Fehler bei Systeminformationen: $($_.Exception.Message)" `
            "ERROR"
    }

    Write-Host ""
    Read-Host "Enter drücken"
}

# ============================================================
# 2. Clean Up
# ============================================================

function Invoke-Cleanup {

    Clear-Host

    Write-Host `
        "========================================" `
        -ForegroundColor Cyan

    Write-Host `
        " Clean Up" `
        -ForegroundColor Cyan

    Write-Host `
        "========================================" `
        -ForegroundColor Cyan

    Write-Host ""

    Write-AppLog "Cleanup gestartet."

    $tempPaths = @(
        $env:TEMP,
        "$env:WINDIR\Temp"
    )

    foreach ($path in $tempPaths) {

        if (-not (Test-Path $path)) {

            Write-AppLog `
                "Temp-Pfad nicht gefunden: $path" `
                "WARNING"

            continue
        }

        Write-Host `
            "Bereinige: $path" `
            -ForegroundColor Yellow

        Write-AppLog `
            "Bereinige: $path"

        $items = Get-ChildItem `
            -Path $path `
            -Force `
            -ErrorAction SilentlyContinue

        $removed = 0
        $failed = 0

        foreach ($item in $items) {

            try {

                Remove-Item `
                    -Path $item.FullName `
                    -Recurse `
                    -Force `
                    -ErrorAction Stop

                $removed++
            }
            catch {

                $failed++

                Write-AppLog `
                    "Datei konnte nicht entfernt werden: $($item.FullName)" `
                    "WARNING"
            }
        }

        Write-Host `
            "Entfernt: $removed" `
            -ForegroundColor Green

        Write-AppLog `
            "Entfernt aus $path : $removed Dateien."

        if ($failed -gt 0) {

            Write-Host `
                "Übersprungen: $failed" `
                -ForegroundColor DarkYellow

            Write-AppLog `
                "Übersprungen: $failed Dateien." `
                "WARNING"
        }

        Write-Host ""
    }

    # --------------------------------------------------------
    # Papierkorb
    # --------------------------------------------------------

    Write-Host `
        "Leere Papierkorb..." `
        -ForegroundColor Yellow

    Write-AppLog `
        "Papierkorb wird geleert."

    try {

        Clear-RecycleBin `
            -Force `
            -ErrorAction Stop

        Write-Host `
            "Papierkorb geleert." `
            -ForegroundColor Green

        Write-AppLog `
            "Papierkorb erfolgreich geleert." `
            "SUCCESS"
    }
    catch {

        Write-Host `
            "Papierkorb konnte nicht geleert werden." `
            -ForegroundColor DarkYellow

        Write-AppLog `
            "Papierkorb konnte nicht geleert werden." `
            "WARNING"
    }

    # --------------------------------------------------------
    # DNS Cache
    # --------------------------------------------------------

    Write-Host ""

    Write-Host `
        "Leere DNS-Cache..." `
        -ForegroundColor Yellow

    Write-AppLog `
        "DNS-Cache wird geleert."

    try {

        Clear-DnsClientCache `
            -ErrorAction Stop

        Write-Host `
            "DNS-Cache geleert." `
            -ForegroundColor Green

        Write-AppLog `
            "DNS-Cache erfolgreich geleert." `
            "SUCCESS"
    }
    catch {

        Write-Host `
            "DNS-Cache konnte nicht geleert werden." `
            -ForegroundColor DarkYellow

        Write-AppLog `
            "DNS-Cache konnte nicht geleert werden." `
            "WARNING"
    }

    Write-Host ""

    Write-Host `
        "Cleanup abgeschlossen." `
        -ForegroundColor Green

    Write-AppLog `
        "Cleanup abgeschlossen." `
        "SUCCESS"

    Write-Host ""
    Read-Host "Enter drücken"
}

# ============================================================
# 3. DNS Cache
# ============================================================

function Clear-DNSCache {

    Clear-Host

    Write-Host `
        "========================================" `
        -ForegroundColor Cyan

    Write-Host `
        " DNS Cache" `
        -ForegroundColor Cyan

    Write-Host `
        "========================================" `
        -ForegroundColor Cyan

    Write-Host ""

    Write-AppLog `
        "Manuelle DNS-Cache-Bereinigung gestartet."

    try {

        Clear-DnsClientCache `
            -ErrorAction Stop

        Write-Host `
            "DNS-Cache erfolgreich geleert." `
            -ForegroundColor Green

        Write-AppLog `
            "DNS-Cache erfolgreich geleert." `
            "SUCCESS"
    }
    catch {

        Write-Host `
            "DNS-Cache konnte nicht geleert werden." `
            -ForegroundColor Red

        Write-AppLog `
            "DNS-Cache konnte nicht geleert werden: $($_.Exception.Message)" `
            "ERROR"
    }

    Write-Host ""
    Read-Host "Enter drücken"
}

# ============================================================
# 4. Component Store
# ============================================================

function Invoke-ComponentCleanup {

    Clear-Host

    Write-Host `
        "========================================" `
        -ForegroundColor Cyan

    Write-Host `
        " Windows Component Store" `
        -ForegroundColor Cyan

    Write-Host `
        "========================================" `
        -ForegroundColor Cyan

    Write-Host ""

    Write-AppLog `
        "Component Store Bereinigung gestartet."

    Write-Host `
        "Komponentenbereinigung wird gestartet..." `
        -ForegroundColor Yellow

    DISM.exe `
        /Online `
        /Cleanup-Image `
        /StartComponentCleanup

    if ($LASTEXITCODE -eq 0) {

        Write-Host ""

        Write-Host `
            "Komponentenbereinigung abgeschlossen." `
            -ForegroundColor Green

        Write-AppLog `
            "Component Store erfolgreich bereinigt." `
            "SUCCESS"
    }
    else {

        Write-Host ""

        Write-Host `
            "DISM meldete einen Fehler. Exit Code: $LASTEXITCODE" `
            -ForegroundColor Red

        Write-AppLog `
            "DISM Fehler. Exit Code: $LASTEXITCODE" `
            "ERROR"
    }

    Write-Host ""
    Read-Host "Enter drücken"
}

# ============================================================
# 5. Systemdateien prüfen
# ============================================================

function Invoke-SystemRepair {

    Clear-Host

    Write-Host `
        "========================================" `
        -ForegroundColor Cyan

    Write-Host `
        " Systemdateien prüfen" `
        -ForegroundColor Cyan

    Write-Host `
        "========================================" `
        -ForegroundColor Cyan

    Write-Host ""

    Write-AppLog `
        "SFC Systemdateiprüfung gestartet."

    Write-Host `
        "SFC wird gestartet..." `
        -ForegroundColor Yellow

    Write-Host ""

    sfc.exe /scannow

    Write-Host ""

    if ($LASTEXITCODE -eq 0) {

        Write-Host `
            "Systemdateiprüfung abgeschlossen." `
            -ForegroundColor Green

        Write-AppLog `
            "SFC erfolgreich abgeschlossen." `
            "SUCCESS"
    }
    else {

        Write-Host `
            "SFC meldete einen Fehler oder ein Problem." `
            -ForegroundColor DarkYellow

        Write-AppLog `
            "SFC Exit Code: $LASTEXITCODE" `
            "WARNING"
    }

    Write-Host ""
    Read-Host "Enter drücken"
}

# ============================================================
# 6. Energieprofil
# ============================================================

function Set-HighPerformance {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'
    )]
    param()

    Clear-Host

    Write-Host `
        "========================================" `
        -ForegroundColor Cyan

    Write-Host `
        " Energieprofil" `
        -ForegroundColor Cyan

    Write-Host `
        "========================================" `
        -ForegroundColor Cyan

    Write-Host ""

    Write-AppLog `
        "Energieprofil Höchstleistung wird aktiviert."

    Write-Host `
        "Aktiviere Höchstleistung..." `
        -ForegroundColor Yellow

    if ($PSCmdlet.ShouldProcess(
            "Power scheme",
            "Activate High Performance"
        )) {

        powercfg /setactive SCHEME_MAX

        if ($LASTEXITCODE -eq 0) {

            Write-Host ""

            Write-Host `
                "Höchstleistung aktiviert." `
                -ForegroundColor Green

            Write-AppLog `
                "Höchstleistungsprofil aktiviert." `
                "SUCCESS"
        }
        else {

            Write-Host ""

            Write-Host `
                "Energieprofil konnte nicht aktiviert werden." `
                -ForegroundColor Red

            Write-AppLog `
                "Höchstleistungsprofil konnte nicht aktiviert werden." `
                "ERROR"
        }
    }

    Write-Host ""
    Read-Host "Enter drücken"
}

# ============================================================
# 7. Game DVR
# ============================================================

function Disable-GameDVR {

    Clear-Host

    Write-Host `
        "========================================" `
        -ForegroundColor Cyan

    Write-Host `
        " Hintergrundaufnahme" `
        -ForegroundColor Cyan

    Write-Host `
        "========================================" `
        -ForegroundColor Cyan

    Write-Host ""

    Write-AppLog `
        "Game DVR Deaktivierung gestartet."

    Write-Host `
        "Deaktiviere Hintergrundaufnahme..." `
        -ForegroundColor Yellow

    $gameConfig = `
        "HKCU:\System\GameConfigStore"

    if (-not (Test-Path $gameConfig)) {

        New-Item `
            -Path $gameConfig `
            -Force `
            -ErrorAction SilentlyContinue |
        Out-Null
    }

    Set-ItemProperty `
        -Path $gameConfig `
        -Name "GameDVR_Enabled" `
        -Type DWord `
        -Value 0 `
        -ErrorAction SilentlyContinue

    $gameDvr = `
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"

    if (-not (Test-Path $gameDvr)) {

        New-Item `
            -Path $gameDvr `
            -Force `
            -ErrorAction SilentlyContinue |
        Out-Null
    }

    Set-ItemProperty `
        -Path $gameDvr `
        -Name "AppCaptureEnabled" `
        -Type DWord `
        -Value 0 `
        -ErrorAction SilentlyContinue

    Write-Host ""

    Write-Host `
        "Hintergrundaufnahme deaktiviert." `
        -ForegroundColor Green

    Write-AppLog `
        "Game DVR erfolgreich deaktiviert." `
        "SUCCESS"

    Write-Host ""
    Read-Host "Enter drücken"
}

# ============================================================
# 8. Speicheroptimierung
# ============================================================

function Enable-StorageOptimization {

    Clear-Host

    Write-Host `
        "========================================" `
        -ForegroundColor Cyan

    Write-Host `
        " Speicheroptimierung" `
        -ForegroundColor Cyan

    Write-Host `
        "========================================" `
        -ForegroundColor Cyan

    Write-Host ""

    Write-AppLog `
        "Speicheroptimierung wird aktiviert."

    Write-Host `
        "Speicheroptimierung wird aktiviert..." `
        -ForegroundColor Yellow

    try {

        Enable-StorageSense `
            -ErrorAction Stop

        Write-Host ""

        Write-Host `
            "Speicheroptimierung aktiviert." `
            -ForegroundColor Green

        Write-AppLog `
            "Speicheroptimierung erfolgreich aktiviert." `
            "SUCCESS"
    }
    catch {

        Write-Host ""

        Write-Host `
            "Speicheroptimierung konnte nicht aktiviert werden." `
            -ForegroundColor DarkYellow

        Write-AppLog `
            "Speicheroptimierung fehlgeschlagen: $($_.Exception.Message)" `
            "WARNING"
    }

    Write-Host ""
    Read-Host "Enter drücken"
}

# ============================================================
# Hauptmenü
# ============================================================

do {

    Clear-Host

    Write-Host `
        "========================================" `
        -ForegroundColor Cyan

    Write-Host `
        " Windows Maintenance Toolkit v1.1" `
        -ForegroundColor Cyan

    Write-Host `
        "========================================" `
        -ForegroundColor Cyan

    Write-Host ""

    Write-Host "[1] Systeminformationen"
    Write-Host "[2] Clean Up"
    Write-Host "[3] DNS Cache"
    Write-Host "[4] Component Store"
    Write-Host "[5] Systemdateien prüfen"
    Write-Host "[6] Energieprofil"
    Write-Host "[7] Game DVR deaktivieren"
    Write-Host "[8] Speicheroptimierung"
    Write-Host "[0] Beenden"

    Write-Host ""

    $choice = Read-Host "Auswahl"

    Write-AppLog `
        "Menüauswahl: $choice"

    switch ($choice) {

        "1" {
            Show-SystemInfo
        }

        "2" {
            Invoke-Cleanup
        }

        "3" {
            Clear-DNSCache
        }

        "4" {
            Invoke-ComponentCleanup
        }

        "5" {
            Invoke-SystemRepair
        }

        "6" {
            Set-HighPerformance
        }

        "7" {
            Disable-GameDVR
        }

        "8" {
            Enable-StorageOptimization
        }

        "0" {

            Write-AppLog `
                "Windows Maintenance Toolkit beendet." `
                "SUCCESS"

            Clear-Host

            Write-Host ""

            Write-Host `
                "Windows Maintenance Toolkit beendet." `
                -ForegroundColor Cyan

            Write-Host ""
        }

        default {

            Write-Host ""

            Write-Host `
                "Ungültige Auswahl." `
                -ForegroundColor Red

            Write-AppLog `
                "Ungültige Menüauswahl: $choice" `
                "WARNING"

            Start-Sleep -Seconds 1
        }
    }

} while ($choice -ne "0")