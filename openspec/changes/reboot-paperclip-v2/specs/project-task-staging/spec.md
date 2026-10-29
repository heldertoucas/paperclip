## Purpose
Defines the structured note and task staging interface that appends to `00-inbox/project-notes.md` grouped by Project and Day with split-brain overwrite prevention.

## Requirements

### Requirement: Split-Brain Overwrite Prevention (Read-Only Viewer)
The system SHALL prevent in-place editor mutations of `project-notes.md` to avoid clobbering concurrent appends or external edits from Obsidian.

#### Scenario: Viewing `project-notes.md` in TreeView
- **WHEN** the user selects `project-notes.md` in the TreeView
- **THEN** the editor renders the file in Read-Only mode
- **AND** an "Open in Obsidian (`Ctrl+O`)" shortcut is provided for manual structural reorganization

### Requirement: Transactional Fresh-Disk-Read Appends
The system SHALL append task entries directly from the latest disk state without caching stale file buffers.

#### Scenario: Staging a Note for a Project
- **WHEN** the user selects project `PRJ-0013` (Paperclip) in the Destination selector and submits text via `Ctrl+Enter`
- **THEN** `project-notes.md` is read freshly from disk
- **AND** the task is inserted under `## [[PRJ-0013|Paperclip]]` > `### YYYY-MM-DD` as `- [ ] HH:mm: <task>`
- **AND** flushed immediately to disk
- **AND** the TreeView dirty state is cleared
