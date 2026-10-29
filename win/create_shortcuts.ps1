$WshShell = New-Object -ComObject WScript.Shell

$TargetExe = "C:\Users\helder.toucas\scoop\apps\autohotkey\current\v2\AutoHotkey64.exe"
$ScriptPath = "C:\Users\helder.toucas\Dev\paperclip\win\paperclip.ahk"
$WorkDir = "C:\Users\helder.toucas\Dev\paperclip\win"

# 1. Desktop shortcut
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$DesktopLnk = Join-Path $DesktopPath "Paperclip.lnk"
$Shortcut1 = $WshShell.CreateShortcut($DesktopLnk)
$Shortcut1.TargetPath = $TargetExe
$Shortcut1.Arguments = ('"' + $ScriptPath + '"')
$Shortcut1.WorkingDirectory = $WorkDir
$Shortcut1.Description = "Paperclip v2 - Second Brain Inbox Scratchpad"
$Shortcut1.IconLocation = ($TargetExe + ",0")
$Shortcut1.Save()

# 2. Repo root shortcut
$RepoLnk = "C:\Users\helder.toucas\Dev\paperclip\Paperclip.lnk"
$Shortcut2 = $WshShell.CreateShortcut($RepoLnk)
$Shortcut2.TargetPath = $TargetExe
$Shortcut2.Arguments = ('"' + $ScriptPath + '"')
$Shortcut2.WorkingDirectory = $WorkDir
$Shortcut2.Description = "Paperclip v2 - Second Brain Inbox Scratchpad"
$Shortcut2.IconLocation = ($TargetExe + ",0")
$Shortcut2.Save()

# 3. Windows Startup folder shortcut (runs automatically at login)
$StartupPath = [Environment]::GetFolderPath("Startup")
$StartupLnk = Join-Path $StartupPath "Paperclip.lnk"
$Shortcut3 = $WshShell.CreateShortcut($StartupLnk)
$Shortcut3.TargetPath = $TargetExe
$Shortcut3.Arguments = ('"' + $ScriptPath + '"')
$Shortcut3.WorkingDirectory = $WorkDir
$Shortcut3.Description = "Paperclip v2 - Second Brain Inbox Scratchpad"
$Shortcut3.IconLocation = ($TargetExe + ",0")
$Shortcut3.Save()

Write-Host "Shortcuts created successfully at:"
Write-Host " - $DesktopLnk"
Write-Host " - $RepoLnk"
Write-Host " - $StartupLnk"
