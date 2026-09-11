## 1. Process and System Autostart Termination

- [x] 1.1 Terminate active resident AutoHotkey process running paperclip.ahk
  - *Executed 2026-09-11*: Identified running AutoHotkey64 instance (PID 67564) and stopped process.
- [x] 1.2 Remove Windows startup shortcut from user Startup directory
  - *Executed 2026-09-11*: Deleted Paperclip.lnk from %APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup and verified no registry Run keys or scheduled tasks exist.

## 2. Documentation and Decommissioning Records

- [x] 2.1 Author OpenSpec decommission change proposal, spec, and design
  - *Executed 2026-09-11*: Created OpenSpec change decommission-paperclip defining invariants, system quiescence, and future reboot requirements.
- [x] 2.2 Update repository root README.md with decommissioned notice and v2 vision
  - *Executed 2026-09-11*: Added decommissioned status alert and link to OpenSpec change in README.md.
- [ ] 2.3 Propose DU project status update in registry for PRJ-0013
