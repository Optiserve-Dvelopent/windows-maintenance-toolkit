[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingWriteHost',
    '',
    Justification = 'Interactive console script uses Write-Host for colored status output.'
)]
param()

# ============================================================
# Windows Maintenance Toolkit
# ============================================================

# ------------------------------------------------------------
# Administratorprüfung
# ------------------------------------------------------------

$isAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host ""
    Write-Host "Bitte PowerShell als Administrator starten." -ForegroundColor Red
    Write-Host ""
    exit 1
}

# ------------------------------------------------------------
# Header
# ------------------------------------------------------------

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Windows Maintenance Toolkit" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# 1. Systeminformationen
# ------------------------------------------------------------

Write-Host "[1/8] Systeminformationen..." -ForegroundColor Yellow

$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$ram = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)

$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"

if ($disk) {
    $freeSpace = [math]::Round($disk.FreeSpace / 1GB, 1)
    $totalSpace = [math]::Round($disk.Size / 1GB, 1)
}

Write-Host "Windows: $($os.Caption)"
Write-Host "CPU:     $($cpu.Name)"
Write-Host "RAM:     $ram GB"

if ($disk) {
    Write-Host "Storage: $freeSpace GB frei / $totalSpace GB"
}
else {
    Write-Host "Storage: C: konnte nicht ermittelt werden." -ForegroundColor DarkYellow
}

Write-Host ""
Write-Host "Systeminformationen abgeschlossen." -ForegroundColor Green
Write-Host ""

# ------------------------------------------------------------
# 2. Temporäre Dateien
# ------------------------------------------------------------

Write-Host "[2/8] Temporäre Dateien bereinigen..." -ForegroundColor Yellow

$tempPaths = @(
    $env:TEMP,
    "$env:WINDIR\Temp"
)

foreach ($path in $tempPaths) {

    if (Test-Path $path) {

        Write-Host "Bereinige: $path" -ForegroundColor Gray

        $items = Get-ChildItem `
            -Path $path `
            -Force `
            -ErrorAction SilentlyContinue

        foreach ($item in $items) {

            try {
                Remove-Item `
                    -Path $item.FullName `
                    -Recurse `
                    -Force `
                    -ErrorAction Stop
            }
            catch {
                # Gesperrte Dateien werden übersprungen
            }
        }

        Write-Host "Bereinigung abgeschlossen: $path" -ForegroundColor Green
    }
}

Write-Host "Temporäre Dateien bereinigt." -ForegroundColor Green
Write-Host ""

# ------------------------------------------------------------
# 3. DNS Cache
# ------------------------------------------------------------

Write-Host "[3/8] DNS-Cache leeren..." -ForegroundColor Yellow

try {

    Clear-DnsClientCache -ErrorAction Stop

    Write-Host "DNS-Cache geleert." -ForegroundColor Green
}
catch {

    Write-Host "DNS-Cache konnte nicht geleert werden." -ForegroundColor Red
}

Write-Host ""

# ------------------------------------------------------------
# 4. Windows Component Store
# ------------------------------------------------------------

Write-Host "[4/8] Windows-Komponenten bereinigen..." -ForegroundColor Yellow

DISM.exe /Online /Cleanup-Image /StartComponentCleanup

if ($LASTEXITCODE -eq 0) {
    Write-Host "Komponentenbereinigung abgeschlossen." -ForegroundColor Green
}
else {
    Write-Host "Komponentenbereinigung meldete einen Fehler." -ForegroundColor Red
}

Write-Host ""

# ------------------------------------------------------------
# 5. Systemdateien prüfen
# ------------------------------------------------------------

Write-Host "[5/8] Windows-Systemdateien prüfen..." -ForegroundColor Yellow

sfc.exe /scannow

if ($LASTEXITCODE -eq 0) {
    Write-Host "Systemdateiprüfung abgeschlossen." -ForegroundColor Green
}
else {
    Write-Host "SFC meldete einen Fehler oder ein Problem." -ForegroundColor DarkYellow
}

Write-Host ""

# ------------------------------------------------------------
# 6. Energieprofil
# ------------------------------------------------------------

Write-Host "[6/8] Energieprofil konfigurieren..." -ForegroundColor Yellow

$highPerformance = powercfg -list |
Select-String "High performance|Höchstleistung"

if ($highPerformance) {

    $guid = ($highPerformance.ToString() -split '\s+')[3]

    if ($guid) {

        powercfg /setactive $guid

        if ($LASTEXITCODE -eq 0) {
            Write-Host "Höchstleistung aktiviert." -ForegroundColor Green
        }
        else {
            Write-Host "Energieprofil konnte nicht aktiviert werden." -ForegroundColor Red
        }
    }
}
else {

    powercfg -duplicatescheme SCHEME_MAX

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Höchstleistungsprofil erstellt." -ForegroundColor Green
    }
    else {
        Write-Host "Höchstleistungsprofil konnte nicht erstellt werden." -ForegroundColor Red
    }
}

Write-Host ""

# ------------------------------------------------------------
# 7. Windows Game DVR deaktivieren
# ------------------------------------------------------------

Write-Host "[7/8] Hintergrundaufnahme deaktivieren..." -ForegroundColor Yellow

$gameConfig = "HKCU:\System\GameConfigStore"

if (Test-Path $gameConfig) {

    Set-ItemProperty `
        -Path $gameConfig `
        -Name "GameDVR_Enabled" `
        -Type DWord `
        -Value 0 `
        -ErrorAction SilentlyContinue
}

$gameDvr = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"

if (Test-Path $gameDvr) {

    Set-ItemProperty `
        -Path $gameDvr `
        -Name "AppCaptureEnabled" `
        -Type DWord `
        -Value 0 `
        -ErrorAction SilentlyContinue
}

Write-Host "Hintergrundaufnahme deaktiviert." -ForegroundColor Green
Write-Host ""

# ------------------------------------------------------------
# 8. Speicheroptimierung
# ------------------------------------------------------------

Write-Host "[8/8] Speicheroptimierung konfigurieren..." -ForegroundColor Yellow

try {

    Enable-StorageSense -ErrorAction Stop

    Write-Host "Speicheroptimierung aktiviert." -ForegroundColor Green
}
catch {

    Write-Host `
        "Speicheroptimierung konnte nicht automatisch aktiviert werden." `
        -ForegroundColor DarkYellow
}

Write-Host ""

# ------------------------------------------------------------
# Abschluss
# ------------------------------------------------------------

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Optimierung abgeschlossen" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Empfehlung: PC jetzt neu starten." -ForegroundColor Yellow
Write-Host ""

# ------------------------------------------------------------
# Autostart-Programme
# ------------------------------------------------------------

Write-Host "Autostart-Programme:" -ForegroundColor Cyan
Write-Host ""

try {

    Get-CimInstance Win32_StartupCommand |
    Select-Object Name, Command, Location |
    Format-Table -AutoSize
}
catch {

    Write-Host "Autostart-Programme konnten nicht ermittelt werden." -ForegroundColor DarkYellow
}

Write-Host ""
Write-Host "Fertig." -ForegroundColor Green
Write-Host "Windows Maintenance Toolkit beendet." -ForegroundColor Green
Write-Host ""