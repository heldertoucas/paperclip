#Requires AutoHotkey v2.0
#SingleInstance Force

; ==============================================================================
; PROJECT PAPERCLIP: Windows Desktop Edition
; Ultra-lightweight, zero-friction capture terminal.
; ==============================================================================

; Configuration
GLOBAL_HOTKEY := "^+Space"
DESTINATION_DIR := A_ScriptDir "\obsidian-ht\00-inbox\pc\"
WINDOW_WIDTH := 580
WINDOW_HEIGHT := 400
BG_COLOR := "101010"
EDITOR_BG := "161616"
TEXT_COLOR := "E0E0E0"
ACCENT_COLOR := "22D3EE"

; Domain Mapping
Domains := ["system", "pessoal", "cmlisboa", "cmlisboa", "freelance"]
CurrentDomainIndex := 1

; Persistence State
LastContext := ""
LastProcess := ""
LastSavedHash := "" ; For deduplication

; Create Directory if missing
if !DirExist(DESTINATION_DIR)
    DirCreate(DESTINATION_DIR)

; ==============================================================================
; GUI CONSTRUCTION
; ==============================================================================

MyGui := Gui("+AlwaysOnTop -Caption +Border", "Paperclip")
MyGui.BackColor := BG_COLOR
MyGui.SetFont("s10 c" TEXT_COLOR, "SF Pro Display")

; Tab Bar (Simulated with Buttons for precise styling)
Tab1 := MyGui.Add("Button", "x10 y10 w100 h30", "1: Inbox")
Tab2 := MyGui.Add("Button", "x+5 y10 w100 h30", "2: Família")
Tab3 := MyGui.Add("Button", "x+5 y10 w100 h30", "3: Passaporte")
Tab4 := MyGui.Add("Button", "x+5 y10 w100 h30", "4: Futuro")
Tab5 := MyGui.Add("Button", "x+5 y10 w100 h30", "5: Freelance")

Tabs := [Tab1, Tab2, Tab3, Tab4, Tab5]

; Editor
MyGui.SetFont("s11 c" TEXT_COLOR, "SF Mono")
Editor := MyGui.Add("Edit", "x10 y50 w560 h300 -VScroll Multi Background" EDITOR_BG " c" TEXT_COLOR, "")

; Status Bar
MyGui.SetFont("s9 c606060", "SF Pro Display")
StatusBar := MyGui.Add("Text", "x10 y360 w560 h30", "Ready")

; Events
MyGui.OnEvent("DropFiles", Gui_DropFiles)
for index, tabBtn in Tabs {
    tabBtn.OnEvent("Click", SetTab.Bind(index))
}

; Initial Tab State
SetTab(1)

; Make the borderless window movable by dragging the background
OnMessage(0x0201, WM_LBUTTONDOWN)
WM_LBUTTONDOWN(wParam, lParam, msg, hwnd) {
    if (hwnd == MyGui.Hwnd)
        PostMessage(0xA1, 2,,, "ahk_id " MyGui.Hwnd)
}

; ==============================================================================
; HOTKEYS & LOGIC
; ==============================================================================

Hotkey GLOBAL_HOTKEY, ToggleWindow

ToggleWindow(*) {
    if WinActive("ahk_id " MyGui.Hwnd) {
        MyGui.Hide()
    } else {
        ; Capture Context BEFORE showing
        CaptureContext()
        MyGui.Show("w" WINDOW_WIDTH " h" WINDOW_HEIGHT " Center")
        Editor.Focus()
    }
}

SetTab(index, *) {
    global CurrentDomainIndex := index
    for i, tabBtn in Tabs {
        if (i == index) {
            tabBtn.Opt("+Default c" ACCENT_COLOR)
        } else {
            tabBtn.Opt("-Default c" TEXT_COLOR)
        }
    }
    StatusBar.Value := "Domain: " Domains[index] " | Context: " LastProcess
}

CaptureContext() {
    global LastContext, LastProcess
    
    ; Get Active Window before Monolith
    prevHwnd := WinGetID("A")
    if (prevHwnd == MyGui.Hwnd)
        return

    LastProcess := WinGetProcessName("ahk_id " prevHwnd)
    
    ; Attempt URL extraction if browser
    if (LastProcess ~= "i)chrome|msedge|brave") {
        url := GetBrowserURL(prevHwnd)
        if (url) {
            LastContext := url
            StatusBar.Value := "Found URL: " url " (Press Tab to append)"
            return
        }
    }
    
    LastContext := WinGetTitle("ahk_id " prevHwnd)
    StatusBar.Value := "Context: " LastProcess " | " LastContext
}

; Ctrl+Enter to Save
#HotIf WinActive("ahk_id " MyGui.Hwnd)
^Enter:: {
    SaveNote()
}

; Tab to Append Context
Tab:: {
    if (LastContext) {
        if (LastContext ~= "^http")
            Editor.Value .= "`n`n[Source](" LastContext ")"
        else
            Editor.Value .= "`n`nContext: " LastContext
        
        StatusBar.Value := "Context appended."
    }
}

; Esc to Hide
Esc:: MyGui.Hide()

; Ctrl+Esc to Clear
^Esc:: {
    Editor.Value := ""
    StatusBar.Value := "Buffer cleared."
}

; Numbers to switch tabs
^1:: SetTab(1)
^2:: SetTab(2)
^3:: SetTab(3)
^4:: SetTab(4)
^5:: SetTab(5)
#HotIf

Gui_DropFiles(GuiObj, GuiCtrlObj, FileArray, *) {
    for i, file in FileArray {
        Editor.Value .= "`n`n[File](" file ")"
    }
    StatusBar.Value := "Files appended."
}

SaveNote() {
    global LastSavedHash
    text := Editor.Value
    if (Trim(text) == "") {
        StatusBar.Value := "Error: Empty note."
        return
    }

    ; Sequential Deduplication (Simple content comparison)
    if (text == LastSavedHash) {
        StatusBar.Value := "Duplicate blocked."
        MyGui.Hide()
        return
    }

    ; Extract Title
    lines := StrSplit(text, "`n")
    title := Trim(lines[1])
    if (title == "")
        title := "Untitled Note"
    
    ; Format Filename
    ts := FormatTime(, "yyyyMMdd-HHmmss")
    filename := ts "-pc.md"
    filepath := DESTINATION_DIR filename
    
    ; YAML Frontmatter
    domain := Domains[CurrentDomainIndex]
    created := FormatTime(, "yyyy-MM-dd")
    
    yaml := "---" "`n"
    yaml .= 'title: "' title '"' "`n"
    yaml .= "type: source" "`n"
    yaml .= "domain: " domain "`n"
    yaml .= "context: " LastProcess "`n"
    yaml .= "status: draft" "`n"
    yaml .= "created: " created "`n"
    yaml .= "---" "`n`n"
    
    ; Write File
    try {
        FileAppend(yaml text, filepath, "UTF-8")
        LastSavedHash := text
        Editor.Value := ""
        MyGui.Hide()
        TrayTip "Paperclip", "Note saved: " filename
    } catch Error as e {
        StatusBar.Value := "Error saving: " e.Message
    }
}

; ==============================================================================
; BROWSER URL EXTRACTION (UIAutomation Lightweight)
; ==============================================================================

GetBrowserURL(hWnd) {
    ; CLSID_CUIAutomation := "{ff48dba4-60ef-4201-aa87-54103eef594e}"
    ; IID_IUIAutomation    := "{30cbe57d-d9d0-452a-ab13-7ac5ac4825ee}"
    try {
        UIA := ComObject("{ff48dba4-60ef-4201-aa87-54103eef594e}", "{30cbe57d-d9d0-452a-ab13-7ac5ac4825ee}")
        
        ; ElementFromHandle
        ComCall(6, UIA, "ptr", hWnd, "ptr*", &elementMain := 0)
        
        ; Create Condition for "Address and search bar"
        ; Using a simpler approach: finding by Name property
        ; In non-English Windows, this might need localization
        
        ; Property ID 30005 = UIA_NamePropertyId
        ; We'll try common names
        names := ["Address and search bar", "Barra de endereço e pesquisa", "Address bar"]
        
        for name in names {
            pStr := DllCall("oleaut32\SysAllocString", "str", name, "ptr")
            
            ; Create variant
            varName := Buffer(8 + 2 * A_PtrSize, 0)
            NumPut("ushort", 8, varName, 0) ; VT_BSTR
            NumPut("ptr", pStr, varName, 8)
            
            ComCall(23, UIA, "int", 30005, "ptr", varName, "ptr*", &condition := 0)
            
            ; FindFirst (TreeScope_Descendants = 0x4)
            ComCall(5, elementMain, "int", 0x4, "ptr", condition, "ptr*", &elementAddr := 0)
            
            if (elementAddr) {
                ; Get current value (30045 = UIA_ValueValuePropertyId)
                varValue := Buffer(24, 0)
                ComCall(10, elementAddr, "int", 30045, "ptr", varValue)
                url := StrGet(NumGet(varValue, 8, "ptr"), "UTF-16")
                return url
            }
        }
    }
    return ""
}
