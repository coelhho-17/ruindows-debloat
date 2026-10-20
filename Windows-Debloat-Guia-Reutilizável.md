# Windows Debloat — Guia Reutilizável (qualquer agente de terminal)

> **Sem agente de IA?** Use o modo manual: baixe `debloat.ps1` + `debloat.bat` do repositório **na mesma pasta** e clique com o **botão direito** no `debloat.bat` → **"Executar como administrador"** (não clique duas vezes). Este guia abaixo é para quando você usa um agente de IA.

---

## COMO USAR (3 passos)

**O que isto faz:** limpa o Windows — tira lixo, telemetria e apps inúteis e desliga a atualização automática — **sem quebrar** drivers, jogos, controle ou programas. É reversível (tem como voltar).

1. **Salve este arquivo** em algum lugar fácil (Downloads ou Documentos). Lembre onde salvou.
2. **Abra seu assistente de IA como Administrador** (botão direito no ícone do programa → "Executar como administrador"). Sem isso, a limpeza falha.
3. **Copie o bloco abaixo e cole no assistente.** Ele primeiro analisa o PC e mostra um RELATÓRIO do que pretende remover/desativar — cada item com o porquê — e PARA para você aprovar. Nada é mudado antes do seu "sim". Depois da sua aprovação, ele executa e, no final, pede para reiniciar o PC — reinicie e pronto.

```text
Você vai fazer um "debloat" no meu Windows: limpar bloat, telemetria e apps inúteis SEM quebrar drivers, hardware, jogos ou programas.

1. Encontre e leia o arquivo "Windows-Debloat-Guia-Reutilizável.md" (procure em Downloads, Documentos ou Área de Trabalho; se não achar, me pergunte onde salvei) e siga-o do início ao fim.
2. Antes de qualquer coisa, detecte minha CPU e GPU e os programas que eu uso (Steam, AutoCAD, VS Code, Adobe, etc.) — e só então decida o que remover/desativar. NUNCA remova ou desative nada ligado a programas que eu uso para trabalhar, criar ou jogar.
3. Verifique se está rodando como Administrador. Se não estiver, me avise para eu reabrir o terminal como Administrador.
4. Depois de detectar CPU/GPU e classificar tudo, apresente um RELATÓRIO do que pretende remover/desativar (cada item com justificativa) e PARE para eu aprovar. Só execute depois que eu confirmar "sim". NÃO mude nada antes da minha aprovação.
5. NÃO remova drivers, áudio, chipset, GPU, Wi-Fi, o controle do meu Xbox, nem os programas que eu uso para trabalhar/jogar/criar (Steam, AutoCAD, VS Code, Adobe, etc.). Não desinstale antivírus sem me perguntar antes.
6. No final, me diga exatamente o que foi feito, apresente um relatório dos processos/serviços que ficaram ativos (e o porquê de cada um) e me peça para reiniciar o PC.

Faça o debloat completo seguindo o guia.
```

---

> Guia definitivo para reproduzir o debloat do Windows em QUALQUER PC — desktop ou laptop, qualquer CPU/GPU e qualquer edição (Windows 10/11, Home ou Pro).
> Funciona com QUALQUER agente de IA que tenha acesso a um terminal/shell e rode no Windows elevado (admin): Hermes Agent, Claude Code, GitHub Copilot (CLI), OpenClaw, Cline, etc. O guia é autocontido e não depende de skill/plugin específico de nenhum agente.
> Validado em 2 máquinas: ThinkPad Intel/Win11 Pro (dev) e desktop AMD Ryzen + NVIDIA RTX 3060/Win11 Home (gamer).
> Executar de cima a baixo. Antes de qualquer passo destrutivo, fazer recon + backup. Nada aqui é irreversível — tudo tem rollback.

---

## Requisitos mínimos do agente (ler antes de tudo)

Para um agente executar este guia, ele precisa de TRÊS coisas. Sem elas, o guia não funciona:

1. **Acesso a terminal/shell** — o agente precisa conseguir rodar comandos PowerShell. Um assistente que só responde texto (sem ferramenta de execução de comandos) não consegue fazer NADA daqui.
2. **Terminal ELEVADO (admin)** — sem privilégios de administrador, ~80% do guia falha com "acesso negado" (remover apps, desativar serviços, escrever em HKLM). O usuário precisa ABRIR o agente "como Administrador". Há um comando de verificação de elevação no passo 0.
3. **Sessão interativa** — o guia exige apresentar um relatório/plano (seção 3.5) e obter a aprovação explícita do usuário antes de executar. Num run não-interativo (cron, CI, script automático) não há como aprovar; nesse caso, o agente deve gerar SÓ o relatório e parar (ou aplicar apenas os passos 100% seguros, se o contexto permitir).

> Se o agente rodar dentro de container/WSL em vez do Windows nativo, os comandos PowerShell não alcançam o sistema Windows real — o guia precisa rodar no Windows nativo.

---

## 0. Princípios (ler antes de tudo)

1. Objetivo: remover bloat de consumo/telemetria **preservando** drivers, hardware, recursos de jogo e o toolchain de dev.
2. **Nunca remover às cegas** um pacote de nome obscuro. Checar `Publisher` primeiro: se for `CN=Microsoft Windows`, é componente de sistema (IA/voz/input), não bloat.
3. **Nunca tocar** em DRIVERS e serviços de hardware (GPU, áudio, chipset, touchpad, térmica, energia). Cuidado: "OEM" não é sinônimo de bloat — utilitário OEM que controla hardware (Lenovo Vantage, Armoury Crate) é KEEP; app OEM de consumo (McAfee, SupportAssist) é REMOVE. Ver seção 3.
4. **Sempre criar rollback antes**: exportar CSVs do estado "antes" + ponto de restauração.
5. **Shell**: cada agente roda num shell diferente no Windows — git-bash/MSYS (Hermes, Claude Code), PowerShell, cmd ou WSL. Os comandos deste guia são PowerShell; o agente deve adaptar a sintaxe ao shell em que está:
   - **git-bash/MSYS**: envolver comandos PowerShell em **aspas simples** no nível bash (MSYS expande `$var`/`$_` dentro de aspas duplas).
   - **PowerShell puro**: rodar os comandos diretamente (sem `powershell.exe -Command`), cuidando de `$`.
   - **WSL**: chamar via `powershell.exe` (o PowerShell do Windows, não o do WSL).
   Exemplo (git-bash/MSYS):
   ```bash
   powershell.exe -NoProfile -Command 'Get-Service DiagTrack | Select-Object Name,Status,StartType'
   ```
6. **Elevação**: checar admin antes de qualquer passo destrutivo:
   ```powershell
   ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
   ```
   Se retornar `False`, abrir um terminal elevado (no Claude Code: fechar e reabrir o terminal como Administrador).
7. **Versão do Windows** vem de `DisplayVersion`/`CurrentBuild`, NÃO de `ProductName` (o registro ainda diz "Windows 10 Pro" no Win11 25H2):
   ```powershell
   Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' | Select-Object DisplayVersion,CurrentBuild
   ```
8. **Usuário leigo + aprovação prévia**: o dono do PC pode não entender os termos. Explicar cada decisão em linguagem simples. Antes de qualquer passo destrutivo, apresentar o **plano completo (seção 3.5)** e esperar o "sim". O usuário também precisa APROVAR as permissões que o próprio agente pedir (cada agente tem seu mecanismo de allow/deny — Claude Code, Copilot, etc.). Não usar modo "auto-aprovar tudo".
9. **Nunca quebrar o trabalho do usuário**: detectar o que o usuário USA (dev, CAD, design, foto/vídeo, jogos) e NUNCA remover/desativar software ou serviço ligado a isso. Software de trabalho/criação/jogo NÃO é bloat — só é bloat o que não está ligado a nada que ele usa (trial, OEM de marketing, promoção). Na dúvida, KEEP e perguntar.

---

## 1. Como adaptar a QUALQUER hardware (não é só o PC gamer)

O guia foi validado em 2 máquinas bem diferentes (ThinkPad Intel/Win11 Pro e desktop AMD+NVIDIA/Win11 Home). O segredo pra funcionar em qualquer PC: **detectar CPU e GPU primeiro e classificar conforme o que existe** — nunca aplicar a lista de outra máquina às cegas.

Regras de hardware (aplicar conforme o detectado):

- **CPU Intel** (muito comum em laptop): preservar serviços Intel — áudio `IntelAudioService`, térmica `esifsvc`/`LITSSVC` (em OEMs como Lenovo/Dell/HP), chipset. Em laptop Dell/HP/Lenovo, há serviços OEM específicos (ex.: `IBMPMSVC`, `TPHKLOAD`, `LenovoSmartStandby` em Lenovo) — preservar.
- **CPU AMD** (Ryzen): preservar chipset AMD (`AMDRyzenMasterDriver` se Ryzen Master instalado), crash-defender AMD. Ignorar os serviços Intel (não existem).
- **GPU NVIDIA**: KEEP obrigatório `NVDisplay.ContainerLocalSystem` + `NvContainerLocalSystem` (containers de display — essenciais). Desativável `NvTelemetryContainer` (telemetria) se não usa GeForce Experience. `GeForce Experience` (app Win32) é bloat opcional — perguntar antes (alguns usam p/ driver/gravação).
- **GPU AMD (Radeon)** ou **GPU Intel (Arc/HD/UHD)**: preservar o driver/software da GPU; telemetria equivalente desativável se existir (AMD tem telemetria de "User Experience").
- **Áudio**: sempre KEEP `Audiosrv` + driver de áudio (Realtek `RtkAudioUniversalService`, Dolby `DolbyDAXAPI`/`DolbyLaboratories.DolbyAccess`, ou o do fabricante).
- **Windows Home vs Pro**: sem diferença no procedimento — as chaves de política de registro (NoAutoUpdate, Copilot) funcionam nas duas. Home não tem `gpedit.msc`, mas o guia usa registro, então tanto faz.
- **Windows 10 vs 11**: os passos de pilha de IA (5.4) e Copilot (5.5) só se aplicam ao Windows 11 (23H2+). No Windows 10, esses componentes não existem — pular. Todo o resto vale para os dois.
- **Uso gaming**: se for PC de jogo, NÃO sair removendo Xbox/Game Bar. **Perguntar antes** sobre Xbox app, Game Bar, Game Pass. Seguro desativar mesmo em gamer: `XblAuthManager`/`XblGameSave`/`XboxNetApiSvc` (cloud/auth/save-sync). **KEEP sempre** `XboxGipSvc` + `GameInputSvc` (controle Xbox via Bluetooth/USB).
- **Laptop de consumo**: atenção extra a bloat de terceiros/OEM (McAfee, Norton, trial de antivírus, apps Dell/HP/Asus/Lenovo) — ver seção 3 (REMOVE).

---

## 2. Diagnóstico (recon — somente leitura, rodar em paralelo)

> ⚠️ **PRIMEIRO passo obrigatório: detectar CPU, GPU e o PERFIL do usuário (o que ele usa).** Toda decisão de debloat depende do hardware E do software que o usuário realmente usa. Só depois de saber CPU, GPU e quais programas ele tem (Steam, AutoCAD, VS Code, Adobe, etc.) é que se classifica qualquer item.

```powershell
# 1) CPU e GPU — SEMPRE o primeiro comando (a decisão de debloat depende disto)
Get-CimInstance Win32_Processor | Select-Object Name,Manufacturer
Get-CimInstance Win32_VideoController | Select-Object Name,AdapterCompatibility,DriverVersion

# Versão real do Windows
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' | Select-Object DisplayVersion,CurrentBuild

# Apps UWP instalados
Get-AppxPackage | Select-Object Name,Publisher,Version

# Serviços
Get-Service | Select-Object Name,Status,StartType

# Programas Win32 (uninstall registry — sinal rápido de quanto lixo real existe)
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*','HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName } | Select-Object DisplayName,Publisher

# Itens de inicialização
Get-CimInstance Win32_StartupCommand | Select-Object Name,Command,Location
```

Depois, com base no hardware (CPU/GPU) e nos programas Win32 encontrados, identificar o **PERFIL do usuário**: desenvolvedor (VS Code/Visual Studio/JetBrains/Docker/Git), CAD (AutoCAD/Fusion 360/SolidWorks/Inventor), design (Adobe/Figma/Corel), foto/vídeo (Photoshop/Premiere/DaVinci/OBS/Blender), gamer (Steam/Epic/GOG/Battle.net). Tudo que for software de trabalho/criação/jogo do usuário é KEEP (ver seção 3). Só então classificar cada item em REMOVE / DISABLE / KEEP.

---

## 3. Listas de classificação

> A classificação depende da CPU/GPU detectada no passo 2. Aplicar apenas as listas que correspondem ao hardware real. NUNCA aplicar lista de hardware de outra máquina sem verificar o que existe aqui.

### KEEP (drivers / hardware / frameworks / toolchain / jogo)

- **GPU NVIDIA**: `NVDisplay.ContainerLocalSystem`, `NvContainerLocalSystem`, `NVIDIA Display Container LS`.
- **GPU AMD**: driver Radeon/Adrenalin + serviço associado.
- **GPU Intel**: `igfxCUIService`/`IntelGraphicsSoftwareService` (se presente).
- **Chipset AMD**: `AMDRyzenMasterDriver` (se Ryzen Master instalado), serviços AMD de chipset.
- **Chipset Intel / térmica OEM**: `esifsvc`, `LITSSVC`, `IBMPMSVC`, `LenovoSmartStandby`, `TPHKLOAD` (Lenovo), equivalentes Dell/HP.
- **Áudio**: `Audiosrv`, Realtek (`RtkAudioUniversalService`), Dolby (`DolbyDAXAPI`/`DolbyLaboratories.DolbyAccess`).
- **Rede**: `WlanSvc`, `Dhcp`, `Dnscache`, `mpssvc` (vale p/ Wi-Fi e Ethernet).
- **Windows Update**: `wuauserv`, `UsoSvc`, `WaaSMedicSvc` (não desativar — ver seção 5.6).
- **Defender**: `WinDefend`, `WdNisSvc`, `SecurityHealthService`, `wscsvc`.
- **Controle Xbox**: `XboxGipSvc`, `GameInputSvc`.
- **winget**: `Microsoft.DesktopAppInstaller` (pacote separado da Store — nunca remover).
- **Apps úteis**: Terminal, Calculator, Notepad, Paint, codecs (HEIF/HEVC/AV1/VP9/WebMedia), frameworks (VCLibs, UI.Xaml, .NET Native, WindowsAppRuntime), WindowsSubsystemForLinux, WebView2.
- **Utilitário OEM de hardware** (controla RGB/fan/hotkeys): Lenovo Vantage, Asus Armoury Crate, etc. — perguntar antes de remover.

### KEEP (software e serviços PROFISSIONAIS do usuário — NUNCA remover)

Identificar pelo recon (passo 2) o que o usuário usa e preservar o software E seus serviços/frameworks de suporte:

- **Dev**: VS Code, Visual Studio, JetBrains (IntelliJ/PyCharm/Rider), Docker Desktop (+ serviço `com.docker.service`), WSL, Git, Node, Python, Java/JDK, .NET, bancos de dados (PostgreSQL/MySQL/SQL Server e seus serviços), Android Studio, Unity/Unreal.
- **CAD/Engenharia**: AutoCAD, Fusion 360, SolidWorks, Inventor, Revit, SketchUp, CATIA — e os serviços de licença deles (`FlexNet Licensing Service`, `Autodesk Desktop Licensing Service`, `AdAppMgrSvc`/Autodesk Desktop App). NUNCA desativar serviço de licença (FlexNet/Autodesk) — sem ele o software para de abrir.
- **Design**: Adobe Creative Cloud (Photoshop/Illustrator/InDesign) + `Adobe Update Service`/Creative Cloud, Figma, CorelDRAW, Affinity.
- **Foto/Vídeo**: Lightroom, Premiere, DaVinci Resolve, OBS Studio, Blender, Capture One, Vegas. (Dependem da GPU — por isso os drivers/containers de GPU são KEEP.)
- **Gaming**: Steam (+ `Steam Client Service`), Epic Games, GOG Galaxy, Battle.net, Riot, Xbox app/Game Pass (se o usuário usa), Discord.
- **Regra geral**: serviço ou app que pertence a um software que o usuário USA é KEEP. Só é bloat se NÃO estiver ligado a nada que ele usa (trial expirado, OEM de marketing, promoção).

### REMOVE (bloat UWP de consumo — seguro)

- Gaming (só se o usuário concordar): `Microsoft.GamingApp`, `Microsoft.MicrosoftSolitaireCollection`, `Microsoft.Xbox.TCUI`, `Microsoft.XboxGamingOverlay`, `Microsoft.XboxIdentityProvider`, `Microsoft.XboxSpeechToTextOverlay`.
- Bing: `Microsoft.BingNews`, `Microsoft.BingSearch`, `Microsoft.BingWeather`.
- Consumo: `Clipchamp.Clipchamp`, `Microsoft.GetHelp`, `Microsoft.Todos`, `Microsoft.WindowsFeedbackHub`, `Microsoft.WindowsCamera`, `Microsoft.WindowsSoundRecorder`, `Microsoft.WindowsAlarms`, `Microsoft.YourPhone`, `Microsoft.OutlookForWindows`, `Microsoft.PowerAutomateDesktop`, `Microsoft.Windows.DevHome`, `MicrosoftCorporationII.QuickAssist`, `MSTeams`, `MicrosoftWindows.Client.WebExperience` (Widgets), `MicrosoftWindows.CrossDevice`, `Microsoft.OneDriveSync`.
- Widgets/feed restantes (ficam como órfãos rodando processos mesmo depois que o WebExperience sai): `Microsoft.WidgetsPlatformRuntime` (motor de Widgets — roda o `WidgetService`) e `Microsoft.StartExperiencesApp` (feed "My Feed"/notícias do menu Iniciar — roda o `MicrosoftStartFeedProvider`). Remover os dois NÃO quebra o menu Iniciar (o Iniciar em si é o `Microsoft.Windows.StartMenuExperienceHost`, que é KEEP).

### REMOVE (bloat de terceiros/OEM — Win32, comum em laptop de consumo)

Aparecem na lista de desinstalação Win32 (recon passo 2) com `Publisher` = Dell/HP/Lenovo/Asus/Acer/McAfee/Norton/etc. **Confirmar com o usuário antes** (antivírus é decisão dele):

- **Antivírus/limpeza de trial**: McAfee (LiveSafe, Security Scan Plus, WebAdvisor), Norton (trial), Avast/AVG (e "Cleanup"), PC App Store, Chromium pré-instalado.
- **Apps OEM de consumo/suporte**: Dell SupportAssist, HP Support Assistant, MyASUS, Acer Care Center, promoções/trials (Office/Spotify/Netflix pré-instalados).
- **Regra (conservadora)**: remover SOMENTE o que for claramente bloat de consumo — antivírus de trial, apps OEM de suporte/marketing, promoções pré-instaladas. **NUNCA remover software que o usuário usa para trabalhar/criar/jogar** (VS Code, Visual Studio, Docker, AutoCAD, Fusion, Adobe, Steam, Epic, etc.). Na dúvida, NÃO remover e PERGUNTAR. Antivírus de terceiros também pode BLOQUEAR a execução dos scripts deste guia (deleção de arquivos/serviços) — se for remover, remover o antivírus primeiro, ou o guia pode falhar com "acesso negado" onde não deveria.

### DISABLE (serviços — seguro)

- Telemetria: `DiagTrack`, `dmwappushservice`, `InventorySvc`, `wisvc`.
- Diagnóstico: `WdiSystemHost`, `WdiServiceHost`.
- Xbox Live cloud: `XblAuthManager`, `XblGameSave`, `XboxNetApiSvc`.
- NFC/pagamento/mensagem: `SEMgrSvc`, `WalletService`, `PhoneSvc`, `SmsRouter`.
- Outros: `WMPNetworkSvc`, `RetailDemo`, `MapsBroker`, `TrkWks`, `lmhosts`, `lfsvc`. (TrkWks/lmhosts são legado — seguros em PC doméstico; se o PC estiver em domínio corporativo, pular esses dois.)
- NVIDIA telemetria (se não usa GFE): `NvTelemetryContainer`.

### DO NOT touch (componentes de sistema — não são bloat)

- Pacotes com nome GUID (`1527c705-...` etc.) e `MicrosoftWindows.61869XXX.*` assinados `CN=Microsoft Windows` (stack de IA/voz/input).
- `MicrosoftWindows.Client.CoreAI`, `MicrosoftWindows.Client.Core`, `MicrosoftWindows.Client.FileExp`, etc.

---

## 3.5 Plano de Debloat — relatório + APROVAÇÃO do usuário (obrigatório, antes de executar)

> ⚠️ **PONTO DE CONTROLE OBRIGATÓRIO.** Depois do recon (seção 2) e da classificação (seção 3), o agente NÃO executa nada ainda. Primeiro monta um relatório/plano, apresenta ao usuário e ESPERA a aprovação explícita. Só depois do "sim" é que segue para o backup (seção 4) e a execução (seção 5).

O relatório deve ser em linguagem simples (o dono do PC pode ser leigo) e conter, no mínimo:

1. **Hardware e perfil detectados** (1-2 linhas): CPU, GPU e o que o usuário usa (dev, CAD, design, foto/vídeo, gamer).
2. **O que será REMOVIDO** — lista, cada item com justificativa de 1 linha (por que é bloat).
3. **O que será DESATIVADO** — serviços/tarefas, cada um com justificativa.
4. **O que será MANTIDO mesmo parecendo bloat** — drivers, serviços de licença (FlexNet/Autodesk/Adobe), GPU, controle Xbox, WebView2, componentes de sistema ("DO NOT touch"). Para o usuário entender por que aquilo fica.
5. **Decisões que dependem do usuário** — perguntas explícitas, uma por linha: antivírus de terceiros, GeForce Experience/NVIDIA, apps de jogo (Xbox app, Game Bar, Game Pass), OneDrive, desligar update automático, remover a Store.

Depois de apresentar, **parar e perguntar**: "Aceita aplicar este plano? Responda sim, não, ou me diga quais itens mudar."

Regras:

- **Não executar nada destrutivo** (remover app, desativar serviço, mexer em registro) antes do "sim" do usuário. O backup (seção 4) é só leitura/export + ponto de restauração e pode ser feito antes; a execução (seção 5) só após aprovação.
- Se o usuário disser "não" ou pedir ajustes, **revisar o plano** e reapresentar.
- Em modo não-interativo (cron/CI, sem como perguntar): **não executar** o que exige decisão — gerar só o relatório e parar.

> Por quê: o debloat é reversível, mas cada ação mexe em algo que pode ser do trabalho/criação/jogo do usuário. Um "sim" informado antes de tocar em qualquer coisa dá ao usuário controle total do que acontece no PC dele.

---

## 4. Backup + rollback (antes de qualquer ação)

```powershell
# Exportar estado "antes"
Get-AppxPackage | Export-Csv -Path "$env:USERPROFILE\Documents\windows-debloat-backup\appx-before.csv" -NoTypeInformation
Get-Service | Export-Csv -Path "$env:USERPROFILE\Documents\windows-debloat-backup\services-before.csv" -NoTypeInformation
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' | Export-Csv -Path "$env:USERPROFILE\Documents\windows-debloat-backup\win32-programs-before.csv" -NoTypeInformation

# Ponto de restauração (se falhar com "service disabled", habilitar antes)
Enable-ComputerRestore -Drive "C:\"
Checkpoint-Computer -Description "Pre-debloat" -RestorePointType MODIFY_SETTINGS
```

---

## 5. Execução

> ⚠️ Só execute esta seção DEPOIS da aprovação explícita do usuário no plano (seção 3.5).

### 5.1 Remover apps UWP (por usuário + provisionado)

```powershell
$removed = @('Microsoft.GamingApp','Microsoft.BingNews','Clipchamp.Clipchamp', ...)  # lista completa da seção REMOVE
foreach ($name in $removed) {
  Get-AppxPackage -Name $name -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
  Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like "$name*" } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}
```

### 5.2 Desativar serviços

```powershell
$disabled = @('DiagTrack','dmwappushservice','InventorySvc','wisvc', ...)  # lista da seção DISABLE
foreach ($s in $disabled) {
  Set-Service -Name $s -StartupType Disabled -ErrorAction SilentlyContinue
  Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
}
```

### 5.3 OneDrive + auto-launch do Edge

> ⚠️ PERGUNTAR antes: se o usuário usa OneDrive para sincronizar/backup (fotos, documentos, projetos), NÃO remover — muitos designers/fotógrafos dependem dele. Só remover se o usuário confirmar que não usa.

```powershell
Stop-Process -Name OneDrive -Force -ErrorAction SilentlyContinue
Start-Process "$env:SystemRoot\System32\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait
Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'OneDrive' -ErrorAction SilentlyContinue
Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'MicrosoftEdgeAutoLaunch_*' -ErrorAction SilentlyContinue
# KEEP a chave SecurityHealth (ícone do Windows Security)
```

### 5.4 Pilha de IA (Recall/Copilot/Click-to-Do) — só Windows 11 (23H2+)

> No Windows 10, pular esta seção (os componentes não existem).

```powershell
# 1) Parar + desativar o host
Stop-Service -Name 'WSAIFabricSvc' -Force -ErrorAction SilentlyContinue
Set-Service -Name 'WSAIFabricSvc' -StartupType Disabled

# 2) Desativar as tarefas WindowsAI (protegidas — rodar como SYSTEM)
#    Salvar o trecho abaixo num .ps1 e rodar via tarefa temporária SYSTEM:
#    (Get-ScheduledTask | ? {$_.TaskPath -like '\Microsoft\Windows\WindowsAI\*'} | % { Disable-ScheduledTask -TaskPath $_.TaskPath -TaskName $_.TaskName })
```

Como rodar como SYSTEM sem ACL (ver pitfall 6):

```powershell
# inner.ps1 contém o loop de Disable-ScheduledTask acima
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\path\inner.ps1"
$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName 'HermesDisableAI' -Action $action -Principal $principal -Force | Out-Null
Start-ScheduledTask -TaskName 'HermesDisableAI'
# esperar terminar, depois:
Unregister-ScheduledTask -TaskName 'HermesDisableAI' -Confirm:$false
```

**NÃO remover** os pacotes `CN=Microsoft Windows` (CoreAI, GUID-named, `61869*.Voiess/Livtop/Speion/InpApp`) — arrisca o Windows Update e quebra ditado/entrada de voz.

### 5.5 Copilot (ocultar + desativar) — só Windows 11

> No Windows 10, pular (não existe Copilot).

```powershell
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowCopilotButton' -Type DWord -Value 0
New-Item -Path 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' -Force | Out-Null
Set-ItemProperty -Path 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' -Name 'TurnOffWindowsCopilot' -Type DWord -Value 1
Stop-Process -Name explorer -Force; Start-Process explorer.exe  # aplica na hora
```

### 5.6 Windows Update automático (política, NÃO o serviço)

```powershell
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Name 'NoAutoUpdate' -Type DWord -Value 1
```

**Não** rodar `Set-Service wuauserv Disabled` (o WaaSMedicSvc reverte — ver pitfall 5). A política bloqueia download+instalação automáticos e o "Check for updates" manual continua funcionando.

⚠️ Avisar o usuário leigo sobre o tradeoff: sem update automático, patches de segurança não se aplicam sozinhos — recomendar checar manualmente de tempos em tempos.

### 5.7 Limpar cache de update pendente (se houver)

```powershell
Stop-Service wuauserv,bits,dosvc,UsoSvc -Force -ErrorAction SilentlyContinue
Remove-Item 'C:\Windows\SoftwareDistribution\Download\*' -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item 'C:\Windows\SoftwareDistribution\DataStore\*' -Recurse -Force -ErrorAction SilentlyContinue
Start-Service bits,wuauserv -ErrorAction SilentlyContinue
```

### 5.8 Microsoft Store (opcional)

```powershell
Get-AppxPackage -Name 'Microsoft.WindowsStore','Microsoft.StorePurchaseApp' -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
# KEEP: Microsoft.DesktopAppInstaller (winget) e Microsoft.Services.Store.Engagement (ver pitfall 10)
```

---

## 6. Verificação

Re-consultar e conferir:
- Apps removidos: `Get-AppxPackage -Name <cada nome>` → nada.
- Serviços desativados: `StartType = Disabled`.
- Hardware preservado: serviços de GPU/áudio/chipset ainda `Running`.
- Toolchain: `git`, `winget`, `rustc`, `cargo`, `java`, `python`, `node` resolvem.
- OneDrive ausente da lista de desinstalação.

---

## 7. Reboot + re-verificação

Pedir ao usuário para reiniciar. Após o reboot, re-rodar a verificação — serviços desativados e apps removidos devem continuar assim (persistência já comprovada). Se algo voltou, foi via Windows Update (que agora está desligado) ou Store (removida).

---

## 7.5 Relatório final — processos e serviços ativos (transparência ao usuário)

> Depois do reboot e da re-verificação (seção 7), apresentar ao usuário um relatório final do que está rodando e POR QUÊ. Objetivo: transparência total — o usuário confirma que nada essencial quebrou e que não sobrou bloat.

O relatório lista todos os processos e serviços ativos, agrupados por categoria, cada um com justificativa de 1 linha:

1. **Núcleo do Windows** — kernel, sessão, shell, busca, RPC/DCOM, log/WMI (essencial, não desliga).
2. **Segurança (Defender)** — antivírus em tempo real, inspeção de rede, central de segurança (essencial).
3. **Hardware / drivers** — CPU/GPU, áudio, touchpad, térmica, energia, hotkeys, Thunderbolt (um processo por peça; KEEP).
4. **Rede** — DHCP/DNS, firewall, Wi-Fi, Bluetooth, VPN, WSL/Hyper-V.
5. **Software do usuário em uso** — navegador, Obsidian, terminal, o próprio agente (some ao fechar).
6. **Serviços de infraestrutura** — agendador, fontes, temas, notificações, compatibilidade, atualização (svchost).

Terminar com uma seção "**O que é opcional**" listando os poucos itens que poderiam ser desligados sem quebrar nada (ex.: `WpnService`/notificações, `SysMain`, `PcaSvc`, telemetria de GPU) — deixando claro que NÃO são bloat e por que ficam.

Como coletar (somente leitura):

```powershell
Get-Process | Group-Object ProcessName | ForEach-Object { $_.Name }
Get-CimInstance Win32_Service | Where-Object { $_.State -eq 'Running' } | Select-Object Name, StartMode
```

> Se o relatório mostrar algo que pareça bloat ainda rodando (Widgets, feed do Iniciar, telemetria), a remoção falhou — voltar à seção 3, re-classificar e pedir aprovação novamente.

---

## 8. Pitfalls (todos já encontrados)

1. **Quoting MSYS**: `$var`/`$_` dentro de aspas duplas no bash viram argumento do comando anterior. Envolver tudo em aspas simples (no git-bash/MSYS).
2. **ProductName mente**: Win11 25H2 reporta "Windows 10 Pro". Usar `DisplayVersion`/`CurrentBuild`.
3. **`DoSvc` (Delivery Optimization)** é protegido: `Set-Service` dá "Access denied". Pular — já fica parado e o Medic reverte qualquer mexida.
4. **Serviços per-user** com sufixo `_<sid>` (ex.: `MessagingService_d438a`) rejeitam `Set-Service` com "parameter incorrect". Pular — já parados.
5. **`wuauserv` + WaaSMedicSvc**: desativar o serviço é revertido silenciosamente pelo Update Medic. Usar a **política** `NoAutoUpdate=1` (não é revertida; é configuração suportada).
6. **Tarefas WindowsAI protegidas**: dono é SYSTEM e Administrators têm write negado → `Disable-ScheduledTask` dá "Acesso negado" para as tarefas "Ready". Rodar o disable como SYSTEM via tarefa temporária (`Register-ScheduledTask` + `Start-ScheduledTask`), sem mexer em ACL.
7. **Apps de sistema** em `C:\Windows\SystemApps` (ex.: `Microsoft.XboxGameCallableUI`) falham com HRESULT `0x80073CFA` "part of Windows". Deixar.
8. **Controle Xbox ≠ Xbox Live**: `XboxGipSvc`/`GameInputSvc` controlam o controle (KEEP). `XblAuthManager`/`XblGameSave`/`XboxNetApiSvc` são cloud/auth/save-sync (desativáveis).
9. **Store ≠ winget**: `Microsoft.DesktopAppInstaller` É o winget (KEEP). `Microsoft.WindowsStore` é a vitrine (removível).
10. **`Microsoft.Services.Store.Engagement`** é dependência do `DolbyLaboratories.DolbyAccess` (e de outros apps OEM de Store) — remover quebra licenciamento. KEEP. Vem em x64 E x86 (dois registros).
11. **Antivírus de terceiros** (McAfee/Norton/Avast) podem bloquear a deleção de arquivos/serviços do guia e reverter/limitar mudanças. Se o usuário quiser removê-los, fazer isso primeiro (ou antes dos passos destrutivos).
12. **NVIDIA**: não confundir o container de display (`NVDisplay.ContainerLocalSystem`, obrigatório) com telemetria (`NvTelemetryContainer`, desativável).
13. **Serviços de licença NÃO são bloat**: `FlexNet Licensing Service`, `Autodesk Desktop Licensing Service`, `Adobe Update Service`, `com.docker.service`, `Steam Client Service` parecem bloat mas são essenciais pro software do usuário funcionar (licença/update/engine). KEEP. Só desativar se o usuário confirmar que não usa mais o software dono daquele serviço.
14. **Chaves de política protegidas**: `HKLM\SOFTWARE\Policies\Microsoft\Dsh` (`AllowNewsAndInterests`) e `...\Windows Feeds` (`EnableFeeds`) negam escrita até para terminal elevado ("Acesso negado"). Para desligar Widgets/feed, remover os pacotes (`Microsoft.WidgetsPlatformRuntime` e `Microsoft.StartExperiencesApp`) em vez de escrever a política — efeito equivalente, sem brigar com ACL.

---

## 9. Rollback

- Ponto de restauração "Pre-debloat" (criado na seção 4).
- CSVs "before" na pasta `~\Documents\windows-debloat-backup\`.
- Reverter Windows Update: apagar a chave `NoAutoUpdate`.
- Reverter Copilot: apagar `ShowCopilotButton` e `TurnOffWindowsCopilot`.
- Reverter IA: `Set-Service WSAIFabricSvc Automatic` + `Enable-ScheduledTask` nas tarefas WindowsAI.
- Reverter Store: re-registrar o provisioned package (mantido na imagem).

---

## 10. Como usar com QUALQUER agente

Este guia é autocontido — funciona passando o texto inteiro como contexto/tarefa para qualquer agente de terminal:

1. **Entrega**: salve este arquivo .md na máquina e dê ao agente como tarefa, com instrução clara, ex.: "Leia este arquivo e execute o debloat seguindo-o do início ao fim. Detecte CPU/GPU primeiro e confirme comigo antes de cada ação destrutiva."
2. **Elevação**: abra o agente num terminal **elevado (admin)** no Windows nativo (não container/WSL). Sem admin, os comandos falham com "acesso negado".
3. **Permissões**: aprove as solicitações de permissão que o agente fizer (cada agente tem seu próprio mecanismo). NÃO rode em modo "auto-aprovar tudo" — o guia pede decisões que dependem do usuário (antivírus, apps de jogo, etc.).
4. **Agentes específicos**:
   - **Hermes Agent**: opcionalmente, copiar também o skill `windows-debloat` para `AppData\Local\hermes\skills\system-administration\windows-debloat\` (há backup no vault em `Backup-Skills-2026-10-18\system-administration\windows-debloat\`).
   - **Claude Code / GitHub Copilot / OpenClaw / Cline / etc.**: não precisam de skill — o guia já contém todos os comandos e listas. Cole o conteúdo como tarefa (ou referencie o arquivo). No Claude Code, pode virar instrução de projeto (CLAUDE.md).
5. **O que NÃO depende do agente**: a decisão de remover antivírus/GeForce Experience/apps de jogo e desligar update automático é SEMPRE do usuário humano — o agente pergunta, o usuário responde.
