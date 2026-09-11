## Purpose

Defines the decommissioning guarantees, system quiescence standards, and autostart removal invariants for the Paperclip capture utility.

## ADDED Requirements

### Requirement: Autostart Elimination
The system SHALL ensure that no background daemons or shortcuts execute Paperclip automatically on user login.

#### Scenario: Windows User Login
- **WHEN** user logs into the Windows operating system
- **THEN** neither `Paperclip.lnk` nor any Paperclip script or daemon is launched in the background

### Requirement: Daemon Quiescence
The system SHALL ensure zero running background processes or lingering thread handles remain active for Paperclip.

#### Scenario: Process Verification
- **WHEN** processes are inspected via PowerShell or Task Manager
- **THEN** no `AutoHotkey64.exe` instances running `paperclip.ahk` or performance monitors are present

### Requirement: Codebase Preservation for Future Reboot
The system SHALL keep all source scripts in `win/`, `mac/`, and documentation version-controlled and intact.

#### Scenario: Inspecting preserved repository assets
- **WHEN** a developer inspects the repository for future redesign
- **THEN** all historical implementation files, layout definitions, and keymaps remain accessible in git
