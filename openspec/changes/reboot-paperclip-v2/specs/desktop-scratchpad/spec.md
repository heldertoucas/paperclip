## Purpose
Defines the distraction-free desktop client interface, hierarchical inbox TreeView navigation, native Win32 controls, keyboard shortcuts, context awareness, and system tray integration in AutoHotkey v2.

## Requirements

### Requirement: Distraction-Free Zen Interface & Canvas Padding
The desktop client SHALL prioritize zero-friction typing without multi-field form clutter, providing comfortable reading margins.

#### Scenario: Opening Paperclip for Capture
- **WHEN** the user invokes Paperclip via hotkey (`Ctrl+Shift+Space`), tray icon, or shortcut
- **THEN** a clean two-pane window appears with focus already in the text scratchpad
- **AND** Win32 `EM_SETMARGINS` is applied to provide a 14px internal text margin
- **AND** no mandatory title, domain, or context input fields block typing

#### Scenario: Ephemeral Crash Recovery (.draft.md)
- **WHEN** the user types text into the scratchpad
- **THEN** the active buffer is debounced to `00-inbox/.draft.md`
- **AND** upon launching Paperclip, if `.draft.md` exists, its contents are automatically restored into the canvas

### Requirement: Hierarchical Inbox TreeView (`SysTreeView32`) & Dirty-State Guard
The client SHALL provide a left sidebar rendering a native Win32 TreeView of `Dev/home/00-inbox/` with subfolders `pc/` and `tg/`.

#### Scenario: Browsing Existing Notes with Dirty-State Protection
- **WHEN** the user clicks an existing `.md` note in the TreeView
- **IF** the current canvas contains unsaved changes, the client prompts: `Save draft before switching? [Yes] [No]`
- **THEN** upon resolution, the selected note's markdown loads for review and editing

#### Scenario: Returning to Blank Scratchpad
- **WHEN** the user clicks the `+ New` button or presses `Ctrl+N`
- **THEN** the editor clears and prepares for a new capture

#### Scenario: Refreshing the TreeView
- **WHEN** the user presses `F5` or restores the window from tray
- **THEN** the TreeView refreshes its file hierarchy from disk without collapsing existing expanded paths

### Requirement: Native Win32 Selection Formatting (No Clipboard Hijacking)
The client SHALL use native Win32 `EM_GETSEL` (0x00B0) and `EM_REPLACESEL` (0x00C2) messages to wrap selections, preserving undo buffers and clipboard history.

#### Scenario: Text Formatting
- **WHEN** text is selected in the canvas:
  - `Ctrl+B`: Wraps selection in `**bold**`
  - `Ctrl+I`: Wraps selection in `*italic*`
  - `Ctrl+K`: Wraps selection in `[[Wiki-link]]`
  - `Ctrl+L`: Inserts or toggles checklist item `- [ ] `
  - `Ctrl+T`: Inserts current timestamp `HH:mm: `
- **AND** the system clipboard is completely untouched

### Requirement: Safe OS Shortcuts & MenuBar Discoverability
The client SHALL provide complete shortcut access via a native MenuBar (`File`, `Edit`, `Format`, `View`, `Sync`, `Help`), avoiding native Windows hotkey collisions.

#### Scenario: Discarding and Hiding
- **WHEN** the user presses `Shift+Esc` (or clicks `File -> Discard & Hide`)
- **THEN** the draft is cleared and the window minimizes to the tray
- **AND** `Ctrl+Esc` is NEVER intercepted (reserved for Windows Start Menu)

### Requirement: Leak-Free Context Awareness
When creating an atomic note, the client SHALL extract the active browser URL and window title using RAII COM reference counting, explicitly calling `SysFreeString` on all allocated BSTR strings and `ObjRelease` on COM pointers inside `try...finally` blocks.

### Requirement: Ultra-Low Memory Footprint & Working Set Trimming
The desktop client SHALL enforce minimal memory consumption in idle and background states through Win32 Working Set trimming and lazy-loading patterns.

#### Scenario: Background Inactivity Trimming
- **WHEN** the user hides or minimizes Paperclip to the system tray (`Esc`, `Shift+Esc`, window close, or after `Ctrl+Enter` save)
- **THEN** the client SHALL invoke `psapi.dll\EmptyWorkingSet` via `DllCall` with the current process pseudo-handle (`-1`)
- **AND** the resident Working Set in RAM SHALL drop to under 5 MB in idle tray state without impacting subsequent summon latency

#### Scenario: Lazy Dynamic Project Discovery
- **WHEN** Paperclip launches on system startup
- **THEN** project scanning across `02-projects/` SHALL be deferred until first access to the project list (`Ctrl+P` or `Format` menu)
- **AND** menu instances SHALL be reused across summon cycles rather than reallocated on every hotkey press

### Requirement: JIT (Just-In-Time) Sync Trigger
When Paperclip is summoned via `Ctrl+Shift+Space`, the client SHALL check if > 5 minutes have elapsed since the last Telegram sync; if so, it asynchronously launches `sync/telegram_sync.py` without blocking the UI thread.

