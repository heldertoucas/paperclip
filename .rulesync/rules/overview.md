---
last_verified: 2026-07-21
project: paperclip
tags: [ia, gestao, paperclip]
domain: system
---

# Project Instructions: paperclip

## Product Vision
Ultra-lightweight Windows capture utility for the obsidian-ht Second Brain ecosystem — AHK v2 hotkey-based note capture.

## Tech Stack
- **Language**: AutoHotkey (AHK) v2.0
- **Monitor**: PowerShell (`monitor_perf.ps1` → `perf_log.txt`)
- **Platform**: Windows only

## Architecture
- **Structure**: AHK scripts compiled/executed on Windows
- **Key Directories**: `win/` (Windows logic), `mac/` (macOS variant)
- **Key Pattern**: Hotkey-triggered capture → write to `home/00-inbox/pc/`

## Build & Run Commands
- **Run**: Execute `.ahk` scripts directly with AutoHotkey v2
- **Monitor**: `powershell .\monitor_perf.ps1` (logs RAM to `perf_log.txt`)
- **Test**: Manual — test global hotkeys (`Ctrl+Shift+Space`), smart paste (`Ctrl+Alt+V`), tab switching

## Code Standards
- Write destination: `home/00-inbox/pc/` only — no files outside app dir and mapped vault
- RAM budget: stable at ~19MB. Audit memory after changes to `win/` or `mac/`
- OpenSpec workflow for architecture changes

## Quality Gates
- Hotkey behavior: capture, smart paste, tab switching all functional
- `monitor_perf.ps1` confirms no memory leaks after changes
- RAM stable at ~19MB

> Note: Memory Protocol and Global Rules are inherited from the global AGENTS.md.
