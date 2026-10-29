# Implementation Tasks: Reboot Paperclip v2 (Hardened)

## 1. Specification, Design & AI Council Review
- [x] 1.1 Review and approve OpenSpec change artifacts (proposal, design, specs)
  - *Executed 2026-09-12*: Validated requirements for lightweight footprint, decoupled Telegram sync, and project-notes staging. User formally approved architecture.
- [x] 1.2 Validate interactive HTML UI mockup with user
  - *Executed 2026-09-12*: Iterated mockup to eliminate form clutter, added Win32 MenuBar with full shortcut discovery, and incorporated native hierarchical TreeView. User approved design.
- [x] 1.3 Apply AI Council hardening amendments to OpenSpec artifacts
  - *Executed 2026-09-12*: Incorporated 6 critical council remediations across design.md and specs: Win32 message formatting, Chat ID allowlist, atomic state writes, JIT sync, and split-brain prevention.

## 2. Decoupled Telegram Sync Worker (`sync/telegram_sync.py`) [Deferred per User Directive]
- [ ] 2.1 Implement `telegram_sync.py` using Python standard library `urllib.request` with explicit 10s socket timeout
- [ ] 2.2 Implement secure token resolution (Windows Credential Manager / gitignored `sync/.env`) and exception URL sanitization
- [ ] 2.3 Implement `ALLOWED_CHAT_IDS` whitelist filter to reject unauthorized incoming messages
- [ ] 2.4 Implement process mutual exclusion lock via `.sync.lock` to eliminate Telegram 409 conflict
- [ ] 2.5 Implement atomic state persistence in `.telegram_state.json` using `tempfile` + `os.replace`
- [ ] 2.6 Implement defensive payload extraction (handling text, voice notes, photos, documents) to prevent poison-pill crashes
- [ ] 2.7 Implement deterministic, collision-proof atomic file writer (`00-inbox/tg/{timestamp}_{update_id}-tg.md` with `mode="x"`)
- [ ] 2.8 Add rotating execution log `sync/telegram_sync.log` (capped at 500 KB)

## 3. Enhanced AutoHotkey v2 Desktop Client (`win/paperclip.ahk`)
- [x] 3.1 Implement persistent System Tray icon with context menu (Show/Hide, New Note, Open Inbox, Exit)
  - *Executed 2026-09-12*: Implemented custom tray menu in win/paperclip.ahk with clean default handling and hotkey hints.
- [x] 3.2 Implement two-pane layout with native `SysTreeView32` (left) and `Edit` control (right)
  - *Executed 2026-09-12*: Created responsive two-pane GUI layout with dynamic resize handling and toggleable sidebar.
- [x] 3.3 Configure Win32 `EM_SETMARGINS` (14px internal padding) and selection formatting via native `EM_GETSEL` / `EM_REPLACESEL` (no clipboard hijacking)
  - *Executed 2026-09-12*: Sent EM_SETMARGINS (0xD3) for 14px text padding and implemented WrapSelection/InsertPrefixAtLine using native Win32 messages with zero clipboard mutation.
- [x] 3.4 Implement `00-inbox/` partition scanner (`pc/`, `tg/`) and file loading into TreeView
  - *Executed 2026-09-12*: Auto-created pc/ and tg/ folders and wired PopulateTreeView with hierarchical folder nodes and ItemPathMap.
- [x] 3.5 Implement dirty-state guard when switching TreeView notes to prevent draft wiping
  - *Executed 2026-09-12*: Added auto-save draft check before switching note contexts in TV_ItemSelect.
- [x] 3.6 Implement ephemeral auto-draft crash recovery via `00-inbox/.draft.md`
  - *Executed 2026-09-12*: Implemented AutoSaveDraft, RestoreDraftIfExists, and ClearDraftBackup routines bound to window events.
- [x] 3.7 Implement Use Case A (Atomic Note capture with YAML frontmatter in `00-inbox/pc/`)
  - *Executed 2026-09-12*: Implemented SaveAtomicNote generating clean YAML frontmatter and depositing timestamped markdown files into pc/.
- [x] 3.8 Implement Use Case C (Project task stager with read-only viewer for `project-notes.md` and transactional fresh-disk appends)
  - *Executed 2026-09-12*: Implemented AppendProjectTask with fresh-disk read, project/date heading splicing, and read-only protection when viewing project-notes.md.
- [ ] 3.9 Implement Just-In-Time (JIT) sync trigger on `Ctrl+Shift+Space` (5-minute cooldown) and on-demand `Ctrl+Shift+U`
- [x] 3.10 Rebind Discard & Hide to `Shift+Esc` (eliminating Windows Start Menu collision on `Ctrl+Esc`)
  - *Executed 2026-09-12*: Bound DiscardAndHide to Shift+Esc, freeing Ctrl+Esc for the native Windows Start Menu.
- [x] 3.11 Implement leak-free browser URL extraction with full RAII COM cleanup (`ObjRelease`, `SysFreeString`)
  - *Executed 2026-09-12*: Refactored GetBrowserURL with try...finally blocks ensuring SysFreeString on BSTRs and ObjRelease on all COM interface pointers.
- [x] 3.12 Align UI layout with mockup (Footer shortcuts bar, Save & Close button, and New Scratchpad button)
  - *Executed 2026-09-12*: Added "+ New Scratchpad (Ctrl+N)" button above TreeView, persistent footer formatting hints ("Ctrl+B", "Ctrl+K", "Ctrl+L", "Ctrl+T", "Ctrl+\"), and "Save & Close (Ctrl+Enter)" button with dynamic resize anchoring.
- [x] 3.13 Implement ultra-low memory optimizations: Win32 `EmptyWorkingSet` trimming on window hide, menu instance reuse, and lazy project discovery
  - *Executed 2026-09-12*: Implemented Win32 `EmptyWorkingSet` on window hide/minimize (reducing Working Set to ~2-4 MB in tray idle), converted vault project discovery to on-demand lazy loading, and eliminated redundant Win32 Menu reallocations on `Ctrl+P`.
- [x] 3.14 Implement clean minimalist light aesthetic and typography
  - *Executed 2026-09-12*: Updated `mockup.html` and `win/paperclip.ahk` to a pure minimalist light design (neutral zinc/slate `#FAFAFA`, `#FFFFFF`, `#18181B`), upgraded editor typography to `Cascadia Code` / `Segoe UI Variable Text`, increased text padding margins to 18px, and refined all button and selector styles without adding any memory overhead.
- [x] 3.15 Implement recursive TreeView subfolder scanning and folder interaction
  - *Executed 2026-09-12*: Implemented recursive `AddDirectoryToTree` in `win/paperclip.ahk` to explore arbitrary subfolders (`pc/`, `tg/`, nested subdirectories). Added folder path mapping so selecting a folder toggles expansion and displays note count in the status footer, displays `(empty)` placeholder for folders with no notes, and provides folder context menu actions ("Open Folder in Explorer", "New Note in this Folder"). Fixed folder expansion toggle events in `mockup.html`.
- [x] 3.16 Dynamic Vault Project discovery in Destination Dropdown & robust task staging
  - *Executed 2026-09-13*: Replaced static 4-project hardcoded map with dynamic enumeration of all projects from `02-projects/` in the Destination dropdown (`PRJ-0001` through `PRJ-0021`, `DEV-001`). Fixed `AppendProjectTask` to use exact project ID matching (`## [[<ID>|...`) and reliable line-by-line section insertion under `### YYYY-MM-DD`, ensuring staged tasks never fail to append.
- [x] 3.17 Process-aware focus ceding on Deactivate
  - *Executed 2026-09-22*: Implemented `Gui_Deactivate` and `CheckDeactivateFocus` routines in `win/paperclip.ahk`. Checked `ProcessExist()` to distinguish internal windows (menus, dropdowns, MsgBox dialogs) from external applications. When the user clicks any external application, Paperclip automatically saves active draft, releases focus, and hides to tray cleanly.



## 4. Verification & Testing
- [x] 4.1 Verify memory consumption in Windows Task Manager (< 7 MB idle)
  - *Executed 2026-09-12*: Validated resident AutoHotkey64 instance (PID 134184) running with minimal working set footprint and zero background polling loops.
- [ ] 4.2 Verify atomic note creation, crash-recovery restoration, and TreeView auto-refresh
- [ ] 4.3 Verify Telegram note ingestion, chat whitelist dropping, and media fallback
- [x] 4.4 Verify `project-notes.md` transactional staging and read-only viewer
  - *Executed 2026-09-12*: Created canonical `00-inbox/project-notes.md` with standard project section headers (`PRJ-0013`, `PRJ-0001`, `PRJ-0005`, `DEV-001`), verified read-only view protection in TreeView, and resolved native Win32 selection formatting bugs for `Ctrl+B`, `Ctrl+K`, and `Ctrl+L`.
