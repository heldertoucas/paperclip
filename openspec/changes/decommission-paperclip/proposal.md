## Why

Paperclip (the AutoHotkey v2 Windows capture scratchpad) has been running continuously in the background, consuming desktop resources with an older integration pattern into the Obsidian vault. The utility is being decommissioned to eliminate background overhead and remove startup hooks. The codebase, architectural assets, and documentation are preserved in version control for a future reboot.

## What Changes

- **Terminate Running Daemon**: Stop any running `AutoHotkey64.exe` processes executing `win/paperclip.ahk`.
- **Remove Startup Hooks**: Delete `Paperclip.lnk` from the Windows User Startup folder (`shell:startup`) and verify no Task Scheduler jobs or Registry Run keys remain.
- **Dormant Repository State**: Set the project into a formally decommissioned state in OpenSpec and DU tracking, preserving all source code (`win/`, `mac/`, `docs/`) for future development.
- **Future Reboot Blueprint**: Document the lessons learned and target design for when Paperclip is rebuilt (modern on-demand invocation, lightweight CLI/MCP or native UI, decoupled capture pipeline).
- **BREAKING**: Paperclip will no longer auto-launch on Windows login, and the global hotkey (`Ctrl+Shift+Space`) is disabled.

## Capabilities

### New Capabilities
- `decommissioning`: Governs the clean shutdown, removal of OS autostart hooks, and preservation of historical assets for future iteration.

### Modified Capabilities

## Impact

- **Affected OS State**: Windows Startup folder (`%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup`), active task list.
- **Affected Repository**: `C:\Users\helder.toucas\Dev\paperclip`.
- **Dependencies**: AutoHotkey v2 background runner is no longer needed at login.
