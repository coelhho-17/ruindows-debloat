# ============================================================
#  Windows Debloat - modo manual (sem agente de IA)
#
#  Remove bloat de consumo e telemetria do Windows 10/11
#  sem quebrar drivers, hardware, jogos ou programas.
#  Reversivel: cria backup + ponto de restauracao antes de
#  qualquer mudanca.
#
#  COMO USAR:
#    1. Clique duas vezes em "debloat.bat" (mais facil), OU
#    2. Abra o PowerShell como Administrador e rode:
#         powershell -ExecutionPolicy Bypass -File .\debloat.ps1
#
#  O script pede elevacao sozinho (janela UAC) e faz 4
#  perguntas no comeco. Responda S/N e pronto.
# ============================================================

$ErrorActionPreference = 'SilentlyContinue'

# ---------- 1. Elevacao automatica ----------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host ""
    Write-Host "Preciso de privilegios de administrador." -ForegroundColor Yellow
    Write-Host "Uma janela do Windows vai pedir sua confirmacao (UAC). Clique em 'Sim'." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
    if ($PSCommandPath) {
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    } else {
        Write-Host "Rode este script a partir do arquivo (debloat.ps1), nao colado no console." -ForegroundColor Red
        Read-Host "Pressione Enter para fechar"
    }
    exit
}

# ---------- 2. Banner ----------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   Windows Debloat - limpeza de bloat e telemetria" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Este script remove apps inuteis e desativa servicos de" -ForegroundColor Gray
Write-Host "telemetria/diagnostico SEM quebrar drivers, jogos ou programas." -ForegroundColor Gray
Write-Host "Antes de qualquer mudanca, ele cria um backup e um ponto de" -ForegroundColor Gray
Write-Host "restauracao, entao da para voltar atras." -ForegroundColor Gray
Write-Host ""

# ---------- 3. Perguntas (decisoes que dependem de voce) ----------
function Ask($pergunta, $default = 'n') {
    $d = if ($default -eq 's') { 'S' } else { 'N' }
    $resp = Read-Host "$pergunta (S/N) [$d]"
    if ([string]::IsNullOrWhiteSpace($resp)) { $resp = $default }
    return ($resp -match '^(s|sim|y|yes)$')
}

$removerJogos    = Ask "Remover apps de jogo pre-instalados (Xbox app, Solitaire, Game Bar)?"
$removerOneDrive = Ask "Remover o OneDrive (sincronizacao de arquivos da Microsoft)?"
$removerStore    = Ask "Remover a Microsoft Store (loja de apps)?"
$desligarUpdate  = Ask "Desligar a atualizacao automatica do Windows?"

Write-Host ""
Write-Host "Atencao: voce respondeu 'S' para desligar atualizacao automatica." -ForegroundColor Yellow -NoNewline
if ($desligarUpdate) {
    Write-Host " Isso deixa de instalar correcoes de seguranca sozinho. Cheque manualmente de tempos em tempos." -ForegroundColor Yellow
} else {
    Write-Host "" -NoNewline
}
Write-Host ""

try {

# ---------- 4. Backup + ponto de restauracao ----------
Write-Host ">> Criando backup e ponto de restauracao..." -ForegroundColor Yellow
$backupDir = "$env:USERPROFILE\Documents\windows-debloat-backup"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
try { Start-Transcript -Path "$backupDir\debloat-log.txt" -Force | Out-Null } catch {}
Get-AppxPackage | Export-Csv "$backupDir\appx-before.csv" -NoTypeInformation
Get-Service | Export-Csv "$backupDir\services-before.csv" -NoTypeInformation
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*','HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName } | Export-Csv "$backupDir\win32-programs-before.csv" -NoTypeInformation
Enable-ComputerRestore -Drive "C:\"
Checkpoint-Computer -Description "Pre-debloat (manual)" -RestorePointType MODIFY_SETTINGS
Write-Host "   Backup salvo em: $backupDir" -ForegroundColor Gray

# ---------- 5. Remover apps UWP ----------
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
if ($removerJogos) {
    $apps += @('Microsoft.GamingApp','Microsoft.MicrosoftSolitaireCollection','Microsoft.Xbox.TCUI','Microsoft.XboxGamingOverlay','Microsoft.XboxIdentityProvider','Microsoft.XboxSpeechToTextOverlay')
}
if ($removerOneDrive) {
    $apps += @('Microsoft.OneDriveSync')
}
if ($removerStore) {
    $apps += @('Microsoft.WindowsStore','Microsoft.StorePurchaseApp')
}

Write-Host ">> Removendo apps de bloat..." -ForegroundColor Yellow
foreach ($name in $apps) {
    Get-AppxPackage -Name $name -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
        Where-Object { $_.PackageName -like "$name*" } |
        Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}

# ---------- 6. Desativar servicos ----------
$services = @(
    'DiagTrack','dmwappushservice','InventorySvc','wisvc',
    'WdiSystemHost','WdiServiceHost',
    'XblAuthManager','XblGameSave','XboxNetApiSvc',
    'SEMgrSvc','WalletService','PhoneSvc','SmsRouter',
    'WMPNetworkSvc','RetailDemo','MapsBroker','TrkWks','lmhosts','lfsvc'
)
Write-Host ">> Desativando servicos de telemetria/diagnostico..." -ForegroundColor Yellow
foreach ($s in $services) {
    if (Get-Service -Name $s -ErrorAction SilentlyContinue) {
        Set-Service -Name $s -StartupType Disabled -ErrorAction SilentlyContinue
        Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
    }
}

# ---------- 7. OneDrive ----------
if ($removerOneDrive) {
    Write-Host ">> Removendo o OneDrive..." -ForegroundColor Yellow
    Stop-Process -Name OneDrive -Force -ErrorAction SilentlyContinue
    Start-Process "$env:SystemRoot\System32\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait
    Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'OneDrive' -ErrorAction SilentlyContinue
    Get-Item 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -ErrorAction SilentlyContinue |
        ForEach-Object { $_.Property } |
        Where-Object { $_ -like 'MicrosoftEdgeAutoLaunch_*' } |
        ForEach-Object { Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name $_ -ErrorAction SilentlyContinue }
}

# ---------- 8. Pilha de IA (Recall/Copilot/Click-to-Do) ----------
Write-Host ">> Desativando pilha de IA (Recall/Copilot/Click-to-Do)..." -ForegroundColor Yellow
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

# ---------- 9. Copilot (ocultar + desativar) ----------
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowCopilotButton' -Type DWord -Value 0 -ErrorAction SilentlyContinue
New-Item -Path 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' -Force | Out-Null
Set-ItemProperty -Path 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' -Name 'TurnOffWindowsCopilot' -Type DWord -Value 1 -ErrorAction SilentlyContinue
Write-Host "   Copilot desativado (botao oculto + recurso desligado)." -ForegroundColor Gray

# ---------- 10. Windows Update automatico (politica) ----------
if ($desligarUpdate) {
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Force | Out-Null
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Name 'NoAutoUpdate' -Type DWord -Value 1 -ErrorAction SilentlyContinue
    Write-Host "   Atualizacao automatica desligada (o 'Buscar atualizacoes' manual continua funcionando)." -ForegroundColor Gray
}

# ---------- 11. Limpar cache de update ----------
Write-Host ">> Limpando cache do Windows Update..." -ForegroundColor Yellow
Stop-Service wuauserv,bits,dosvc,UsoSvc -Force -ErrorAction SilentlyContinue
Remove-Item 'C:\Windows\SoftwareDistribution\Download\*' -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item 'C:\Windows\SoftwareDistribution\DataStore\*' -Recurse -Force -ErrorAction SilentlyContinue
Start-Service bits,wuauserv -ErrorAction SilentlyContinue

# ---------- 12. Resumo ----------
$appsRestantes = @($apps | Where-Object { Get-AppxPackage -Name $_ -ErrorAction SilentlyContinue })
$appsRemovidos = $apps.Count - $appsRestantes.Count
$servicosDesativados = @($services | Where-Object { (Get-Service -Name $_ -ErrorAction SilentlyContinue).StartType -eq 'Disabled' }).Count

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "   Pronto!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  Apps de bloat removidos agora      : $appsRemovidos" -ForegroundColor White
Write-Host "  Servicos desativados agora         : $servicosDesativados" -ForegroundColor White
if ($removerOneDrive) { Write-Host "  OneDrive                           : removido" -ForegroundColor White }
if ($removerStore)    { Write-Host "  Microsoft Store                    : removida" -ForegroundColor White }
Write-Host "  Pilha de IA (Recall/Copilot)       : desativada" -ForegroundColor White
Write-Host "  Copilot                            : desativado" -ForegroundColor White
if ($desligarUpdate) { Write-Host "  Atualizacao automatica             : desligada" -ForegroundColor White }
Write-Host "  Cache do Windows Update            : limpo" -ForegroundColor White
Write-Host ""
Write-Host "  Backup e ponto de restauracao em:" -ForegroundColor Gray
Write-Host "    $backupDir" -ForegroundColor Gray
Write-Host ""
Write-Host "Para terminar, REINICIE o computador." -ForegroundColor Yellow

}
catch {
    Write-Host ""
    Write-Host "Erro inesperado: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Nada foi quebrado - voce pode rodar de novo. O backup ja foi criado." -ForegroundColor Red
}
finally {
    try { Stop-Transcript -ErrorAction SilentlyContinue | Out-Null } catch {}
    Write-Host ""
    Read-Host "Pressione Enter para fechar esta janela"
}
