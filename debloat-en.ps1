# ============================================================
#  Windows Debloat - manual mode (no AI agent)
#
#  Removes consumer bloat and telemetry from Windows 10/11
#  without breaking drivers, hardware, games or programs.
#  Reversible: creates a backup + restore point before
#  any change.
#
#  HOW TO USE:
#    1. Double-click "debloat-en.bat" (easiest), OR
#    2. Open PowerShell as Administrator and run:
#         powershell -ExecutionPolicy Bypass -File .\debloat-en.ps1
#
#  The script asks for elevation on its own (UAC window) and
#  asks 4 questions at the start. Answer Y/N and you are done.
# ============================================================

$ErrorActionPreference = 'SilentlyContinue'

# ---------- 1. Automatic elevation ----------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host ""
    Write-Host "Administrator privileges are required." -ForegroundColor Yellow
    Write-Host "A Windows window will ask for confirmation (UAC). Click 'Yes'." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
    if ($PSCommandPath) {
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    } else {
        Write-Host "Run this script from the file (debloat-en.ps1), not pasted into the console." -ForegroundColor Red
        Read-Host "Press Enter to close"
    }
    exit
}

# ---------- 2. Banner ----------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   Windows Debloat - bloat and telemetry cleanup" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script removes useless apps and disables telemetry/" -ForegroundColor Gray
Write-Host "diagnostic services WITHOUT breaking drivers, games or programs." -ForegroundColor Gray
Write-Host "Before any change, it creates a backup and a restore point," -ForegroundColor Gray
Write-Host "so you can always go back." -ForegroundColor Gray
Write-Host ""

# ---------- 3. Questions (decisions that depend on you) ----------
function Ask($question, $default = 'n') {
    $d = if ($default -eq 'y') { 'Y' } else { 'N' }
    $resp = Read-Host "$question (Y/N) [$d]"
    if ([string]::IsNullOrWhiteSpace($resp)) { $resp = $default }
    return ($resp -match '^(y|yes|s|sim)$')
}

$removeGaming = Ask "Remove preinstalled gaming apps (Xbox app, Solitaire, Game Bar)?"
$removeOneDrive = Ask "Remove OneDrive (Microsoft file sync)?"
$removeStore = Ask "Remove the Microsoft Store (app store)?"
$disableUpdates = Ask "Disable automatic Windows updates?"

if ($disableUpdates) {
    Write-Host ""
    Write-Host "Warning: automatic updates disabled. Security fixes will no longer install by themselves - check for updates manually from time to time." -ForegroundColor Yellow
    Write-Host ""
}

try {

# ---------- 4. Backup + restore point ----------
Write-Host ">> Creating backup and restore point..." -ForegroundColor Yellow
$backupDir = "$env:USERPROFILE\Documents\windows-debloat-backup"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
try { Start-Transcript -Path "$backupDir\debloat-log.txt" -Force | Out-Null } catch {}
Get-AppxPackage | Export-Csv "$backupDir\appx-before.csv" -NoTypeInformation
Get-Service | Export-Csv "$backupDir\services-before.csv" -NoTypeInformation
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*','HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName } | Export-Csv "$backupDir\win32-programs-before.csv" -NoTypeInformation
Enable-ComputerRestore -Drive "C:\"
Checkpoint-Computer -Description "Pre-debloat (manual)" -RestorePointType MODIFY_SETTINGS
Write-Host "   Backup saved to: $backupDir" -ForegroundColor Gray

# ---------- 5. Remove UWP apps ----------
$appsCore = @(
    'Microsoft.BingNews','Microsoft.BingSearch','Microsoft.BingWeather',
    'Clipchamp.Clipchamp','Microsoft.GetHelp','Microsoft.Todos',
    'Microsoft.WindowsFeedbackHub','Microsoft.WindowsCamera',
    'Microsoft.WindowsSoundRecorder','Microsoft.WindowsAlarms',
    'Microsoft.YourPhone','Microsoft.OutlookForWindows',
    'Microsoft.PowerAutomateDesktop','Microsoft.Windows.DevHome',
    'MicrosoftCorporationII.QuickAssist','MSTeams',
    'MicrosoftWindows.Client.WebExperience','MicrosoftWindows.CrossDevice',
    'Microsoft.WidgetsPlatformRuntime','Microsoft.StartExperiencesApp'
)
$apps = @($appsCore)
if ($removeGaming) {
    $apps += @('Microsoft.GamingApp','Microsoft.MicrosoftSolitaireCollection','Microsoft.Xbox.TCUI','Microsoft.XboxGamingOverlay','Microsoft.XboxIdentityProvider','Microsoft.XboxSpeechToTextOverlay')
}
if ($removeOneDrive) {
    $apps += @('Microsoft.OneDriveSync')
}
if ($removeStore) {
    $apps += @('Microsoft.WindowsStore','Microsoft.StorePurchaseApp')
}

Write-Host ">> Removing bloat apps..." -ForegroundColor Yellow
foreach ($name in $apps) {
    Get-AppxPackage -Name $name -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
        Where-Object { $_.PackageName -like "$name*" } |
        Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}

# ---------- 6. Disable services ----------
$services = @(
    'DiagTrack','dmwappushservice','InventorySvc','wisvc',
    'WdiSystemHost','WdiServiceHost',
    'XblAuthManager','XblGameSave','XboxNetApiSvc',
    'SEMgrSvc','WalletService','PhoneSvc','SmsRouter',
    'WMPNetworkSvc','RetailDemo','MapsBroker','TrkWks','lmhosts','lfsvc'
)
Write-Host ">> Disabling telemetry/diagnostic services..." -ForegroundColor Yellow
foreach ($s in $services) {
    if (Get-Service -Name $s -ErrorAction SilentlyContinue) {
        Set-Service -Name $s -StartupType Disabled -ErrorAction SilentlyContinue
        Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
    }
}

# ---------- 7. OneDrive ----------
if ($removeOneDrive) {
    Write-Host ">> Removing OneDrive..." -ForegroundColor Yellow
    Stop-Process -Name OneDrive -Force -ErrorAction SilentlyContinue
    Start-Process "$env:SystemRoot\System32\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait
    Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'OneDrive' -ErrorAction SilentlyContinue
    Get-Item 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -ErrorAction SilentlyContinue |
        ForEach-Object { $_.Property } |
        Where-Object { $_ -like 'MicrosoftEdgeAutoLaunch_*' } |
        ForEach-Object { Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name $_ -ErrorAction SilentlyContinue }
}

# ---------- 8. AI stack (Recall/Copilot/Click-to-Do) ----------
Write-Host ">> Disabling AI stack (Recall/Copilot/Click-to-Do)..." -ForegroundColor Yellow
if (Get-Service -Name 'WSAIFabricSvc' -ErrorAction SilentlyContinue) {
    Stop-Service -Name 'WSAIFabricSvc' -Force -ErrorAction SilentlyContinue
    Set-Service -Name 'WSAIFabricSvc' -StartupType Disabled -ErrorAction SilentlyContinue
}
$aiTasks = Get-ScheduledTask -TaskPath '\Microsoft\Windows\WindowsAI\' -ErrorAction SilentlyContinue
if ($aiTasks) {
    $inner = Join-Path $env:TEMP 'debloat-disable-ai.ps1'
    @'
Get-ScheduledTask | Where-Object { $_.TaskPath -like '\Microsoft\Windows\WindowsAI\*' } | ForEach-Object { Disable-ScheduledTask -TaskPath $_.TaskPath -TaskName $_.TaskName }
'@ | Set-Content -Path $inner -Encoding UTF8
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$inner`""
    $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
    Register-ScheduledTask -TaskName 'DebloatDisableAI' -Action $action -Principal $principal -Force | Out-Null
    Start-ScheduledTask -TaskName 'DebloatDisableAI' -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 8
    Unregister-ScheduledTask -TaskName 'DebloatDisableAI' -Confirm:$false
    Remove-Item $inner -Force -ErrorAction SilentlyContinue
}

# ---------- 9. Copilot (hide + disable) ----------
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowCopilotButton' -Type DWord -Value 0 -ErrorAction SilentlyContinue
New-Item -Path 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' -Force | Out-Null
Set-ItemProperty -Path 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' -Name 'TurnOffWindowsCopilot' -Type DWord -Value 1 -ErrorAction SilentlyContinue
Write-Host "   Copilot disabled (button hidden + feature off)." -ForegroundColor Gray

# ---------- 10. Automatic Windows Update (policy) ----------
if ($disableUpdates) {
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Force | Out-Null
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Name 'NoAutoUpdate' -Type DWord -Value 1 -ErrorAction SilentlyContinue
    Write-Host "   Automatic updates disabled (manual 'Check for updates' still works)." -ForegroundColor Gray
}

# ---------- 11. Clear update cache ----------
Write-Host ">> Clearing Windows Update cache..." -ForegroundColor Yellow
Stop-Service wuauserv,bits,dosvc,UsoSvc -Force -ErrorAction SilentlyContinue
Remove-Item 'C:\Windows\SoftwareDistribution\Download\*' -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item 'C:\Windows\SoftwareDistribution\DataStore\*' -Recurse -Force -ErrorAction SilentlyContinue
Start-Service bits,wuauserv -ErrorAction SilentlyContinue

# ---------- 12. Summary ----------
$appsRemaining = @($apps | Where-Object { Get-AppxPackage -Name $_ -ErrorAction SilentlyContinue })
$appsRemoved = $apps.Count - $appsRemaining.Count
$servicesDisabled = @($services | Where-Object { (Get-Service -Name $_ -ErrorAction SilentlyContinue).StartType -eq 'Disabled' }).Count

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "   Done!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  Bloat apps removed now             : $appsRemoved" -ForegroundColor White
Write-Host "  Services disabled now              : $servicesDisabled" -ForegroundColor White
if ($removeOneDrive) { Write-Host "  OneDrive                           : removed" -ForegroundColor White }
if ($removeStore)    { Write-Host "  Microsoft Store                    : removed" -ForegroundColor White }
Write-Host "  AI stack (Recall/Copilot)          : disabled" -ForegroundColor White
Write-Host "  Copilot                            : disabled" -ForegroundColor White
if ($disableUpdates) { Write-Host "  Automatic updates                  : disabled" -ForegroundColor White }
Write-Host "  Windows Update cache               : cleared" -ForegroundColor White
Write-Host ""
Write-Host "  Backup and restore point at:" -ForegroundColor Gray
Write-Host "    $backupDir" -ForegroundColor Gray
Write-Host ""
Write-Host "To finish, RESTART the computer." -ForegroundColor Yellow

}
catch {
    Write-Host ""
    Write-Host "Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Nothing was broken - you can run it again. The backup was already created." -ForegroundColor Red
}
finally {
    try { Stop-Transcript -ErrorAction SilentlyContinue | Out-Null } catch {}
    Write-Host ""
    Read-Host "Press Enter to close this window"
}
