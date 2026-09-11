## Context

Paperclip historically used AutoHotkey v2 to provide a global Windows hotkey (`Ctrl+Shift+Space`) saving quick markdown notes directly to `obsidian-ht/00-inbox/pc/`. Having an always-resident background daemon running on boot creates desktop overhead when capture workflows can be redesigned more cleanly.

## Goals / Non-Goals

**Goals:**
- Completely halt resident execution of Paperclip on Windows.
- Purge Windows startup shortcuts (`shell:startup\Paperclip.lnk`).
- Retain full git history, source scripts (`win/`, `mac/`), and documentation in `paperclip` so future iterations can reuse them.
- Provide a clear blueprint for Paperclip v2.

**Non-Goals:**
- Deleting the repository or purging git history.
- Implementing the v2 rewrite immediately (deferred to a future change).

## Decisions

### Decision: In-Place Decommissioning vs Repository Archival
- **Choice**: Keep the repository in `Dev/paperclip` in a dormant/decommissioned state tracked by OpenSpec.
- **Rationale**: Preserves working directory context and registry mapping (`PRJ-0013` / `REP-0014`) without breaking references.
- **Alternatives considered**: Moving repo to an archive path or deleting code; rejected to preserve institutional knowledge.

### Decision: Future Architecture Blueprint
- **Choice**: Future Paperclip v2 should be on-demand (e.g. lightweight CLI/MCP, launcher extension, or decoupled native app) rather than an always-on polling AutoHotkey script.
- **Rationale**: Zero idle memory footprint and reliable cross-platform operation.

## Risks / Trade-offs

- [Risk] Accidental manual relaunch → Mitigation: Startup shortcut removed; global hotkey dormant unless manually executed.
- [Risk] Loss of domain context → Mitigation: Documentation, domain schemas, and hotkey mappings remain preserved in repository files.
