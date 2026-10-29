# Design: Reboot Paperclip v2 (Hardened Architecture)

## Context
Paperclip was decommissioned on 2026-09-11 (DEC-0019) to eliminate an unmonitored resident daemon. The v2 reboot re-architects Paperclip as a dual-component system: an ultra-lightweight AutoHotkey v2 desktop client (< 7 MB RAM) with an inbox TreeView navigator and a decoupled, headless Python sync engine (0 MB idle RAM).

Following an adversarial AI Council audit, this design incorporates strict resilience, secret management, file-locking, and memory invariants.

## Architecture & Boundaries

```
+------------------------------------------------------------------------------------+
| Windows User Space                                                                 |
|                                                                                    |
|  [ Tray Icon ] <---> [ Hotkey Ctrl+Shift+Space ] <---> [ Desktop .lnk ]            |
|         |                     |                                                    |
|         +----------+----------+                                                    |
|                    v                                                               |
|       +------------------------------------+                                       |
|       | win/paperclip.ahk (~6 MB RAM)      |                                       |
|       | - SysTreeView32 (00-inbox/pc, tg)  |                                       |
|       | - Edit Control (EM_SETMARGINS)     |                                       |
|       | - Native EM_REPLACESEL formatting  |                                       |
|       | - Ephemeral auto-draft (.draft.md) |                                       |
|       | - JIT Sync trigger (5m cooldown)   |                                       |
|       +------------------+-----------------+                                       |
|                          | (Async non-blocking spawn)                              |
|                          v                                                         |
|       +------------------------------------+                                       |
|       | sync/telegram_sync.py              |                                       |
|       | - Win32 Credential Manager / .env  |                                       |
|       | - ALLOWED_CHAT_IDS whitelist gate  |                                       |
|       | - Single-instance .sync.lock       |                                       |
|       | - Atomic state write (os.replace)  |                                       |
|       | - 10s socket timeout & sanitization|                                       |
|       | - 0 MB idle RAM (ephemeral)        |                                       |
|       +------------------+-----------------+                                       |
+--------------------------|---------------------------------------------------------+
                           v
+------------------------------------------------------------------------------------+
| Obsidian Vault (Dev/home/00-inbox/)                                                |
|  ├── pc/                                                                           |
|  │    └── YYYYMMDD-HHmmss-pc.md         <---+ (Atomic desktop notes)               |
|  ├── tg/                                                                           |
|  │    └── YYYYMMDD-HHmmss_ID-tg.md      <---+ (Telegram mobile notes)              |
|  ├── project-notes.md                   <---+ (Append-only task stager)            |
|  └── .draft.md                          <---+ (Crash-recovery temporary buffer)    |
+------------------------------------------------------------------------------------+
```

## Architectural Decisions & Hardening Invariants

### Decision 1: Secret Storage & Ingestion Authorization
- **Credential Storage**: Bot tokens are never accepted via CLI flags. Stored in Windows Credential Manager (`Paperclip/TelegramBotToken`) or gitignored `sync/.env`.
- **Chat Whitelist Gate**: `telegram_sync.py` strictly verifies incoming `chat.id` and `from.id` against a configured `ALLOWED_CHAT_IDS` whitelist. Updates from unauthorized users are immediately dropped to prevent markdown bombs or vault spam.
- **Log Sanitization**: Outbound Telegram API URLs sanitize `/bot<TOKEN>/` to `/bot<REDACTED>/` before logging or raising exceptions.

### Decision 2: Network Resilience & Concurrency Locks
- **Hard Timeout**: Enforce `timeout=10` on all `urllib.request` network calls to eliminate socket hangs on sleeping or captive networks.
- **Mutual Exclusion Lock**: Python creates an atomic lock file (`.sync.lock`) using `os.open(..., O_CREAT | O_EXCL)`. If locked, secondary runs abort immediately to prevent Telegram `HTTP 409 Conflict`.
- **Async Execution from AHK**: AHK spawns the Python worker asynchronously (`Run` instead of `RunWait`), preventing UI freezes during network calls.

### Decision 3: File System Integrity & Directory Standardization
- **Partitioned Inbox Topology**:
  - `Dev/home/00-inbox/pc/`: Desktop captures.
  - `Dev/home/00-inbox/tg/`: Telegram captures.
  - `Dev/home/00-inbox/project-notes.md`: Shared project task staging.
  - Directories are auto-bootstrapped on launch if missing.
- **Idempotent Filenames**: Telegram notes include the message/update ID (`{timestamp}_{update_id}-tg.md`) and open with exclusive creation (`mode="x"`), preventing batch timestamp overwrite collisions.
- **Atomic State Persistence**: `.telegram_state.json` updates transactionally via temporary file + `os.replace` to prevent 0-byte corruptions during unexpected shutdowns.

### Decision 4: Concurrency & Split-Brain Prevention on `project-notes.md`
- **Read-Only / Preview Mode**: Selecting `project-notes.md` in the TreeView opens it in read-only mode with an "Open in Obsidian (`Ctrl+O`)" shortcut.
- **Transactional Appends**: Staging tasks via the Destination selector performs a fresh disk read, appends under `## [[PRJ-XXXX|Name]]` > `### YYYY-MM-DD`, and immediately flushes to disk.

### Decision 5: Just-In-Time (JIT) Sync Pattern
- **Summon-Triggered Sync**: Pressing `Ctrl+Shift+Space` checks `last_sync_timestamp`. If > 5 minutes have elapsed, AHK silently spawns `telegram_sync.py` in the background.
- **On-Demand Hotkey**: `Ctrl+Shift+U` triggers immediate sync.
- **Decoupled Footprint**: Eliminates dependency on fragile Windows Task Scheduler jobs on laptops.

### Decision 6: Native Win32 Stability & Memory Invariants
- **No Clipboard Hijacking**: Selection formatting (`Ctrl+B`, `Ctrl+K`, `Ctrl+L`) uses native Win32 `EM_GETSEL` and `EM_REPLACESEL` messages instead of simulated `Send("^c")` keystrokes.
- **RAII COM Reference Counting**: `GetBrowserURL` wraps all BSTR strings in `SysFreeString` and COM pointers in `ObjRelease` inside `try...finally` blocks to eliminate memory leaks.
- **Windows Shortcut Safety**: Rebinds Discard & Hide to `Shift+Esc` (avoiding the native Windows Start Menu collision on `Ctrl+Esc`).
- **Crash Recovery Buffer**: AHK debounces writes of active text to `00-inbox/.draft.md`, auto-restoring drafts if the app or OS restarts unexpectedly.
