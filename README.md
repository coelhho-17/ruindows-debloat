# Windows Debloat — Reusable Guide

[Português](README.pt.md) | English

A complete, validated guide to remove bloat, telemetry and useless apps from Windows (10/11, Home or Pro) **without breaking** drivers, hardware, games or work programs — and fully reversible (CSV backup + restore point).

Works in **two ways**:

- **Manual** (no AI agent): download `debloat-en.ps1` + `debloat-en.bat`, right-click the `.bat` → "Run as administrator" and answer 4 questions. For anyone.
- **With an AI agent**: hand the `Windows-Debloat-Guide.en.md` to a terminal agent (Hermes Agent, Claude Code, GitHub Copilot CLI, Cline, etc.) and it runs, detecting CPU/GPU and asking for approval before each action.

## Manual mode (no AI agent)

The simplest way for anyone who doesn't use an AI agent:

1. Download **both** `debloat-en.ps1` and `debloat-en.bat` **into the same folder** — you need both; the `.bat` alone won't work.
2. **Right-click** `debloat-en.bat` → **"Run as administrator"**. On Windows 11, if it isn't shown directly, use "Show more options" → "Run as administrator". (Double-clicking may not elevate and the script won't run.)
3. In the Windows permission window (**UAC**), click **"Yes"**. If Windows Defender/SmartScreen warns, click "More info" → "Run anyway".
4. Answer the **4 questions** with `Y` or `N`:
   - Remove preinstalled gaming apps (Xbox app, Solitaire, Game Bar)?
   - Remove OneDrive?
   - Remove the Microsoft Store?
   - Disable automatic Windows updates?
5. The script creates a **backup + restore point** before any change, does the cleanup and shows a summary at the end.
6. **Restart the computer** to finish.

What it does (always): removes bloat apps (Bing, Clipchamp, GetHelp, FeedbackHub, Widgets, etc.), disables telemetry/diagnostic services, disables Recall/Copilot/Click-to-Do and clears the Windows Update cache. The items in the 4 questions only happen if you answer `Y`.

Nothing is irreversible: the backup is in `Documents\windows-debloat-backup\` and there is a "Pre-debloat (manual)" restore point.

## Mode with an AI agent

1. Save `Windows-Debloat-Guide.en.md` somewhere easy (Downloads or Documents).
2. Open your AI assistant **as Administrator**.
3. Paste the instruction block at the top of the guide and follow it — it analyzes, shows a report and waits for your "yes" before changing anything.

## Results (on my machine)

ThinkPad · Windows 11 Pro · 32 GB RAM — session of 2026-10-18:

- **29 apps** removed (UWP) — from 125 to 96
- **20 services** disabled (telemetry, diagnostics, Xbox Live cloud, NFC/payment/messaging, AI host)
- **OneDrive** removed (app + auto-start)
- **2.8 GB** of Windows Update cache freed
- AI stack disabled (Recall/Copilot/Click-to-Do) + Copilot off + automatic updates off

State after debloat: 203 processes · 114 services running · 7.6 GB of 31.7 GB RAM in use.

## Warning

Touching system services and apps carries risk. The guide and the script were validated on 2 machines (ThinkPad Intel/Win11 Pro and desktop AMD + RTX 3060/Win11 Home) and are reversible (CSV backup + restore point), but use at your own risk. In agent mode, review each item of the report before approving.
