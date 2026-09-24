[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification='Interactive console script uses Write-Host for colored status output.')]
param()

# ============================================================
# Windows 11 Performance Optimizer
# ============================================================

# Als Administrator ausführen
$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Bitte PowerShell als Administrator starten." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Windows 11 Performance Optimizer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# 1. Systeminformationen
# ------------------------------------------------------------

Write-Host "[1/8] Systeminformationen..." -ForegroundColor Yellow

$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$ram = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)

Write-Host "Windows: $($os.Caption)"
Write-Host "CPU: $($cpu.Name)"
Write-Host "RAM: $ram GB"
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
        Get-ChildItem $path -Force -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "Temporäre Dateien bereinigt." -ForegroundColor Green

# ------------------------------------------------------------
# 3. DNS Cache
# ------------------------------------------------------------

Write-Host "[3/8] DNS-Cache leeren..." -ForegroundColor Yellow

Clear-DnsClientCache

Write-Host "DNS-Cache geleert." -ForegroundColor Green

# ------------------------------------------------------------
# 4. Windows Component Store
# ------------------------------------------------------------

Write-Host "[4/8] Windows-Komponenten bereinigen..." -ForegroundColor Yellow

DISM.exe /Online /Cleanup-Image /StartComponentCleanup

Write-Host "Komponentenbereinigung abgeschlossen." -ForegroundColor Green

# ------------------------------------------------------------
# 5. Systemdateien prüfen
# ------------------------------------------------------------

Write-Host "[5/8] Windows-Systemdateien prüfen..." -ForegroundColor Yellow

sfc.exe /scannow

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
        Write-Host "Höchstleistung aktiviert." -ForegroundColor Green
    }

} else {

    # Höchstleistungsprofil erzeugen
    powercfg -duplicatescheme SCHEME_MAX

    Write-Host "Höchstleistungsprofil aktiviert/erstellt." -ForegroundColor Green
}

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

# ------------------------------------------------------------
# 8. Speicheroptimierung
# ------------------------------------------------------------

Write-Host "[8/8] Speicheroptimierung konfigurieren..." -ForegroundColor Yellow

try {
    Enable-StorageSense -ErrorAction SilentlyContinue
    Write-Host "Speicheroptimierung aktiviert." -ForegroundColor Green
}
catch {
    Write-Host "Speicheroptimierung konnte nicht automatisch aktiviert werden." -ForegroundColor DarkYellow
}

# ------------------------------------------------------------
# Abschluss
# ------------------------------------------------------------

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Optimierung abgeschlossen" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Empfehlung: PC jetzt neu starten." -ForegroundColor Yellow
Write-Host ""

Write-Host "Autostart-Programme:" -ForegroundColor Cyan

Get-CimInstance Win32_StartupCommand |
    Select-Object Name, Command, Location |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Fertig." -ForegroundColor Green
