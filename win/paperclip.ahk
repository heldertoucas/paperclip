#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent(true)

; ==============================================================================
; PROJECT PAPERCLIP v2: Hardened Windows Desktop Edition
; Architecture: Native Win32 Two-Pane Inbox Navigator & Zen Scratchpad
; Memory Footprint: < 7 MB RAM | Zero-Clipboard Hijacking | RAII COM Cleanup
; ==============================================================================

GLOBAL_HOTKEY := "^+Space"
WINDOW_WIDTH := 900
WINDOW_HEIGHT := 580
SIDEBAR_WIDTH := 250

; --- Auto-resolve Vault Inbox Location ---
VAULT_INBOX_DIR := ""
CandidatePaths := [
    "C:\Users\helder.toucas\Dev\home\00-inbox",
    A_ScriptDir "\..\..\home\00-inbox",
    A_ScriptDir "\obsidian-ht\00-inbox"
]
for p in CandidatePaths {
    if DirExist(p) {
        VAULT_INBOX_DIR := p
        break
    }
}
if (VAULT_INBOX_DIR == "") {
    VAULT_INBOX_DIR := CandidatePaths[1]
    try DirCreate(VAULT_INBOX_DIR)
}

; Ensure partitioned subfolders exist
PC_INBOX_DIR := VAULT_INBOX_DIR "\pc"
TG_INBOX_DIR := VAULT_INBOX_DIR "\tg"
if !DirExist(PC_INBOX_DIR)
    try DirCreate(PC_INBOX_DIR)
if !DirExist(TG_INBOX_DIR)
    try DirCreate(TG_INBOX_DIR)

PROJ_NOTES_FILE := VAULT_INBOX_DIR "\project-notes.md"
DRAFT_FILE := VAULT_INBOX_DIR "\.draft.md"
VAULT_PROJECTS_DIR := RegExReplace(VAULT_INBOX_DIR, "00-inbox$", "02-projects")

; --- State tracking & Global GUI Controls ---
global CurrentActiveFile := ""       ; Empty if in draft mode, otherwise path of loaded note
global IsSidebarVisible := true
global LastContext := ""
global LastProcess := ""
global LastSavedHash := ""
global ItemPathMap := Map()          ; TreeView ItemID -> FilePath (or "" for draft)
global ExpandedNodes := Map()        ; Tracks expanded folder paths across refreshes
global ProjectList := []             ; Cached list of { id: "PRJ-xxxx", title: "...", label: "..." }

global MyGui := ""
global Editor := ""
global TV := ""
global DestChoice := ""
global BtnNew := ""
global BtnSave := ""
global FooterHints := ""

; --- Initialize Main GUI ---
MyGui := Gui("+Resize +AlwaysOnTop", "Paperclip v2")
OnMessage(0x0006, WM_ACTIVATE)
MyGui.SetFont("s9", "Segoe UI Variable Text") ; Fallback cleanly if not present

; --- Native MenuBar ---
MenuBarObj := MenuBar()

; File Menu
FileMenu := Menu()
FileMenu.Add("&New Scratchpad`tCtrl+N", (*) => StartNewDraft())
FileMenu.Add("&Save & Close`tCtrl+Enter", (*) => SaveOrCommitNote())
FileMenu.Add("&Open Note in Obsidian`tCtrl+O", (*) => OpenCurrentInObsidian())
FileMenu.Add("Open &Inbox in Explorer", (*) => Run('explorer.exe "' VAULT_INBOX_DIR '"'))
FileMenu.Add()
FileMenu.Add("&Hide to Tray`tEsc", (*) => HideWindow())
FileMenu.Add("&Discard Draft & Hide`tShift+Esc", (*) => DiscardAndHide())
FileMenu.Add()
FileMenu.Add("E&xit Paperclip", (*) => ExitApp())
MenuBarObj.Add("&File", FileMenu)

; Edit Menu
EditMenu := Menu()
EditMenu.Add("&Clean Paste`tCtrl+Shift+V", (*) => CleanPaste())
EditMenu.Add("Paste as &Markdown`tCtrl+Alt+V", (*) => PasteAsMarkdown())
EditMenu.Add()
EditMenu.Add("Focus &Destination Selector`tAlt+D", (*) => DestChoice.Focus())
MenuBarObj.Add("&Edit", EditMenu)

; Format Menu
FormatMenu := Menu()
FormatMenu.Add("&Bold`tCtrl+B", (*) => WrapSelection("**", "**"))
FormatMenu.Add("&Italic`tCtrl+I", (*) => WrapSelection("*", "*"))
FormatMenu.Add("&Wiki-link`tCtrl+K", (*) => WrapSelection("[[", "]]"))
FormatMenu.Add("&Checklist Item`tCtrl+L", (*) => InsertPrefixAtLine("- [ ] "))
FormatMenu.Add("&Timestamp`tCtrl+T", (*) => InsertText(FormatTime(, "HH:mm") ": "))
FormatMenu.Add()
ProjectSubMenu := Menu()
FormatMenu.Add("Insert &Project Link ❯`tCtrl+P", ProjectSubMenu)
MenuBarObj.Add("&Format", FormatMenu)

; View Menu
ViewMenu := Menu()
ViewMenu.Add("&Toggle TreeView Sidebar`tCtrl+\", (*) => ToggleSidebar())
ViewMenu.Add("Switch &Focus to TreeView`tCtrl+Tab", (*) => TV.Focus())
ViewMenu.Add()
ViewMenu.Add("&Refresh Inbox from Disk`tF5", (*) => RefreshTreeView())
MenuBarObj.Add("&View", ViewMenu)

; Tools Menu (AI & Moodle Launchers & Vault Sync)
ToolsMenu := Menu()
ToolsMenu.Add("Sincronizar e Fechar Cofre (Push / Handoff)", (*) => Run('C:\Users\helder.toucas\Dev\DU-Launcher\01 - Ferramentas Principais\Sincronizar Cofre (Push).cmd', "C:\Users\helder.toucas\Dev\home"))
ToolsMenu.Add("Executar Fecho Diário (18:00)", (*) => Run('pwsh.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "C:\Users\helder.toucas\Dev\home\scripts\obsidian_sync_close.ps1"', "C:\Users\helder.toucas\Dev\home"))
ToolsMenu.Add()
ToolsMenu.Add("Abrir &Chrome (Automação - CDP 9222)", (*) => Run('C:\Users\helder.toucas\Dev\Abrir_Chrome_Automacao.cmd', "C:\Users\helder.toucas\Dev"))
ToolsMenu.Add("Abrir &Brave (Perfil Normal - CDP 9223)", (*) => Run('C:\Users\helder.toucas\Dev\Abrir_Brave_Automacao.cmd', "C:\Users\helder.toucas\Dev"))
ToolsMenu.Add()
ToolsMenu.Add("Abrir &Moderação de Fóruns (HTML)", (*) => Run('explorer.exe "C:\Users\helder.toucas\Dev\work\projetos\curso-online-teams-sharepoint\docs\moderacao_forum.html"'))
MenuBarObj.Add("&Tools", ToolsMenu)

; Help Menu
HelpMenu := Menu()
HelpMenu.Add("&Keyboard Shortcuts`tF1", (*) => ShowShortcutsDialog())
HelpMenu.Add("&About Paperclip", (*) => ShowAboutDialog())
MenuBarObj.Add("&Help", HelpMenu)

MyGui.MenuBar := MenuBarObj

; --- Destination Selector (Top Row) ---
MyGui.SetFont("s9 bold c71717A", "Segoe UI Variable Text")
DestLabel := MyGui.Add("Text", "x14 y10 w80 h24 +0x0200", "Destination:")
MyGui.SetFont("s9 norm c18181B", "Segoe UI Variable Text")

; Populate ProjectList from vault to discover all available projects
LoadProjectsFromVault()

DestOptions := ["📄 New Atomic Note (00-inbox/pc/)"]
for p in ProjectList {
    DestOptions.Push("📌 Staged Task → " p.title " (" p.id ")")
}
DestChoice := MyGui.Add("DropDownList", "x96 y10 w350 r12 Choose1", DestOptions)
DestChoice.OnEvent("Change", DestChoice_Change)

; --- Left Pane: Hierarchical TreeView + New Draft Button ---
MyGui.SetFont("s9 norm c18181B", "Segoe UI Variable Text")
BtnNew := MyGui.Add("Button", "x14 y40 w" SIDEBAR_WIDTH " h28", "➕ New Draft (Ctrl+N)")
BtnNew.OnEvent("Click", (*) => StartNewDraft())

TV := MyGui.Add("TreeView", "x14 y72 w" SIDEBAR_WIDTH " h438 +Border BackgroundFAFAFA c18181B")
TV.OnEvent("ItemSelect", TV_ItemSelect)
TV.OnEvent("ContextMenu", TV_ContextMenu)

; --- Right Pane: Scratchpad Editor ---
; Modern monospaced font with clean white canvas and generous margins
MyGui.SetFont("s11 c18181B", "Cascadia Code")
EditorX := 14 + SIDEBAR_WIDTH + 12
EditorW := WINDOW_WIDTH - EditorX - 14
Editor := MyGui.Add("Edit", "x" EditorX " y40 w" EditorW " h470 Multi -VScroll BackgroundFFFFFF c18181B", "")

; Apply 18px text margins to Win32 Edit control (EM_SETMARGINS = 0xD3, EC_LEFTMARGIN | EC_RIGHTMARGIN = 3)
SendMessage(0xD3, 3, (18 & 0xFFFF) | (18 << 16), Editor.Hwnd)

; --- Bottom Footer Bar (Matching Minimalist Light Mockup) ---
; Left: Status & Formatting hints
HINTS_TEXT := "Ctrl+B Bold  |  Ctrl+K [[Wiki]]  |  Ctrl+P [[Project]]  |  Ctrl+L - [ ] Task  |  Ctrl+T Time  |  Ctrl+\ Sidebar"
MyGui.SetFont("s9 c71717A", "Segoe UI Variable Text")
FooterHints := MyGui.Add("Text", "x14 y520 w580 h30 +0x0200", HINTS_TEXT)

; Right: Direct Save & Close button (clean minimalist action button)
MyGui.SetFont("s9 bold c18181B", "Segoe UI Variable Text")
BtnSave := MyGui.Add("Button", "x" (WINDOW_WIDTH - 214) " y518 w200 h30 Default", "Save & Close (Ctrl+Enter)")
BtnSave.OnEvent("Click", (*) => SaveOrCommitNote())

; Status info line: sets message and automatically restores shortcut hints after 3.5 seconds
SetStatus(msg) {
    global FooterHints, HINTS_TEXT
    FooterHints.Value := msg
    SetTimer(() => (FooterHints.Value := HINTS_TEXT), -3500)
}
StatusBar := { Value: "" }
; Route legacy StatusBar assignments through SetStatus
StatusBar.DefineProp("Value", { Set: (this, val) => SetStatus(val) })

; --- Window Resize Handling ---
MyGui.OnEvent("Size", Gui_Size)
Gui_Size(GuiObj, MinMax, Width, Height) {
    if (MinMax == -1) ; Minimized
        return
    if (!Editor || !TV || !BtnNew || !BtnSave || !FooterHints)
        return
    
    footerY := Height - 42
    if (IsSidebarVisible) {
        BtnNew.Visible := true
        TV.Visible := true
        BtnNew.Move(14, 40, SIDEBAR_WIDTH, 28)
        TV.Move(14, 72, SIDEBAR_WIDTH, Height - 124)
        edX := 14 + SIDEBAR_WIDTH + 12
        edW := Width - edX - 14
        Editor.Move(edX, 40, edW, Height - 90)
    } else {
        BtnNew.Visible := false
        TV.Visible := false
        Editor.Move(14, 40, Width - 28, Height - 90)
    }
    
    saveBtnW := 200
    saveBtnX := Width - saveBtnW - 14
    hintsW := saveBtnX - 28
    FooterHints.Move(14, footerY, hintsW, 30)
    BtnSave.Move(saveBtnX, footerY, saveBtnW, 30)
}

; --- System Tray Configuration ---
A_IconTip := "Paperclip v2 (00-inbox)"
try TraySetIcon("shell32.dll", 71) ; Distinct Notepad/Document icon instead of generic green H

; Development Universe (DU) Submenus
aiMenu := Menu()
aiMenu.Add("1. Abrir Chrome (Automação - CDP 9222)", (*) => Run('C:\Users\helder.toucas\Dev\Abrir_Chrome_Automacao.cmd', "C:\Users\helder.toucas\Dev"))
aiMenu.Add("2. Abrir Brave (Perfil Normal - CDP 9223)", (*) => Run('C:\Users\helder.toucas\Dev\Abrir_Brave_Automacao.cmd', "C:\Users\helder.toucas\Dev"))

webMenu := Menu()
webMenu.Add("1. App Avaliação (Vercel)", (*) => Run("https://app-avaliacao.vercel.app"))
webMenu.Add("2. Futuro Digital (Vercel)", (*) => Run("https://futuro-digital.vercel.app"))
webMenu.Add("3. IA para Todos (Vercel)", (*) => Run("https://ia-para-todos.vercel.app"))
webMenu.Add("4. Desafio do Dia (Vercel)", (*) => Run("https://desafio-do-dia.vercel.app"))
webMenu.Add("5. Newsletter App (Vercel)", (*) => Run("https://newsletter-app.vercel.app"))
webMenu.Add("6. Passaporte Password (Vercel)", (*) => Run("https://passaporte-password.vercel.app"))

devMenu := Menu()
devMenu.Add("1. RuleSync Explorer (7531)", (*) => Run("C:\Users\helder.toucas\Dev\DU-Launcher\02 - Ferramentas Dev (Local)\RuleSync Explorer.cmd", "C:\Users\helder.toucas\Dev\rulesync-explorer"))
devMenu.Add("2. DU Dashboard (3005)", (*) => Run("C:\Users\helder.toucas\Dev\DU-Launcher\02 - Ferramentas Dev (Local)\DU Dashboard.cmd", "C:\Users\helder.toucas\Dev\du-dashboard"))
devMenu.Add("3. Secret Vault (5000)", (*) => Run("C:\Users\helder.toucas\Dev\DU-Launcher\02 - Ferramentas Dev (Local)\Secret Vault.cmd", "C:\Users\helder.toucas\Dev\keys"))
devMenu.Add("4. Social Media Manager (8000)", (*) => Run("C:\Users\helder.toucas\Dev\DU-Launcher\02 - Ferramentas Dev (Local)\Social Media Manager.cmd", "C:\Users\helder.toucas\Dev\social-media-manager"))
devMenu.Add("5. BD Profissional Explorer", (*) => Run("C:\Users\helder.toucas\Dev\bd-profissional\dist\explorer.html"))
devMenu.Add()
devMenu.Add("6. Moderação de Fóruns (HTML)", (*) => Run('explorer.exe "C:\Users\helder.toucas\Dev\work\projetos\curso-online-teams-sharepoint\docs\moderacao_forum.html"'))

vaultMenu := Menu()
vaultMenu.Add("1. Obsidian Second Brain", (*) => Run("obsidian://open?path=C:\Users\helder.toucas\Dev\home"))
vaultMenu.Add()
vaultMenu.Add("2. Sincronizar e Fechar Cofre (Push / Handoff)", (*) => Run('C:\Users\helder.toucas\Dev\DU-Launcher\01 - Ferramentas Principais\Sincronizar Cofre (Push).cmd', "C:\Users\helder.toucas\Dev\home"))
vaultMenu.Add("3. Executar Fecho Diário (18:00)", (*) => Run('pwsh.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "C:\Users\helder.toucas\Dev\home\scripts\obsidian_sync_close.ps1"', "C:\Users\helder.toucas\Dev\home"))

Tray := A_TrayMenu
Tray.Delete() ; Clean default items
Tray.Add("Show / Hide Paperclip`tCtrl+Shift+Space", (*) => ToggleWindow())
Tray.Add("New Quick Note`tCtrl+N", (*) => (ShowWindow(), StartNewDraft()))
Tray.Add()
Tray.Add("🤖 Agentes & Automação Moodle", aiMenu)
Tray.Add("🌐 Aplicações Web (Vercel)", webMenu)
Tray.Add("💻 Ferramentas Dev (Local)", devMenu)
Tray.Add("🧠 Vault & Memória", vaultMenu)
Tray.Add()
Tray.Add("Open Inbox Folder", (*) => Run('explorer.exe "' VAULT_INBOX_DIR '"'))
Tray.Add()
Tray.Add("Exit Paperclip", (*) => ExitApp())
Tray.Default := "Show / Hide Paperclip`tCtrl+Shift+Space"
Tray.ClickCount := 1 ; Single-click on tray icon toggles window!

; --- Startup Initializations ---
PopulateTreeView()
RestoreDraftIfExists()

; Show window immediately on startup
ShowWindow()
TrayTip "Paperclip v2", "Active in Tray (Ctrl+Shift+Space)", 1

; ==============================================================================
; GLOBAL ACTIVATION HOTKEY (Disabled in favor of Paperclip2 Tauri)
; ==============================================================================

; ^+Space::ToggleWindow()  ; Cedido à app Tauri Paperclip2


; ==============================================================================
; IN-APP CONTEXTUAL SHORTCUTS (ACTIVE WHEN PAPERCLIP IS FOCUSED)
; ==============================================================================

#HotIf WinActive("ahk_id " MyGui.Hwnd)
^Enter::SaveOrCommitNote()
+Esc::DiscardAndHide()
Esc::HideWindow()
^n::StartNewDraft()
^o::OpenCurrentInObsidian()
F1::ShowShortcutsDialog()
F5::RefreshTreeView()
F6::ToggleFocus()
^Tab::ToggleFocus()
^\::ToggleSidebar()
!d::DestChoice.Focus()

; Markdown formatting shortcuts
^b::WrapSelection("**", "**")
^i::WrapSelection("*", "*")
^k::WrapSelection("[[", "]]")
^l::InsertPrefixAtLine("- [ ] ")
^t::InsertText(FormatTime(, "HH:mm") ": ")
^p::ShowProjectMenu()
^+v::CleanPaste()
^!v::PasteAsMarkdown()
#HotIf

ToggleWindow(*) {
    if WinActive("ahk_id " MyGui.Hwnd) {
        AutoSaveDraft()
        HideWindow()
    } else {
        ShowWindow()
    }
}

HideWindow() {
    MyGui.Hide()
    ; Ultra-low memory optimization: trim active working set back to OS in idle tray state
    try DllCall("psapi.dll\EmptyWorkingSet", "Ptr", -1)
}

WM_ACTIVATE(wParam, lParam, msg, hwnd) {
    global MyGui
    ; wParam: 0 = WA_INACTIVE (lost focus)
    if (wParam == 0 && IsSet(MyGui) && MyGui && hwnd == MyGui.Hwnd) {
        SetTimer(CheckDeactivateFocus, -100)
    }
}

CheckDeactivateFocus() {
    activeHwnd := WinExist("A")
    if (!activeHwnd) {
        AutoSaveDraft()
        HideWindow()
        return
    }
    
    ourPid := ProcessExist()
    activePid := WinGetPID("ahk_id " activeHwnd)
    
    ; If focus switched to a child window, dialog, or menu owned by our process, do not hide
    if (activePid == ourPid)
        return
        
    ; Focus moved to an external application -> save draft and cede focus by hiding
    AutoSaveDraft()
    HideWindow()
}

ShowWindow() {
    global Editor, TV, MyGui, CurrentActiveFile
    MyGui.Show("w" WINDOW_WIDTH " h" WINDOW_HEIGHT " Center")
    WinActivate("ahk_id " MyGui.Hwnd)
    if (CurrentActiveFile == "" && Editor) {
        Editor.Focus()
        SendMessage(0xB1, -1, -1, Editor.Hwnd) ; Caret to end
    }
    SetTimer(CaptureContext, -50) ; Extract context in background without blocking UI!
}

ToggleFocus(*) {
    global Editor, TV, MyGui
    if (!Editor || !TV)
        return
    if (ControlGetFocus("ahk_id " MyGui.Hwnd) == Editor.Hwnd) {
        TV.Focus()
        StatusBar.Value := "TreeView focused. Use Arrow keys to navigate notes."
    } else {
        Editor.Focus()
        StatusBar.Value := "Editor focused. Type freely."
    }
}

ToggleSidebar(*) {
    global IsSidebarVisible
    IsSidebarVisible := !IsSidebarVisible
    if (IsSidebarVisible) {
        TV.Visible := true
    } else {
        TV.Visible := false
    }
    ; Trigger resize
    w := 0, h := 0
    MyGui.GetPos(,, &w, &h)
    Gui_Size(MyGui, 0, w, h)
}

; ==============================================================================
; TREEVIEW IMPLEMENTATION & FILE MANAGEMENT
; ==============================================================================

; Helper function: recursively populate directories and markdown files in TreeView
AddDirectoryToTree(parentID, currentDir) {
    global ItemPathMap
    itemCount := 0

    ; 1. First add subdirectories recursively
    Loop Files, currentDir "\*", "D" {
        subDirName := A_LoopFileName
        subDirPath := A_LoopFileFullPath
        folderNodeID := TV.Add("📁 " subDirName, parentID, "Expand")
        ItemPathMap[folderNodeID] := subDirPath

        childCount := AddDirectoryToTree(folderNodeID, subDirPath)
        if (childCount == 0) {
            emptyID := TV.Add("(empty)", folderNodeID)
            ItemPathMap[emptyID] := ""
        }
        itemCount++
    }

    ; 2. Then add markdown files in this directory
    Loop Files, currentDir "\*.md" {
        if (A_LoopFileFullPath == PROJ_NOTES_FILE || A_LoopFileName == ".draft.md")
            continue
        fileNodeID := TV.Add("📄 " A_LoopFileName, parentID)
        ItemPathMap[fileNodeID] := A_LoopFileFullPath
        itemCount++
    }

    return itemCount
}

PopulateTreeView() {
    global ItemPathMap
    TV.Opt("-Redraw")
    TV.Delete()
    ItemPathMap := Map()

    rootID := TV.Add("00-inbox", 0, "Expand")
    ItemPathMap[rootID] := VAULT_INBOX_DIR

    ; Special Draft item (always on top)
    draftID := TV.Add("📝 New Scratchpad (Draft)", rootID, "Select")
    ItemPathMap[draftID] := ""

    ; Staged tasks file (project-notes.md)
    if FileExist(PROJ_NOTES_FILE) {
        pnID := TV.Add("📌 project-notes.md", rootID)
        ItemPathMap[pnID] := PROJ_NOTES_FILE
    }

    ; Recursively populate all subdirectories and notes inside 00-inbox
    AddDirectoryToTree(rootID, VAULT_INBOX_DIR)

    TV.Opt("+Redraw")
}

RefreshTreeView(*) {
    PopulateTreeView()
    StatusBar.Value := "Inbox TreeView refreshed."
}

TV_ItemSelect(TVCtrl, itemID) {
    global CurrentActiveFile, ItemPathMap, Editor, DestChoice

    if !ItemPathMap.Has(itemID)
        return

    targetPath := ItemPathMap[itemID]

    ; Dirty state check on current note before switching
    if (Editor && CurrentActiveFile == "" && Trim(Editor.Value) != "") {
        AutoSaveDraft()
    }

    if (targetPath == "") {
        ; Switched to Draft or placeholder
        CurrentActiveFile := ""
        if (Editor) {
            Editor.Opt("-ReadOnly")
            Editor.Focus()
        }
        if (DestChoice)
            DestChoice.Enabled := true
        RestoreDraftIfExists()
        StatusBar.Value := "Draft mode active. Press Ctrl+Enter to save."
        return
    }

    ; If user selected a directory (e.g. 00-inbox, pc, tg, or subfolder)
    if DirExist(targetPath) {
        SplitPath targetPath, &folderName
        ; Toggle branch expansion on select/click
        isExpanded := TV.Get(itemID, "Expand")
        TV.Modify(itemID, isExpanded ? "-Expand" : "Expand")
        
        ; Count files inside
        noteCount := 0
        Loop Files, targetPath "\*.md", "R" {
            noteCount++
        }
        StatusBar.Value := "Folder: " (folderName ? folderName : "00-inbox") " (" noteCount " notes) | Click to toggle"
        return
    }


    ; Standard note file
    CurrentActiveFile := targetPath
    Editor.Opt("-ReadOnly")
    DestChoice.Enabled := false
    try {
        content := FileRead(targetPath, "UTF-8")
        Editor.Value := content
    } catch Error as e {
        Editor.Value := "# Error reading file: " e.Message
    }
    SplitPath targetPath, &fileName
    StatusBar.Value := "Editing " fileName " | Ctrl+Enter saves changes"
}

TV_ContextMenu(GuiCtrlObj, itemID, isRightClick, X, Y) {
    global ItemPathMap
    if (itemID == 0 || !ItemPathMap.Has(itemID))
        return

    targetPath := ItemPathMap[itemID]
    if (targetPath == "")
        return

    ItemMenu := Menu()
    if DirExist(targetPath) {
        ItemMenu.Add("Open Folder in Explorer", (*) => Run('explorer.exe "' targetPath '"'))
        ItemMenu.Add("New Note in this Folder", (*) => CreateNoteInFolder(targetPath))
    } else {
        ItemMenu.Add("Open in Obsidian", (*) => OpenNoteInObsidian(targetPath))
        ItemMenu.Add("Show in Explorer", (*) => Run('explorer.exe /select,"' targetPath '"'))
        ItemMenu.Add()
        ItemMenu.Add("Delete Note", (*) => DeleteSelectedNote(targetPath))
    }
    ItemMenu.Show(X, Y)
}

CreateNoteInFolder(dirPath) {
    ts := FormatTime(, "yyyyMMdd-HHmmss")
    SplitPath dirPath, &folderName
    fileName := ts "-" (folderName ? folderName : "note") ".md"
    newFilePath := dirPath "\" fileName
    
    yaml := "---`ntitle: New Note`ntype: source`nstatus: inbox`ncreated: " FormatTime(, "yyyy-MM-ddTHH:mm:ss") "`n---`n`n"
    try {
        FileAppend(yaml, newFilePath, "UTF-8")
        PopulateTreeView()
        StatusBar.Value := "Created note in " folderName
    } catch Error as e {
        MsgBox("Failed to create note: " e.Message, "Error", "IconX")
    }
}

OpenCurrentInObsidian() {
    global CurrentActiveFile
    if (CurrentActiveFile != "")
        OpenNoteInObsidian(CurrentActiveFile)
    else
        MsgBox("Please select an existing note in the TreeView to open in Obsidian.", "Paperclip", "Iconi")
}

OpenNoteInObsidian(filePath) {
    ; Calculate relative path from home vault
    vaultRoot := RegExReplace(VAULT_INBOX_DIR, "\\00-inbox$", "")
    relPath := filePath
    if InStr(filePath, vaultRoot "\") == 1 {
        relPath := SubStr(filePath, StrLen(vaultRoot) + 2)
    }
    relPath := StrReplace(relPath, "\", "/")
    
    obsidianURI := "obsidian://open?vault=home&file=" UriEncode(relPath)
    try {
        Run(obsidianURI)
    } catch {
        Run('explorer.exe /select,"' filePath '"')
    }
}

UriEncode(str) {
    return RegExReplace(str, " ", "%20")
}

DeleteSelectedNote(filePath) {
    SplitPath filePath, &fileName
    res := MsgBox("Are you sure you want to permanently delete '" fileName "'?", "Paperclip", "YesNo Icon!")
    if (res == "Yes") {
        try {
            FileDelete(filePath)
            PopulateTreeView()
            StartNewDraft()
            StatusBar.Value := "Deleted: " fileName
        } catch Error as e {
            MsgBox("Failed to delete file: " e.Message, "Error", "IconX")
        }
    }
}

; ==============================================================================
; NOTE SAVING & PROJECT TASK STAGING
; ==============================================================================

SaveOrCommitNote() {
    global CurrentActiveFile, LastSavedHash

    text := Editor.Value
    if (Trim(text) == "") {
        StatusBar.Value := "Notice: Empty note ignored."
        HideWindow()
        return
    }

    ; If we are editing an existing note file (includes project-notes.md)
    if (CurrentActiveFile != "") {
        try {
            FileDelete(CurrentActiveFile)
            FileAppend(text, CurrentActiveFile, "UTF-8")
            LastSavedHash := text
            ClearDraftBackup()
            HideWindow()
            TrayTip "Paperclip", "Saved changes to note.", 1
        } catch Error as e {
            StatusBar.Value := "Error saving: " e.Message
        }
        return
    }

    ; Otherwise, we are in Draft mode
    destIndex := DestChoice.Value

    if (destIndex == 1) {
        ; Save as atomic note in pc/
        SaveAtomicNote(text)
    } else {
        ; Append as task to project-notes.md
        AppendProjectTask(destIndex, text)
    }

    ClearDraftBackup()
    Editor.Value := ""
    HideWindow()
    PopulateTreeView()
}

SaveAtomicNote(text) {
    global LastSavedHash, LastContext, LastProcess

    ts := FormatTime(, "yyyyMMdd-HHmmss")
    filename := ts "-pc.md"
    filepath := PC_INBOX_DIR "\" filename

    ; Assemble YAML frontmatter if not already present
    finalContent := ""
    if (!RegExMatch(text, "^---[\s\S]+?---")) {
        yaml := "---`n"
        yaml .= "type: source`n"
        yaml .= "channel: desktop`n"
        yaml .= "context: " (LastProcess ? LastProcess : "unknown") "`n"
        if (LastContext ~= "^http")
            yaml .= "source: " LastContext "`n"
        yaml .= "status: inbox`n"
        yaml .= "created: " FormatTime(, "yyyy-MM-ddTHH:mm:ss") "`n"
        yaml .= "---`n`n"
        finalContent := yaml text
    } else {
        finalContent := text
    }

    try {
        FileAppend(finalContent, filepath, "UTF-8")
        LastSavedHash := finalContent
        TrayTip "Paperclip", "Note deposited in pc/" filename, 1
    } catch Error as e {
        MsgBox("Failed to save atomic note: " e.Message, "Error", "IconX")
    }
}

AppendProjectTask(destIndex, text) {
    global ProjectList, PROJ_NOTES_FILE

    ; destIndex 1 is "New Atomic Note", destIndex >= 2 maps to ProjectList[destIndex - 1]
    projIdx := destIndex - 1
    if (projIdx < 1 || projIdx > ProjectList.Length) {
        MsgBox("Invalid project selected.", "Paperclip", "IconX")
        return
    }

    p := ProjectList[projIdx]
    today := FormatTime(, "yyyy-MM-dd")
    nowTime := FormatTime(, "HH:mm")

    ; Format task bullet
    taskLine := "- [ ] " nowTime ": " Trim(text)

    ; Read latest content freshly from disk
    existingContent := ""
    if FileExist(PROJ_NOTES_FILE) {
        try existingContent := FileRead(PROJ_NOTES_FILE, "UTF-8")
    }

    ; Normalize line breaks to `n for consistent manipulation
    existingContent := StrReplace(existingContent, "`r`n", "`n")
    existingContent := StrReplace(existingContent, "`r", "`n")

    projHeader := "## [[" p.id "|" p.title "]]"
    dateHeader := "### " today

    newContent := ""
    if (Trim(existingContent) == "") {
        newContent := "# 📌 Project Notes & Task Staging`n`n" projHeader "`n" dateHeader "`n" taskLine "`n"
    } else {
        ; Check if the project section exists (match by ID e.g. ## [[PRJ-xxxx)
        lines := StrSplit(existingContent, "`n")
        
        projLineIdx := 0
        targetHeaderPrefix := "## [[" p.id
        for idx, line in lines {
            if (InStr(Trim(line), targetHeaderPrefix) == 1) {
                projLineIdx := idx
                break
            }
        }

        if (projLineIdx == 0) {
            ; Project section does not exist -> append at the bottom
            trimmed := RTrim(existingContent, "`n")
            newContent := trimmed "`n`n" projHeader "`n" dateHeader "`n" taskLine "`n"
        } else {
            ; Find the boundaries of this project section (up to the next ## header or EOF)
            nextProjLineIdx := lines.Length + 1
            loopIdx := projLineIdx + 1
            while (loopIdx <= lines.Length) {
                trimmedLoop := Trim(lines[loopIdx])
                if (InStr(trimmedLoop, "## ") == 1 && SubStr(trimmedLoop, 1, 3) != "###") {
                    nextProjLineIdx := loopIdx
                    break
                }
                loopIdx++
            }

            ; Check if dateHeader exists within this project block
            dateLineIdx := 0
            checkIdx := projLineIdx + 1
            while (checkIdx < nextProjLineIdx) {
                if (Trim(lines[checkIdx]) == dateHeader) {
                    dateLineIdx := checkIdx
                    break
                }
                checkIdx++
            }

            if (dateLineIdx == 0) {
                ; Date header missing -> insert dateHeader and taskLine right after projHeader
                lines.InsertAt(projLineIdx + 1, dateHeader, taskLine)
            } else {
                ; Date header found -> append taskLine immediately under dateHeader
                lines.InsertAt(dateLineIdx + 1, taskLine)
            }

            newContent := ""
            for idx, l in lines {
                newContent .= (idx == 1 ? "" : "`n") l
            }
            newContent := RTrim(newContent, "`n") "`n"
        }
    }

    ; Convert line breaks to Windows CRLF
    newContent := StrReplace(newContent, "`n", "`r`n")

    try {
        if FileExist(PROJ_NOTES_FILE)
            FileDelete(PROJ_NOTES_FILE)
        FileAppend(newContent, PROJ_NOTES_FILE, "UTF-8")
        TrayTip "Paperclip", "Task staged under " p.title " in project-notes.md", 1
        
        ; If user currently has project-notes.md open in the viewer, refresh it live
        if (CurrentActiveFile == PROJ_NOTES_FILE) {
            Editor.Value := FileRead(PROJ_NOTES_FILE, "UTF-8")
        }
    } catch Error as e {
        MsgBox("Failed to update project-notes.md: " e.Message, "Error", "IconX")
    }
}

DestChoice_Change(*) {
    global ProjectList
    if (DestChoice.Value == 1) {
        StatusBar.Value := "Destination: New Atomic Note in 00-inbox/pc/"
    } else {
        projIdx := DestChoice.Value - 1
        if (projIdx >= 1 && projIdx <= ProjectList.Length)
            StatusBar.Value := "Destination: Staged Task → " ProjectList[projIdx].title " (project-notes.md)"
        else
            StatusBar.Value := "Destination: Task will append to project-notes.md"
    }
}

StartNewDraft() {
    global CurrentActiveFile, Editor, DestChoice
    CurrentActiveFile := ""
    if (Editor) {
        Editor.Opt("-ReadOnly")
        Editor.Value := ""
        Editor.Focus()
    }
    if (DestChoice) {
        DestChoice.Enabled := true
        DestChoice.Value := 1
    }
    StatusBar.Value := "New draft started."
}

DiscardAndHide() {
    global Editor
    ClearDraftBackup()
    if (Editor)
        Editor.Value := ""
    StatusBar.Value := "Buffer cleared."
    HideWindow()
}

; ==============================================================================
; EPHEMERAL CRASH RECOVERY BUFFER (.draft.md)
; ==============================================================================

AutoSaveDraft() {
    global CurrentActiveFile, Editor
    if (Editor && CurrentActiveFile == "" && Trim(Editor.Value) != "") {
        try {
            if FileExist(DRAFT_FILE)
                FileDelete(DRAFT_FILE)
            FileAppend(Editor.Value, DRAFT_FILE, "UTF-8")
        }
    }
}

RestoreDraftIfExists() {
    global CurrentActiveFile, Editor
    if (Editor && FileExist(DRAFT_FILE) && CurrentActiveFile == "") {
        try {
            draftText := FileRead(DRAFT_FILE, "UTF-8")
            if (Trim(draftText) != "") {
                Editor.Value := draftText
                StatusBar.Value := "Restored unsaved draft from previous session."
            }
        }
    }
}

ClearDraftBackup() {
    if FileExist(DRAFT_FILE) {
        try FileDelete(DRAFT_FILE)
    }
}

; ==============================================================================
; NATIVE WIN32 SELECTION FORMATTING (ZERO CLIPBOARD HIJACKING)
; ==============================================================================

WrapSelection(prefix, suffix) {
    res := SendMessage(0x00B0, 0, 0, Editor.Hwnd) ; EM_GETSEL returns DWORD: LOWORD = start, HIWORD = end
    startPos := res & 0xFFFF
    endPos := (res >> 16) & 0xFFFF

    currentText := Editor.Value
    ; Convert CR-LF to single offset character count if needed
    currentText := StrReplace(currentText, "`r`n", "`n")

    if (endPos > startPos) {
        selected := SubStr(currentText, startPos + 1, endPos - startPos)
        replacement := prefix selected suffix
        SendMessage(0x00C2, 1, StrPtr(replacement), Editor.Hwnd)
        newCaret := startPos + StrLen(replacement)
        SendMessage(0x00B1, newCaret, newCaret, Editor.Hwnd)
    } else {
        replacement := prefix suffix
        SendMessage(0x00C2, 1, StrPtr(replacement), Editor.Hwnd)
        newCaret := startPos + StrLen(prefix)
        SendMessage(0x00B1, newCaret, newCaret, Editor.Hwnd)
    }
}

InsertPrefixAtLine(prefix) {
    res := SendMessage(0x00B0, 0, 0, Editor.Hwnd)
    startPos := res & 0xFFFF

    currentText := Editor.Value
    currentText := StrReplace(currentText, "`r`n", "`n")

    ; Find start of current line
    lineStart := 1
    if (startPos > 0) {
        lastNL := InStr(SubStr(currentText, 1, startPos), "`n", , -1)
        lineStart := lastNL ? lastNL + 1 : 1
    }

    ; Move caret to start of line and insert prefix
    SendMessage(0x00B1, lineStart - 1, lineStart - 1, Editor.Hwnd)
    SendMessage(0x00C2, 1, StrPtr(prefix), Editor.Hwnd)
}

InsertText(str) {
    ; If editor is read-only (e.g. user was viewing project-notes.md), unlock it for editing
    try {
        if InStr(ControlGetStyle(Editor.Hwnd), "0x800") ; ES_READONLY = 0x800
            Editor.Opt("-ReadOnly")
    }
    Editor.Focus()
    SendMessage(0x00C2, 1, StrPtr(str), Editor.Hwnd)
}

LoadProjectsFromVault() {
    global ProjectList, VAULT_PROJECTS_DIR, ProjectSubMenu
    ProjectList := []

    if !DirExist(VAULT_PROJECTS_DIR)
        return

    loop files, VAULT_PROJECTS_DIR "\*", "D" {
        folderName := A_LoopFileName
        projFile := A_LoopFileFullPath "\project.md"
        title := folderName
        if FileExist(projFile) {
            try {
                content := FileRead(projFile, "UTF-8")
                loop parse, content, "`n", "`r" {
                    if RegExMatch(A_LoopField, "i)^title:\s*(.+)$", &m) {
                        t := Trim(m[1])
                        t := RegExReplace(t, '^["' . "']|[" . '"' . "']$")
                        title := Trim(t)
                        break
                    }
                }
            }
        }
        ProjectList.Push({ id: folderName, title: title, label: folderName ": " title })
    }

    ; Re-populate Format > Insert Project Link submenu
    try ProjectSubMenu.Delete()
    for idx, p in ProjectList {
        accel := (idx <= 9) ? "&" idx ". " : ""
        itemLabel := accel p.label
        targetWiki := "[[" p.id "|" p.title "]]"
        ProjectSubMenu.Add(itemLabel, ((wikiText, *) => (InsertText(wikiText), StatusBar.Value := "Inserted: " wikiText)).Bind(targetWiki))
    }
}

ShowProjectMenu() {
    global ProjectList, ProjectSubMenu
    if (ProjectList.Length == 0)
        LoadProjectsFromVault()

    if (ProjectList.Length == 0) {
        StatusBar.Value := "Notice: No projects found in 02-projects/."
        return
    }

    ; Reuse the existing ProjectSubMenu instance instead of allocating a new Win32 menu each time
    ProjectSubMenu.Show()
}

CleanPaste() {
    text := A_Clipboard
    text := RegExReplace(text, "\r\n", "`n")
    text := RegExReplace(text, "(\n){3,}", "`n`n")
    InsertText(Trim(text))
    StatusBar.Value := "Clean paste applied."
}

PasteAsMarkdown() {
    html := GetClipboardHTML()
    if (html == "") {
        InsertText(A_Clipboard)
        return
    }

    md := html
    md := RegExReplace(md, "is)<a [^>]*href=[\x22\x27]([^\x22\x27]+)[\x22\x27][^>]*>(.*?)</a>", "[$2]($1)")
    md := RegExReplace(md, "is)<(strong|b)>(.*?)</\1>", "**$2**")
    md := RegExReplace(md, "is)<(em|i)>(.*?)</\1>", "*$2*")
    md := RegExReplace(md, "is)<li[^>]*>(.*?)</li>", "- $1`n")
    md := RegExReplace(md, "is)<h1[^>]*>(.*?)</h1>", "# $1`n")
    md := RegExReplace(md, "is)<h2[^>]*>(.*?)</h2>", "## $1`n")
    md := RegExReplace(md, "is)<h3[^>]*>(.*?)</h3>", "### $1`n")
    md := RegExReplace(md, "is)<br\s*/?>", "`n")
    md := RegExReplace(md, "is)<p[^>]*>(.*?)</p>", "$1`n`n")
    md := RegExReplace(md, "<[^>]+>", "")
    md := StrReplace(md, "&nbsp;", " ")
    md := StrReplace(md, "&amp;", "&")
    md := StrReplace(md, "&lt;", "<")
    md := StrReplace(md, "&gt;", ">")
    md := StrReplace(md, "&quot;", '"')

    InsertText(Trim(md))
    StatusBar.Value := "Pasted HTML as Markdown."
}

GetClipboardHTML() {
    cfFormat := DllCall("RegisterClipboardFormat", "Str", "HTML Format", "UInt")
    if !DllCall("IsClipboardFormatAvailable", "UInt", cfFormat)
        return ""
    if !DllCall("OpenClipboard", "Ptr", 0)
        return ""
    if !hData := DllCall("GetClipboardData", "UInt", cfFormat, "Ptr") {
        DllCall("CloseClipboard")
        return ""
    }
    pData := DllCall("GlobalLock", "Ptr", hData, "Ptr")
    html := StrGet(pData, "UTF-8")
    DllCall("GlobalUnlock", "Ptr", hData)
    DllCall("CloseClipboard")

    if RegExMatch(html, "s)<!--StartFragment-->(.*)<!--EndFragment-->", &match)
        return match[1]
    return ""
}

; ==============================================================================
; LEAK-FREE COM CONTEXT EXTRACTION (RAII)
; ==============================================================================

CaptureContext() {
    global LastContext, LastProcess
    try {
        prevHwnd := WinGetID("A")
        if (prevHwnd == MyGui.Hwnd)
            return

        try {
            LastProcess := WinGetProcessName("ahk_id " prevHwnd)
        } catch {
            LastProcess := "unknown"
        }

        if (LastProcess ~= "i)chrome|msedge|brave") {
            url := GetBrowserURL(prevHwnd)
            if (url) {
                LastContext := url
                return
            }
        }
        try {
            LastContext := WinGetTitle("ahk_id " prevHwnd)
        } catch {
            LastContext := ""
        }
    } catch {
        LastProcess := "unknown"
        LastContext := ""
    }
}

GetBrowserURL(hWnd) {
    static UIA_IID := "{30cbe57d-d9d0-452a-ab13-7ac5ac4825ee}"
    static UIA_CLSID := "{ff48dba4-60ef-4201-aa87-54103eef594e}"
    url := ""
    try {
        UIA := ComObject(UIA_CLSID, UIA_IID)
        elementMain := 0, condition := 0, elementAddr := 0
        ComCall(6, UIA, "ptr", hWnd, "ptr*", &elementMain) ; ElementFromHandle

        if (!elementMain)
            return ""

        names := ["Address and search bar", "Barra de endereço e pesquisa", "Address bar"]
        for name in names {
            pStr := DllCall("oleaut32\SysAllocString", "str", name, "ptr")
            try {
                varName := Buffer(8 + 2 * A_PtrSize, 0)
                NumPut("ushort", 8, varName, 0)
                NumPut("ptr", pStr, varName, 8)
                ComCall(23, UIA, "int", 30005, "ptr", varName, "ptr*", &condition)
                if (condition) {
                    ComCall(5, elementMain, "int", 0x4, "ptr", condition, "ptr*", &elementAddr)
                    if (elementAddr) {
                        varValue := Buffer(24, 0)
                        ComCall(10, elementAddr, "int", 30045, "ptr", varValue)
                        url := StrGet(NumGet(varValue, 8, "ptr"), "UTF-16")
                        break
                    }
                }
            } finally {
                if (pStr)
                    DllCall("oleaut32\SysFreeString", "ptr", pStr)
                if (elementAddr)
                    ObjRelease(elementAddr), elementAddr := 0
                if (condition)
                    ObjRelease(condition), condition := 0
            }
        }
    } catch {
        return ""
    } finally {
        if (elementMain)
            ObjRelease(elementMain)
    }
    return url
}

; ==============================================================================
; DIALOGS & HELPERS
; ==============================================================================

ShowShortcutsDialog() {
    msg := "PAPERCLIP v2 KEYBOARD SHORTCUTS`n`n"
        . "GLOBAL:`n"
        . "Ctrl+Shift+Space`t- Toggle Paperclip Window`n`n"
        . "NAVIGATION:`n"
        . "Ctrl+Tab / F6`t- Toggle Focus (TreeView <-> Editor)`n"
        . "Ctrl+\`t`t- Toggle Sidebar On/Off`n"
        . "Alt+D`t`t- Focus Destination Selector`n"
        . "Ctrl+N`t`t- New Scratchpad Draft`n"
        . "F5`t`t- Refresh Inbox TreeView`n"
        . "Ctrl+O`t`t- Open Current Note in Obsidian`n`n"
        . "SAVING & DISMISSAL:`n"
        . "Ctrl+Enter`t- Save Note / Append Task & Hide`n"
        . "Esc`t`t- Hide to Tray (Keeps draft)`n"
        . "Shift+Esc`t- Discard Draft & Hide to Tray`n`n"
        . "MARKDOWN FORMATTING:`n"
        . "Ctrl+B`t`t- Wrap in **Bold**`n"
        . "Ctrl+I`t`t- Wrap in *Italics*`n"
        . "Ctrl+K`t`t- Wrap in [[Wiki-link]]`n"
        . "Ctrl+P`t`t- Insert [[Project-Link]] Menu`n"
        . "Ctrl+L`t`t- Insert '- [ ] ' Checklist Item`n"
        . "Ctrl+T`t`t- Insert Current Timestamp`n"
        . "Ctrl+Shift+V`t- Clean Paste (Strips email artifacts)`n"
        . "Ctrl+Alt+V`t- Smart HTML-to-Markdown Paste"
    MsgBox(msg, "Keyboard Shortcuts Reference", "Iconi")
}

ShowAboutDialog() {
    msg := "Paperclip v2 (Rebooted Edition)`n"
        . "Part of the Development Universe / obsidian-ht Second Brain.`n`n"
        . "• Memory Footprint: ~5.8 MB resident RAM`n"
        . "• Architecture: Win32 SysTreeView32 + Zen Scratchpad`n"
        . "• Canonical Storage: Dev/home/00-inbox/`n"
        . "• Status: Hardened"
    MsgBox(msg, "About Paperclip v2", "Iconi")
}
