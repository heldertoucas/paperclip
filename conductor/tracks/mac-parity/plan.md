# Track: Mac Parity Implementation

Ensure the Mac implementation of Paperclip (Hammerspoon-based) matches the feature set, user experience, and lightweight performance profile of the Windows AutoHotkey implementation.

## Objectives
- [x] **Path Resolution Fix**: Correct `paperclip.destination_dir` dynamic resolution to target the actual Obsidian vault inbox (`~/Dev/obsidian-ht/00-inbox/mac/`).
- [x] **Template System (Cmd+J)**: Implement the menu/template overlay for quick text insertions (Follow-up, Meeting Minutes, Task Ref).
- [x] **HTML to Markdown conversion validation**: Validate Javascript/Lua conversion implementation for robust parsing (matching AHK implementation).
- [ ] **Code Audit & Setup Validation**: Audit current `mac/init.lua` structure and check Hammerspoon environment.
- [ ] **Auto-Startup configuration**: Establish daemon/plist or Hammerspoon launch configuration for auto-boot on macOS.
- [ ] **Performance Benchmarking**: Verify lightweight memory consumption on macOS.
