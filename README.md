# Paperclip

> [!WARNING]
> **Status: Decommissioned (Preserved for Future Reboot)**
> Paperclip is currently dormant and decommissioned as of 2026-09-11 to eliminate background system resource usage and autostart overhead. All code, architecture, and documentation are preserved in this repository to serve as the foundation for an upcoming reimagined capture utility. See [OpenSpec Change: decommission-paperclip](file:///C:/Users/helder.toucas/Dev/paperclip/openspec/changes/decommission-paperclip/proposal.md).

Ultra-lightweight Windows capture utility for the **obsidian-ht** Second Brain ecosystem.

Paperclip was a keyboard-first scratchpad designed for instant information capture. It acted as an ephemeral buffer between your stream of consciousness and your long-term knowledge repository.

## 🚀 Key Features

- **Global Hotkey (`Ctrl+Shift+Space`):** Instant invocation with zero-latency focus.
- **Context Awareness:** Automatically captures the active window title, process name, and browser URL (Chrome/Edge/Brave).
- **Domain Sorting:** 5 dedicated contexts (Inbox, Família, Passaporte, Futuro, Freelance) with quick-switching (`Ctrl+[1-5]`).
- **Smart Formatting:**
  - **Smart Markdown Paste (`Ctrl+Alt+V`):** Converts HTML fragments to clean Markdown.
  - **Clean Paste (`Ctrl+Shift+V`):** Strips artifacts and normalizes whitespace.
  - **Wiki-links (`Ctrl+K`):** Wraps selection in `[[ ]]`.
  - **Checklists (`Ctrl+L`):** Inserts `- [ ] `.
  - **Timestamps (`Ctrl+T`):** Inserts current time.
- **Template System (`Ctrl+J`):** Quick insertion of common snippets and meeting structures.
- **Integrated Help:** Persistent `?` tab for non-destructive command discovery.
- **Ultra-Light Footprint:** Stable background memory usage of ~19MB RAM.

## 🛠️ Architecture

- **Engine:** AutoHotkey v2.0
- **Storage:** Local `.md` files in `obsidian-ht/00-inbox/pc/`
- **Branding:** Minimalist, high-contrast UI (warm paper theme).

## 📊 Performance

Monitoring is performed via `monitor_perf.ps1`, logging real-time RAM usage to `perf_log.txt`.

---

*Part of the [obsidian-ht](https://github.com/heldertoucas/obsidian-ht) second brain ecosystem.*
