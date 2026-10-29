# Change Proposal: Reboot Paperclip v2 (On-Demand Inbox Manager & Capture Utility)

## Why
Paperclip was decommissioned on 2026-09-11 (DEC-0019) to eliminate an unmonitored resident daemon. However, quick keyboard-driven capture remains an essential daily workflow for the obsidian-ht Second Brain.

This change reboots Paperclip as a lean, dual-component system:
1. **Desktop Client (`win/paperclip.ahk`)**: An ultra-lightweight AutoHotkey v2 desktop app (~5-7 MB RAM) providing a persistent System Tray icon, global hotkey (`Ctrl+Shift+Space`), file shortcut invocation, an Inbox folder TreeView (for browsing and editing existing notes), and instant note/task staging.
2. **Decoupled Sync Engine (`sync/telegram_sync.py`)**: A standalone Python script (0 MB idle RAM) running on a schedule (Windows Task Scheduler) or on-demand from the Paperclip tray menu to pull notes from a Telegram Bot into atomic inbox files.

## What Changes

### 1. Dual-Component Architecture
- **Desktop Client (`win/paperclip.ahk`)**:
  - **Triggers**: Global Hotkey (`Ctrl+Shift+Space`), desktop/taskbar shortcut (`.lnk`), and interactive System Tray icon with right-click context menu.
  - **Two-Pane Explorer UI**:
    - Left pane: `SysTreeView32` displaying all markdown files in the Vault Inbox (`Dev/home/00-inbox/`).
    - Right pane: Multi-line editor displaying selected notes or blank template for new captures.
  - **Use Case A (Atomic Scratchpad)**: Capture quick copy-paste notes into individual atomic files (`YYYYMMDD-HHmmss-pc.md`) in `00-inbox/`.
  - **Use Case C (Project Task Staging)**: Capture quick project-linked notes and checklist items into `00-inbox/project-notes.md`, grouped by project (`## [[PRJ-XXXX|Project]]`) and date (`### YYYY-MM-DD`).
- **Telegram Sync Engine (`sync/telegram_sync.py`)**:
  - **Use Case B (Telegram Ingest)**: Pulls messages from the Telegram Bot API via `getUpdates` with offset tracking.
  - Emits atomic markdown notes (`YYYYMMDD-HHmmss-tg.md`) directly into `00-inbox/`.
  - Fully decoupled: scheduled via Windows Task Scheduler or invoked on-demand via the Paperclip tray menu / toolbar button without keeping a persistent Python process alive.

## Capabilities

### New Capabilities
- `inbox-treeview`: Browse, select, and edit existing notes inside `00-inbox/` directly within Paperclip.
- `project-task-staging`: Append project-scoped tasks and observations to `00-inbox/project-notes.md` grouped by project and day.
- `telegram-sync`: Batch-pull mobile notes from Telegram Bot into atomic inbox notes on a schedule or on demand.

### Modified Capabilities
- `desktop-scratchpad`: Upgraded from a simple 1-field popup to a full two-pane manager with System Tray integration, while keeping RAM footprint strictly under 10 MB.

## Impact
- **Vault Location**: `C:\Users\helder.toucas\Dev\home\00-inbox\`.
- **System Memory**: ~5-7 MB resident RAM for AHK tray client; 0 MB idle RAM for Python sync.
- **Dependencies**: AutoHotkey v2 for desktop UI; Python 3 with standard library (`urllib.request`) for Telegram sync.
