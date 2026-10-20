# Windows Debloat — Reusable Guide (any terminal agent)

> **No AI agent?** Use the manual mode: download `debloat-en.ps1` + `debloat-en.bat` from the repository **into the same folder** and **right-click** `debloat-en.bat` → **"Run as administrator"** (don't double-click). This guide below is for when you use an AI agent.

---

## HOW TO USE (3 steps)

**What this does:** cleans Windows — removes junk, telemetry and useless apps and turns off automatic updates — **without breaking** drivers, games, controller or programs. It is reversible (you can go back).

1. **Save this file** somewhere easy (Downloads or Documents). Remember where you saved it.
2. **Open your AI assistant as Administrator** (right-click the program icon → "Run as administrator"). Without this, the cleanup fails.
3. **Copy the block below and paste it into the assistant.** It first analyzes the PC and shows a REPORT of what it intends to remove/disable — each item with the why — and STOPS for you to approve. Nothing is changed before your "yes". After your approval, it runs and, at the end, asks you to restart the PC — restart and you're done.

```text
You are going to "debloat" my Windows: clean bloat, telemetry and useless apps WITHOUT breaking drivers, hardware, games or programs.

1. Find and read the file "Windows-Debloat-Guide.en.md" (look in Downloads, Documents or Desktop; if you can't find it, ask me where I saved it) and follow it from start to finish.
2. Before anything, detect my CPU and GPU and the programs I use (Steam, AutoCAD, VS Code, Adobe, etc.) — and only then decide what to remove/disable. NEVER remove or disable anything tied to programs I use for work, creating or gaming.
3. Check if you are running as Administrator. If not, tell me so I can reopen the terminal as Administrator.
4. After detecting CPU/GPU and classifying everything, present a REPORT of what you intend to remove/disable (each item with a justification) and STOP for me to approve. Only execute after I confirm "yes". Do NOT change anything before my approval.
5. Do NOT remove drivers, audio, chipset, GPU, Wi-Fi, my Xbox controller, or the programs I use for work/gaming/creating (Steam, AutoCAD, VS Code, Adobe, etc.). Do not uninstall antivirus without asking me first.
6. At the end, tell me exactly what was done, present a report of the processes/services that remained active (and the why of each) and ask me to restart the PC.

Do the full debloat following the guide.
```

---

> Definitive guide to reproduce the Windows debloat on ANY PC — desktop or laptop, any CPU/GPU and any edition (Windows 10/11, Home or Pro).
> Works with ANY AI agent that has access to a terminal/shell and runs on elevated (admin) Windows: Hermes Agent, Claude Code, GitHub Copilot (CLI), OpenClaw, Cline, etc. The guide is self-contained and does not depend on any agent-specific skill/plugin.
> Validated on 2 machines: ThinkPad Intel/Win11 Pro (dev) and desktop AMD Ryzen + NVIDIA RTX 3060/Win11 Home (gamer).
> Run top to bottom. Before any destructive step, do recon + backup. Nothing here is irreversible — everything has a rollback.

---

## Minimum agent requirements (read before anything)

For an agent to run this guide, it needs THREE things. Without them, the guide does not work:

1. **Terminal/shell access** — the agent must be able to run PowerShell commands. An assistant that only replies with text (no command-execution tool) cannot do ANYTHING here.
2. **ELEVATED (admin) terminal** — without administrator privileges, ~80% of the guide fails with "access denied" (removing apps, disabling services, writing to HKLM). The user needs to OPEN the agent "as Administrator". There is an elevation-check command in step 0.
3. **Interactive session** — the guide requires presenting a report/plan (section 3.5) and getting the user's explicit approval before executing. In a non-interactive run (cron, CI, automatic script) there is no way to approve; in that case, the agent must produce ONLY the report and stop (or apply only the 100% safe steps, if the context allows).

> If the agent runs inside a container/WSL instead of native Windows, the PowerShell commands do not reach the real Windows system — the guide needs to run on native Windows.

---

## 0. Principles (read before anything)

1. Goal: remove consumer/telemetry bloat **preserving** drivers, hardware, gaming features and the dev toolchain.
2. **Never blindly remove** a package with an obscure name. Check `Publisher` first: if it is `CN=Microsoft Windows`, it is a system component (AI/voice/input), not bloat.
3. **Never touch** DRIVERS and hardware services (GPU, audio, chipset, touchpad, thermal, power). Careful: "OEM" is not a synonym for bloat — an OEM utility that controls hardware (Lenovo Vantage, Armoury Crate) is KEEP; a consumer OEM app (McAfee, SupportAssist) is REMOVE. See section 3.
4. **Always create a rollback before**: export before-state CSVs + a restore point.
5. **Shell**: each agent runs in a different shell on Windows — git-bash/MSYS (Hermes, Claude Code), PowerShell, cmd or WSL. The commands in this guide are PowerShell; the agent must adapt the syntax to the shell it is in:
   - **git-bash/MSYS**: wrap PowerShell commands in **single quotes** at the bash level (MSYS expands `$var`/`$_` inside double quotes).
   - **Pure PowerShell**: run the commands directly (without `powershell.exe -Command`), minding `$`.
   - **WSL**: call via `powershell.exe` (the Windows PowerShell, not the WSL one).
   Example (git-bash/MSYS):
   ```bash
   powershell.exe -NoProfile -Command 'Get-Service DiagTrack | Select-Object Name,Status,StartType'
   ```
6. **Elevation**: check admin before any destructive step:
   ```powershell
   ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
   ```
   If it returns `False`, open an elevated terminal (in Claude Code: close and reopen the terminal as Administrator).
7. **Windows version** comes from `DisplayVersion`/`CurrentBuild`, NOT from `ProductName` (the registry still says "Windows 10 Pro" on Win11 25H2):
   ```powershell
   Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' | Select-Object DisplayVersion,CurrentBuild
   ```
8. **Lay user + prior approval**: the PC owner may not understand the terms. Explain each decision in simple language. Before any destructive step, present the **full plan (section 3.5)** and wait for the "yes". The user also needs to APPROVE the permissions the agent itself asks for (each agent has its own allow/deny mechanism — Claude Code, Copilot, etc.). Do not use "auto-approve everything" mode.
9. **Never break the user's work**: detect what the user USES (dev, CAD, design, photo/video, gaming) and NEVER remove/disable software or a service tied to it. Work/creation/gaming software is NOT bloat — only what is not tied to anything the user uses (trial, marketing OEM, promotion) is bloat. When in doubt, KEEP and ask.

---

## 1. How to adapt to ANY hardware (not just the gaming PC)

The guide was validated on 2 quite different machines (ThinkPad Intel/Win11 Pro and desktop AMD+NVIDIA/Win11 Home). The secret to working on any PC: **detect CPU and GPU first and classify according to what exists** — never apply another machine's list blindly.

Hardware rules (apply according to what is detected):

- **Intel CPU** (very common in laptops): preserve Intel services — audio `IntelAudioService`, thermal `esifsvc`/`LITSSVC` (on OEMs like Lenovo/Dell/HP), chipset. On Dell/HP/Lenovo laptops there are specific OEM services (e.g. `IBMPMSVC`, `TPHKLOAD`, `LenovoSmartStandby` on Lenovo) — preserve.
- **AMD CPU** (Ryzen): preserve AMD chipset (`AMDRyzenMasterDriver` if Ryzen Master is installed), AMD crash-defender. Ignore the Intel services (they don't exist).
- **NVIDIA GPU**: mandatory KEEP `NVDisplay.ContainerLocalSystem` + `NvContainerLocalSystem` (display containers — essential). Disableable `NvTelemetryContainer` (telemetry) if not using GeForce Experience. `GeForce Experience` (Win32 app) is optional bloat — ask first (some use it for driver/recording).
- **AMD GPU (Radeon)** or **Intel GPU (Arc/HD/UHD)**: preserve the GPU driver/software; equivalent telemetry disableable if present (AMD has "User Experience" telemetry).
- **Audio**: always KEEP `Audiosrv` + audio driver (Realtek `RtkAudioUniversalService`, Dolby `DolbyDAXAPI`/`DolbyLaboratories.DolbyAccess`, or the manufacturer's).
- **Windows Home vs Pro**: no difference in the procedure — the registry policy keys (NoAutoUpdate, Copilot) work on both. Home has no `gpedit.msc`, but the guide uses the registry, so it doesn't matter.
- **Windows 10 vs 11**: the AI-stack (5.4) and Copilot (5.5) steps only apply to Windows 11 (23H2+). On Windows 10, those components do not exist — skip. Everything else applies to both.
- **Gaming use**: if it is a gaming PC, do NOT go removing Xbox/Game Bar. **Ask first** about the Xbox app, Game Bar, Game Pass. Safe to disable even on a gamer: `XblAuthManager`/`XblGameSave`/`XboxNetApiSvc` (cloud/auth/save-sync). **Always KEEP** `XboxGipSvc` + `GameInputSvc` (Xbox controller via Bluetooth/USB).
- **Consumer laptop**: extra attention to third-party/OEM bloat (McAfee, Norton, antivirus trial, Dell/HP/Asus/Lenovo apps) — see section 3 (REMOVE).

---

## 2. Diagnostics (recon — read-only, run in parallel)

> ⚠️ **Mandatory first step: detect CPU, GPU and the USER profile (what they use).** Every debloat decision depends on the hardware AND the software the user actually uses. Only after knowing CPU, GPU and which programs they have (Steam, AutoCAD, VS Code, Adobe, etc.) do you classify any item.

```powershell
# 1) CPU and GPU — ALWAYS the first command (the debloat decision depends on this)
Get-CimInstance Win32_Processor | Select-Object Name,Manufacturer
Get-CimInstance Win32_VideoController | Select-Object Name,AdapterCompatibility,DriverVersion

# Real Windows version
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' | Select-Object DisplayVersion,CurrentBuild

# Installed UWP apps
Get-AppxPackage | Select-Object Name,Publisher,Version

# Services
Get-Service | Select-Object Name,Status,StartType

# Win32 programs (uninstall registry — fast signal of how much real junk exists)
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*','HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName } | Select-Object DisplayName,Publisher

# Startup items
Get-CimInstance Win32_StartupCommand | Select-Object Name,Command,Location
```

Then, based on the hardware (CPU/GPU) and the Win32 programs found, identify the **USER profile**: developer (VS Code/Visual Studio/JetBrains/Docker/Git), CAD (AutoCAD/Fusion 360/SolidWorks/Inventor), design (Adobe/Figma/Corel), photo/video (Photoshop/Premiere/DaVinci/OBS/Blender), gamer (Steam/Epic/GOG/Battle.net). Anything that is the user's work/creation/gaming software is KEEP (see section 3). Only then classify each item into REMOVE / DISABLE / KEEP.

---

## 3. Classification lists

> The classification depends on the CPU/GPU detected in step 2. Apply only the lists that match the real hardware. NEVER apply another machine's hardware list without checking what exists here.

### KEEP (drivers / hardware / frameworks / toolchain / gaming)

- **NVIDIA GPU**: `NVDisplay.ContainerLocalSystem`, `NvContainerLocalSystem`, `NVIDIA Display Container LS`.
- **AMD GPU**: Radeon/Adrenalin driver + associated service.
- **Intel GPU**: `igfxCUIService`/`IntelGraphicsSoftwareService` (if present).
- **AMD chipset**: `AMDRyzenMasterDriver` (if Ryzen Master installed), AMD chipset services.
- **Intel chipset / OEM thermal**: `esifsvc`, `LITSSVC`, `IBMPMSVC`, `LenovoSmartStandby`, `TPHKLOAD` (Lenovo), Dell/HP equivalents.
- **Audio**: `Audiosrv`, Realtek (`RtkAudioUniversalService`), Dolby (`DolbyDAXAPI`/`DolbyLaboratories.DolbyAccess`).
- **Network**: `WlanSvc`, `Dhcp`, `Dnscache`, `mpssvc` (applies to Wi-Fi and Ethernet).
- **Windows Update**: `wuauserv`, `UsoSvc`, `WaaSMedicSvc` (do not disable — see section 5.6).
- **Defender**: `WinDefend`, `WdNisSvc`, `SecurityHealthService`, `wscsvc`.
- **Xbox controller**: `XboxGipSvc`, `GameInputSvc`.
- **winget**: `Microsoft.DesktopAppInstaller` (a package separate from the Store — never remove).
- **Useful apps**: Terminal, Calculator, Notepad, Paint, codecs (HEIF/HEVC/AV1/VP9/WebMedia), frameworks (VCLibs, UI.Xaml, .NET Native, WindowsAppRuntime), WindowsSubsystemForLinux, WebView2.
- **OEM hardware utility** (controls RGB/fan/hotkeys): Lenovo Vantage, Asus Armoury Crate, etc. — ask before removing.

### KEEP (the user's PROFESSIONAL software and services — NEVER remove)

Identify from recon (step 2) what the user uses and preserve the software AND its services/support frameworks:

- **Dev**: VS Code, Visual Studio, JetBrains (IntelliJ/PyCharm/Rider), Docker Desktop (+ `com.docker.service`), WSL, Git, Node, Python, Java/JDK, .NET, databases (PostgreSQL/MySQL/SQL Server and their services), Android Studio, Unity/Unreal.
- **CAD/Engineering**: AutoCAD, Fusion 360, SolidWorks, Inventor, Revit, SketchUp, CATIA — and their license services (`FlexNet Licensing Service`, `Autodesk Desktop Licensing Service`, `AdAppMgrSvc`/Autodesk Desktop App). NEVER disable a license service (FlexNet/Autodesk) — without it the software stops opening.
- **Design**: Adobe Creative Cloud (Photoshop/Illustrator/InDesign) + `Adobe Update Service`/Creative Cloud, Figma, CorelDRAW, Affinity.
- **Photo/Video**: Lightroom, Premiere, DaVinci Resolve, OBS Studio, Blender, Capture One, Vegas. (They depend on the GPU — which is why GPU drivers/containers are KEEP.)
- **Gaming**: Steam (+ `Steam Client Service`), Epic Games, GOG Galaxy, Battle.net, Riot, Xbox app/Game Pass (if the user uses them), Discord.
- **General rule**: a service or app that belongs to software the user USES is KEEP. It is only bloat if it is NOT tied to anything they use (expired trial, marketing OEM, promotion).

### REMOVE (consumer UWP bloat — safe)

- Gaming (only if the user agrees): `Microsoft.GamingApp`, `Microsoft.MicrosoftSolitaireCollection`, `Microsoft.Xbox.TCUI`, `Microsoft.XboxGamingOverlay`, `Microsoft.XboxIdentityProvider`, `Microsoft.XboxSpeechToTextOverlay`.
- Bing: `Microsoft.BingNews`, `Microsoft.BingSearch`, `Microsoft.BingWeather`.
- Consumer: `Clipchamp.Clipchamp`, `Microsoft.GetHelp`, `Microsoft.Todos`, `Microsoft.WindowsFeedbackHub`, `Microsoft.WindowsCamera`, `Microsoft.WindowsSoundRecorder`, `Microsoft.WindowsAlarms`, `Microsoft.YourPhone`, `Microsoft.OutlookForWindows`, `Microsoft.PowerAutomateDesktop`, `Microsoft.Windows.DevHome`, `MicrosoftCorporationII.QuickAssist`, `MSTeams`, `MicrosoftWindows.Client.WebExperience` (Widgets), `MicrosoftWindows.CrossDevice`, `Microsoft.OneDriveSync`.
- Remaining Widgets/feed (they stay as orphans running processes even after WebExperience leaves): `Microsoft.WidgetsPlatformRuntime` (Widgets engine — runs `WidgetService`) and `Microsoft.StartExperiencesApp` (the Start menu "My Feed"/news — runs `MicrosoftStartFeedProvider`). Removing both does NOT break the Start menu (the Start menu itself is `Microsoft.Windows.StartMenuExperienceHost`, which is KEEP).

### REMOVE (third-party/OEM bloat — Win32, common on consumer laptops)

They appear in the Win32 uninstall list (recon step 2) with `Publisher` = Dell/HP/Lenovo/Asus/Acer/McAfee/Norton/etc. **Confirm with the user first** (antivirus is their decision):

- **Trial antivirus/cleanup**: McAfee (LiveSafe, Security Scan Plus, WebAdvisor), Norton (trial), Avast/AVG (and "Cleanup"), PC App Store, preinstalled Chromium.
- **Consumer/support OEM apps**: Dell SupportAssist, HP Support Assistant, MyASUS, Acer Care Center, promotions/trials (preinstalled Office/Spotify/Netflix).
- **Rule (conservative)**: remove ONLY what is clearly consumer bloat — trial antivirus, OEM support/marketing apps, preinstalled promotions. **NEVER remove software the user uses to work/create/game** (VS Code, Visual Studio, Docker, AutoCAD, Fusion, Adobe, Steam, Epic, etc.). When in doubt, do NOT remove and ASK. Third-party antivirus can also BLOCK the execution of this guide's scripts (file/service deletion) — if you are going to remove it, remove the antivirus first, or the guide may fail with "access denied" where it shouldn't.

### DISABLE (services — safe)

- Telemetry: `DiagTrack`, `dmwappushservice`, `InventorySvc`, `wisvc`.
- Diagnostics: `WdiSystemHost`, `WdiServiceHost`.
- Xbox Live cloud: `XblAuthManager`, `XblGameSave`, `XboxNetApiSvc`.
- NFC/payment/messaging: `SEMgrSvc`, `WalletService`, `PhoneSvc`, `SmsRouter`.
- Others: `WMPNetworkSvc`, `RetailDemo`, `MapsBroker`, `TrkWks`, `lmhosts`, `lfsvc`. (TrkWks/lmhosts are legacy — safe on a home PC; if the PC is on a corporate domain, skip those two.)
- NVIDIA telemetry (if not using GFE): `NvTelemetryContainer`.

### DO NOT touch (system components — not bloat)

- Packages with a GUID name (`1527c705-...` etc.) and `MicrosoftWindows.61869XXX.*` signed `CN=Microsoft Windows` (AI/voice/input stack).
- `MicrosoftWindows.Client.CoreAI`, `MicrosoftWindows.Client.Core`, `MicrosoftWindows.Client.FileExp`, etc.

---

## 3.5 Debloat plan — report + user APPROVAL (mandatory, before executing)

> ⚠️ **MANDATORY CHECKPOINT.** After recon (section 2) and classification (section 3), the agent does NOT execute anything yet. First it builds a report/plan, presents it to the user and WAITS for explicit approval. Only after the "yes" does it move to backup (section 4) and execution (section 5).

The report must be in simple language (the PC owner may be a lay person) and contain, at minimum:

1. **Detected hardware and profile** (1-2 lines): CPU, GPU and what the user uses (dev, CAD, design, photo/video, gamer).
2. **What will be REMOVED** — a list, each item with a 1-line justification (why it is bloat).
3. **What will be DISABLED** — services/tasks, each with a justification.
4. **What stays even though it looks like bloat** — drivers, license services (FlexNet/Autodesk/Adobe), GPU, Xbox controller, WebView2, system components ("DO NOT touch"). So the user understands why it stays.
5. **Decisions that depend on the user** — explicit questions, one per line: third-party antivirus, GeForce Experience/NVIDIA, gaming apps (Xbox app, Game Bar, Game Pass), OneDrive, turn off automatic updates, remove the Store.

After presenting, **stop and ask**: "Do you approve this plan? Answer yes, no, or tell me which items to change."

Rules:

- **Do not execute anything destructive** (remove an app, disable a service, touch the registry) before the user's "yes". The backup (section 4) is only read/export + restore point and can be done before; execution (section 5) only after approval.
- If the user says "no" or asks for adjustments, **revise the plan** and re-present.
- In non-interactive mode (cron/CI, no way to ask): **do not execute** what requires a decision — produce only the report and stop.

> Why: the debloat is reversible, but each action touches something that may be the user's work/creation/game. An informed "yes" before touching anything gives the user full control over what happens on their PC.

---

## 4. Backup + rollback (before any action)

```powershell
# Export before-state
Get-AppxPackage | Export-Csv -Path "$env:USERPROFILE\Documents\windows-debloat-backup\appx-before.csv" -NoTypeInformation
Get-Service | Export-Csv -Path "$env:USERPROFILE\Documents\windows-debloat-backup\services-before.csv" -NoTypeInformation
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' | Export-Csv -Path "$env:USERPROFILE\Documents\windows-debloat-backup\win32-programs-before.csv" -NoTypeInformation

# Restore point (if it fails with "service disabled", enable it first)
Enable-ComputerRestore -Drive "C:\"
Checkpoint-Computer -Description "Pre-debloat" -RestorePointType MODIFY_SETTINGS
```

---

## 5. Execution

> ⚠️ Only run this section AFTER the user's explicit approval of the plan (section 3.5).

### 5.1 Remove UWP apps (per-user + provisioned)

```powershell
$removed = @('Microsoft.GamingApp','Microsoft.BingNews','Clipchamp.Clipchamp', ...)  # full list from the REMOVE section
foreach ($name in $removed) {
  Get-AppxPackage -Name $name -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
  Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like "$name*" } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}
```

### 5.2 Disable services

```powershell
$disabled = @('DiagTrack','dmwappushservice','InventorySvc','wisvc', ...)  # list from the DISABLE section
foreach ($s in $disabled) {
  Set-Service -Name $s -StartupType Disabled -ErrorAction SilentlyContinue
  Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
}
```

### 5.3 OneDrive + Edge auto-launch

> ⚠️ ASK first: if the user uses OneDrive for sync/backup (photos, documents, projects), do NOT remove it — many designers/photographers depend on it. Only remove if the user confirms they don't use it.

```powershell
Stop-Process -Name OneDrive -Force -ErrorAction SilentlyContinue
Start-Process "$env:SystemRoot\System32\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait
Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'OneDrive' -ErrorAction SilentlyContinue
Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'MicrosoftEdgeAutoLaunch_*' -ErrorAction SilentlyContinue
# KEEP the SecurityHealth key (Windows Security tray icon)
```

### 5.4 AI stack (Recall/Copilot/Click-to-Do) — Windows 11 only (23H2+)

> On Windows 10, skip this section (the components do not exist).

```powershell
# 1) Stop + disable the host
Stop-Service -Name 'WSAIFabricSvc' -Force -ErrorAction SilentlyContinue
Set-Service -Name 'WSAIFabricSvc' -StartupType Disabled

# 2) Disable the WindowsAI tasks (protected — run as SYSTEM)
#    Save the snippet below into a .ps1 and run it via a temporary SYSTEM task:
#    (Get-ScheduledTask | ? {$_.TaskPath -like '\Microsoft\Windows\WindowsAI\*'} | % { Disable-ScheduledTask -TaskPath $_.TaskPath -TaskName $_.TaskName })
```

How to run as SYSTEM without an ACL fight (see pitfall 6):

```powershell
# inner.ps1 contains the Disable-ScheduledTask loop above
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\path\inner.ps1"
$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName 'HermesDisableAI' -Action $action -Principal $principal -Force | Out-Null
Start-ScheduledTask -TaskName 'HermesDisableAI'
# wait for it to finish, then:
Unregister-ScheduledTask -TaskName 'HermesDisableAI' -Confirm:$false
```

**Do NOT remove** the `CN=Microsoft Windows` packages (CoreAI, GUID-named, `61869*.Voiess/Livtop/Speion/InpApp`) — it risks Windows Update servicing and can break voice typing/dictation.

### 5.5 Copilot (hide + disable) — Windows 11 only

> On Windows 10, skip (no Copilot).

```powershell
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowCopilotButton' -Type DWord -Value 0
New-Item -Path 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' -Force | Out-Null
Set-ItemProperty -Path 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' -Name 'TurnOffWindowsCopilot' -Type DWord -Value 1
Stop-Process -Name explorer -Force; Start-Process explorer.exe  # applies immediately
```

### 5.6 Automatic Windows Update (policy, NOT the service)

```powershell
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Name 'NoAutoUpdate' -Type DWord -Value 1
```

**Do not** run `Set-Service wuauserv Disabled` (WaaSMedicSvc reverts it — see pitfall 5). The policy blocks automatic download+install and the manual "Check for updates" still works.

⚠️ Warn the lay user about the tradeoff: without automatic updates, security patches don't apply by themselves — recommend checking manually from time to time.

### 5.7 Clear pending update cache (if any)

```powershell
Stop-Service wuauserv,bits,dosvc,UsoSvc -Force -ErrorAction SilentlyContinue
Remove-Item 'C:\Windows\SoftwareDistribution\Download\*' -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item 'C:\Windows\SoftwareDistribution\DataStore\*' -Recurse -Force -ErrorAction SilentlyContinue
Start-Service bits,wuauserv -ErrorAction SilentlyContinue
```

### 5.8 Microsoft Store (optional)

```powershell
Get-AppxPackage -Name 'Microsoft.WindowsStore','Microsoft.StorePurchaseApp' -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
# KEEP: Microsoft.DesktopAppInstaller (winget) and Microsoft.Services.Store.Engagement (see pitfall 10)
```

---

## 6. Verification

Re-query and check:
- Removed apps: `Get-AppxPackage -Name <each name>` → nothing.
- Disabled services: `StartType = Disabled`.
- Preserved hardware: GPU/audio/chipset services still `Running`.
- Toolchain: `git`, `winget`, `rustc`, `cargo`, `java`, `python`, `node` resolve.
- OneDrive absent from the uninstall list.

---

## 7. Reboot + re-verification

Ask the user to restart. After the reboot, re-run the verification — disabled services and removed apps should stay that way (persistence already proven). If something came back, it was via Windows Update (now off) or the Store (removed).

---

## 7.5 Final report — active processes and services (transparency to the user)

> After the reboot and re-verification (section 7), present the user a final report of what is running and WHY. Goal: full transparency — the user confirms nothing essential broke and no bloat remains.

The report lists all active processes and services, grouped by category, each with a 1-line justification:

1. **Windows core** — kernel, session, shell, search, RPC/DCOM, log/WMI (essential, do not turn off).
2. **Security (Defender)** — real-time antivirus, network inspection, security center (essential).
3. **Hardware / drivers** — CPU/GPU, audio, touchpad, thermal, power, hotkeys, Thunderbolt (one process per piece; KEEP).
4. **Network** — DHCP/DNS, firewall, Wi-Fi, Bluetooth, VPN, WSL/Hyper-V.
5. **User software in use** — browser, Obsidian, terminal, the agent itself (goes away when closed).
6. **Infrastructure services** — scheduler, fonts, themes, notifications, compatibility, update (svchost).

End with an "**What is optional**" section listing the few items that could be turned off without breaking anything (e.g. `WpnService`/notifications, `SysMain`, `PcaSvc`, GPU telemetry) — making clear they are NOT bloat and why they stay.

How to collect (read-only):

```powershell
Get-Process | Group-Object ProcessName | ForEach-Object { $_.Name }
Get-CimInstance Win32_Service | Where-Object { $_.State -eq 'Running' } | Select-Object Name, StartMode
```

> If the report shows something that still looks like running bloat (Widgets, Start feed, telemetry), the removal failed — go back to section 3, re-classify and ask for approval again.

---

## 8. Pitfalls (all already encountered)

1. **MSYS quoting**: `$var`/`$_` inside double quotes in bash become the previous command's argument. Wrap everything in single quotes (in git-bash/MSYS).
2. **ProductName lies**: Win11 25H2 reports "Windows 10 Pro". Use `DisplayVersion`/`CurrentBuild`.
3. **`DoSvc` (Delivery Optimization)** is protected: `Set-Service` gives "Access denied". Skip it — it stays stopped anyway and the Medic reverts any tampering.
4. **Per-user services** with a `_<sid>` suffix (e.g. `MessagingService_d438a`) reject `Set-Service` with "parameter incorrect". Skip — already stopped.
5. **`wuauserv` + WaaSMedicSvc**: disabling the service is silently reverted by Update Medic. Use the **policy** `NoAutoUpdate=1` (not reverted; it is a supported configuration).
6. **Protected WindowsAI tasks**: owner is SYSTEM and Administrators are denied write → `Disable-ScheduledTask` gives "Access denied" for the "Ready" tasks. Run the disable as SYSTEM via a temporary task (`Register-ScheduledTask` + `Start-ScheduledTask`), without touching ACLs.
7. **System apps** under `C:\Windows\SystemApps` (e.g. `Microsoft.XboxGameCallableUI`) fail with HRESULT `0x80073CFA` "part of Windows". Leave them.
8. **Xbox controller ≠ Xbox Live**: `XboxGipSvc`/`GameInputSvc` drive the controller (KEEP). `XblAuthManager`/`XblGameSave`/`XboxNetApiSvc` are cloud/auth/save-sync (disableable).
9. **Store ≠ winget**: `Microsoft.DesktopAppInstaller` IS winget (KEEP). `Microsoft.WindowsStore` is the storefront (removable).
10. **`Microsoft.Services.Store.Engagement`** is a dependency of `DolbyLaboratories.DolbyAccess` (and other OEM Store apps) — removing it breaks licensing. KEEP. It ships as both x64 AND x86 (two entries).
11. **Third-party antivirus** (McAfee/Norton/Avast) can block the guide's file/service deletions and revert/limit changes. If the user wants to remove them, do it first (or before the destructive steps).
12. **NVIDIA**: do not confuse the display container (`NVDisplay.ContainerLocalSystem`, mandatory) with telemetry (`NvTelemetryContainer`, disableable).
13. **License services are NOT bloat**: `FlexNet Licensing Service`, `Autodesk Desktop Licensing Service`, `Adobe Update Service`, `com.docker.service`, `Steam Client Service` look like bloat but are essential for the user's software to work (license/update/engine). KEEP. Only disable if the user confirms they no longer use the software that owns that service.
14. **Protected policy keys**: `HKLM\SOFTWARE\Policies\Microsoft\Dsh` (`AllowNewsAndInterests`) and `...\Windows Feeds` (`EnableFeeds`) deny writes even to an elevated terminal ("Access denied"). To turn off Widgets/feed, remove the packages (`Microsoft.WidgetsPlatformRuntime` and `Microsoft.StartExperiencesApp`) instead of writing the policy — same effect, no ACL fight.

---

## 9. Rollback

- "Pre-debloat" restore point (created in section 4).
- "Before" CSVs in the `~\Documents\windows-debloat-backup\` folder.
- Revert Windows Update: delete the `NoAutoUpdate` key.
- Revert Copilot: delete `ShowCopilotButton` and `TurnOffWindowsCopilot`.
- Revert AI: `Set-Service WSAIFabricSvc Automatic` + `Enable-ScheduledTask` on the WindowsAI tasks.
- Revert Store: re-register the provisioned package (kept in the image).

---

## 10. How to use with ANY agent

This guide is self-contained — it works by passing the entire text as context/task to any terminal agent:

1. **Delivery**: save this .md file on the machine and give it to the agent as a task, with a clear instruction, e.g. "Read this file and run the debloat following it from start to finish. Detect CPU/GPU first and confirm with me before each destructive action."
2. **Elevation**: open the agent in an **elevated (admin) terminal** on native Windows (not container/WSL). Without admin, the commands fail with "access denied".
3. **Permissions**: approve the permission requests the agent makes (each agent has its own mechanism). Do NOT run in "auto-approve everything" mode — the guide asks for decisions that depend on the user (antivirus, gaming apps, etc.).
4. **Specific agents**:
   - **Hermes Agent**: optionally, also copy the `windows-debloat` skill to `AppData\Local\hermes\skills\system-administration\windows-debloat\` (there is a backup in the vault at `Backup-Skills-2026-10-18\system-administration\windows-debloat\`).
   - **Claude Code / GitHub Copilot / OpenClaw / Cline / etc.**: no skill needed — the guide already contains all commands and lists. Paste the content as a task (or reference the file). In Claude Code, it can become a project instruction (CLAUDE.md).
5. **What does NOT depend on the agent**: the decision to remove antivirus/GeForce Experience/gaming apps and to turn off automatic updates is ALWAYS the human user's — the agent asks, the user answers.
