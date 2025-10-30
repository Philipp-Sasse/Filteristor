; the Filteristor switches to windows or opens recent items with given string

global Config := {}
Config.Launch := "#!f"
Config.Path["Bookmarks"] := localAppData "\Microsoft\Edge\User Data\Default\Bookmarks"
Config.Modes := {}
Config.Modes["^r"] := {name: "Recent", filter: "."}
Config.Modes["^w"] := {name: "Word", filter: "i)\.doc[xm]?$"}
Config.Modes["^x"] := {name: "eXcel", filter: "i)\.xls[xm]?$"}
Config.Modes["^p"] := {name: "Pdf", filter: "i)\.pdf$"}
Config.Actions["^1"] := {monitor: 1, dimensions: "x"}
Config.Exclude := []

configFile := A_ScriptDir "\Filteristor.config"
Loop
{
    FileReadLine, line, %configFile%, %A_Index%
    if ErrorLevel
        break
    if RegExMatch(line, "^\s*(\S*) +([^:]*):\s*([^\t]*)(\t+(.*))?$", match)
    {
        ;MsgBox, Command "%match1%", target "%match2%", key "%match3%", parameter "%match5%"
        Switch, match1
        {
            Case "Hotkey":
                Switch, match2
                {
                    Case "Launch": Config.Launch := match3
                    Default: MsgBox, Unknown Hotkey "%match2%" in line %A_Index%
                }
            Case "Mode": Config.Modes[match3] := {name: match2, filter: match5}
            Case "Sniplets": Config.Sniplets[match3] := {name: match2, path: match5}
            Case "Monitor": Config.Actions[match3] := {monitor: match2, dimensions: match5}
            Case "Path": Config.Path[match2] := match3
            Case "Exclude": Config.Exclude.Push({ scope: match2, filter: match3})
            Default:
                MsgBox, Unknown command %match1% in line %A_Index%
        }
    }
    else
        MsgBox, 4, , Line #%A_Index%: Cannot parse "%line%". Continue?
    IfMsgBox, No
        return
}
modeList := "openWindows|favorites|bookmarks|directories"
for hotkey, mode in Config.Modes
    modeList .= "|" mode.name
Menu, Tray, NoStandard
Menu, Tray, Add, Help, ShowHelp
Menu, Tray, Add, Exit, ExitApp
Menu, Tray, Default, Help

Hotkey, % Config.Launch, LaunchFilteristor
return
LaunchFilteristor:
{
    global ItemList := []
    global SelectedIndex := 1
    global CaseSensitive := false
    RecentIndex := []
    RecentIndexBuilt := false
    FilterMode := "openWindows"

    Gui, +AlwaysOnTop +ToolWindow
    Gui, Font, s10
    Gui, Add, Edit, x10 y10 w280 vSearchInput gUpdateList
    Gui, Add, Checkbox, x+10 yp w50 h22 vCaseToggle gToggleCase, case
    Gui, Add, DropDownList, x+8 yp w120 vModeSelector gModeChanged, %modeList%
    Gui, Add, Button, x+10 yp w22 h22 gShowHelp, ?
    Gui, Add, ListBox, x10 y+10 w500 h200 vWindowBox gListBoxChanged
    Gui, Show,, Filteristor
    GuiControl, ChooseString, ModeSelector, %FilterMode%
    ;PredefinedHotkeys := ["^w", "^x", "^p", "^r", "^1"]
    PredefinedHotkeys := "^w,^x,^p,^r,^1"
    for hotkey, mode in Config.Modes {
        if hotkey not in "^w,^x,^p,^r,^1"
            Hotkey, %hotkey%, HandleModeHotkey
    }
    for hotkey, mode in Config.Sniplets {
        if hotkey not in %PredefinedHotkeys%
            Hotkey, %hotkey%, HandleModeHotkey
    }
    for hotkey, action in Config.Actions {
        if hotkey not in %PredefinedHotkeys%
            Hotkey, %hotkey%, selection
    }
    Gosub, UpdateList
    return
}

ShowHelp:
    Gui, -AlwaysOnTop
    MsgBox, 64, Filteristor Help,
    (
Filteristor: Your Friendly Neighborhood Filter Guide
helps you quickly switch between open windows or launch documents, bookmarks and more.

How to Use:
 - Start typing to filter the list
 - Press Tab to auto-complete
 - Press Down and Up to navigate the list
 - Press Return to run or bring to front the current selection
 - Press Ctrl+1 to maximise the current selection on screen 1 (more keys configurable)
 - Press Shift-Backspace to close the selected window or remove the recent item link
 - Press Esc to close the Filteristor

Modes & Shortcuts:
 - Ctrl+O to switch between your (O)pen windows (default)
 - Ctrl+F to open one of your (F)avorites
 - Ctrl+B to open one of your (B)ookmarks
 - Ctrl+R to open (R)ecently used documents or directories
 - Ctrl+D to open recently used (D)irectories
 - Ctrl+P to open recently used (P)df documents
 - Ctrl+W to open recently used (W)ord documents
 - Ctrl+X to open recently used e(X)cel sheets
 - Ctrl+C to toggle (C)ase sensitive search
 - Ctrl+H to show this beautiful little (H)elp
)
    Gui, +AlwaysOnTop
return

ModeChanged:
{
    GuiControlGet, FilterMode,, ModeSelector
    Gosub, UpdateList
    return
}
ToggleCase:
{
    GuiControlGet, CaseSensitive,, CaseToggle
    GuiControl,, CaseToggle, % CaseSensitive ? "CaSe" : "case"
    Gosub, UpdateList
    return
}
ListBoxChanged:
{
    GuiControlGet, selectedTitle,, WindowBox
    SelectedIndex := 0
    Loop, % ItemList.Length()
    {
        if (ItemList[A_Index].title = selectedTitle) {
            SelectedIndex := A_Index
            break
        }
    }
    Gosub, selection
    return
}
IsExcluded(item, mode) {
    Loop % Config.Exclude.Length() {
        scope := Config.Exclude[A_Index].scope
       filter := Config.Exclude[A_Index].filter
       if (scope = "*" or scope = mode) {
           if (RegExMatch(item, filter))
               return True
           }
    }
    return False
}
UpdateList:
{
    global ItemList, SelectedIndex, CaseSensitive, FilterMode
    GuiControlGet, FilterText,, SearchInput
    ItemList := []
    GuiControl,, WindowBox, |

    if (FilterMode = "openWindows") {
        WinGet, idList, List
        Loop, % idList
        {
            this_id := idList%A_Index%
            WinGetTitle, title, ahk_id %this_id%
            WinGetClass, class, ahk_id %this_id%
            if (title != "" && title != "Filteristor" && title != "Program Manager"
                    && InStr(title, FilterText, CaseSensitive ? 1 : 0)
                    && class != "PopupHost"
                    && !IsExcluded(title, FilterMode)) {
                cleanTitle := StrReplace(title, "|", ">>>")
                ItemList.Push({id: this_id, title: cleanTitle})
                GuiControl,, WindowBox, %cleanTitle%
            }
        }
    } else if (FilterMode = "favorites") {
        EnvGet, userProfile, USERPROFILE
        favFolder := userProfile "\Favorites"
        Loop, Files, %favFolder%\*.lnk
        {
            FileGetShortcut, %A_LoopFileFullPath%, target
            if (target = "" || !FileExist(target))
                continue
            if (!InStr(target, FilterText, CaseSensitive ? 1 : 0))
                continue
            if (IsExcluded(target, FilterMode))
                continue

            FileGetTime, modTime, %A_LoopFileFullPath%, M
            if ErrorLevel
                continue
            displayName := StrReplace(A_LoopFileName, ".lnk", "")
            ItemList.Push({path: target, title: displayName})
            GuiControl,, WindowBox, %displayName%
        }
    } else if (FilterMode = "bookmarks") {
        EnvGet, localAppData, LOCALAPPDATA
        bookmarksFile := Config.Path["Bookmarks"]
        if !FileExist(bookmarksFile)
            return
        FileRead, rawJson, %bookmarksFile%
        GuiControl,, WindowBox, |

        currentName := ""
        Loop, Parse, rawJson, `n, `r
        {
            line := Trim(A_LoopField)
            if (RegExMatch(line, """name"":\s*""(.*?)""", nameMatch)) {
                currentName := nameMatch1
            } else if (RegExMatch(line, """url"":\s*""(.*?)""", urlMatch)) {
                if (InStr(currentName, FilterText, CaseSensitive ? 1 : 0) && !IsExcluded(currentName, FilterMode)) {
                    ItemList.Push({title: currentName, path: urlMatch1})
                    GuiControl,, WindowBox, %currentName%
                }
                currentName := ""  ; Reset für nächsten Block
            }
        }
    } else { ; all recentItems-based filters
        filterRegex := "."
        snipletPath = ""
        for hotkey, mode in Config.Modes
        {
            if (mode.name = FilterMode) {
                if (mode.path) {
                    snipletPath = mode.path
                } else {
                    filterRegex := mode.filter
                }
                break
            }
        }

        recentFolder := A_AppData "\Microsoft\Windows\Recent"
        if (!RecentIndexBuilt) {
            tempList := []

            Loop, Files, %recentFolder%\*.lnk
            {
                FileGetShortcut, %A_LoopFileFullPath%, target
                if (target = "" || !FileExist(target))
                    continue
                FileGetTime, modTime, %A_LoopFileFullPath%, M
                if ErrorLevel
                    continue

                displayName := StrReplace(A_LoopFileName, ".lnk", "")
                tempList.Push({path: target, title: displayName, time: modTime, link: A_LoopFileFullPath})
            }
            tempList.Sort("time D")
            RecentIndex := tempList
            RecentIndexBuilt := true
        }

        for index, item in RecentIndex {
            if (FilterMode = "directories" && !InStr(FileExist(item.path), "D"))
                continue
            if (!RegExMatch(item.path, filterRegex))
                continue
            if (!InStr(item.title, FilterText, CaseSensitive ? 1 : 0))
                continue
            if (IsExcluded(item.title, FilterMode))
                continue

            ItemList.Push(item)
            GuiControl,, WindowBox, % item.title
        }
    }
    if (ItemList.Length() > 0) {
        SelectedIndex := 1
        GuiControl, Choose, WindowBox, %SelectedIndex%
    }
    return
}

Selection:
{
    if (SelectedIndex < 1 || SelectedIndex > ItemList.Length())
        return
    selectedItem := ItemList[SelectedIndex]
    if (FilterMode = "openWindows") {
        windowId := selectedItem.id
        WinActivate, ahk_id %windowId%
    } else {
        Run, % selectedItem.path,,, pid
        if (pid != "") {
            WinWait, ahk_pid %pid%
            WinGet, windowId, ID, ahk_pid %pid%
        } else {
            WinWaitActive
            WinGet, windowId, ID, A
        }
    }
    action := Config.Actions[A_ThisHotkey]
    if (action = "") {
        Gui, Destroy
        return
    }
    monitorNr := Config.Actions[A_ThisHotkey].monitor
    dim := StrSplit(Config.Actions[A_ThisHotkey].dimensions, ",", " ")
    ; MsgBox hotkey %A_ThisHotkey%, action %action% --> Config.Actions["^1"] :: %monitorNr% ::: %dim%, 3
    SysGet, MonitorCount, MonitorCount
    if (monitorNr <= MonitorCount) {
        SysGet, Mon, MonitorWorkArea, %monitorNr%
        MonWidth := MonRight - MonLeft
        MonHeight := MonBottom - MonTop

        WinRestore, ahk_id %windowId%
        WinGetPos, WinX, WinY, WinW, WinH, ahk_id %windowId%
        WinW := min(WinW, MonWidth)
        WinH := min(WinH, MonHeight)
        NewX := MonLeft + (MonWidth - WinW) // 2
        NewY := MonTop + (MonHeight - WinH) // 2
        ; MsgBox, %dim% - %WinX% - %WinY% - %WinW% - %WinH% : %NewX% - %NewY% : %MonLeft% - %MonRight%

        if (dim[1] = "x") {
            WinMove, ahk_id %windowId%, , NewX, NewY, WinW, WinH
            WinMaximize, ahk_id %windowId%
        } else if (dim[1] = "z") {
            WinMove, ahk_id %windowId%, , NewX, NewY, WinW, WinH
        } else if (dim[1] = "%") {
            NewX := MonLeft + (dim[2] * MonWidth) // 100
            WinW := ((100 - dim[2] - dim[3]) * MonWidth) // 100
            NewY := MonTop + (dim[4] * MonHeight) // 100
            WinH := ((100 - dim[4] - dim[5]) * MonHeight) // 100
            WinMove, ahk_id %windowId%, , NewX, NewY, WinW, WinH
        }
    }
    Gui, Destroy
    return
}

HandleModeHotkey:
{
    if !WinActive("ahk_class AutoHotkeyGUI") {
        SendInput, %A_ThisHotkey%
        return
    }
    mode := Config.Modes[A_ThisHotkey]
    if (mode)
    {
        FilterMode := mode.name
        GuiControl, , ModeSelector, filtering ...
        GuiControl, ChooseString, ModeSelector, filtering ...
        Gosub, UpdateList
        GuiControl, , ModeSelector, |
        GuiControl, , ModeSelector, %modeList%
        GuiControl, ChooseString, ModeSelector, %FilterMode%
        return
    }
    mode := Config.Sniplets[A_ThisHotkey]
    if (mode)
    {
        FilterMode := mode.name
        Gosub, UpdateList
        GuiControl, ChooseString, ModeSelector, %FilterMode%
    }
    else
    {
        MsgBox, Unknown hotkey %A_ThisHotkey%
        return
    }

    return
}
#IfWinActive ahk_class AutoHotkeyGUI
^r::
^w::
^x::
^p::
    Gosub, HandleModeHotkey
    return

^o::
^f::
^b::
^d::
{
    Switch, SubStr(A_ThisHotkey, StrLen(A_ThisHotkey))
    {
        Case "o": FilterMode := "openWindows"
        Case "f": FilterMode := "favorites"
        Case "b": FilterMode := "bookmarks"
        Case "d": FilterMode := "directories"
    }
    Gosub, UpdateList
    GuiControl, ChooseString, ModeSelector, %FilterMode%
    return
}

~Enter:: Gosub, selection
^1:: Gosub, selection

^c::
{
    CaseSensitive := !CaseSensitive
    GuiControl,, CaseToggle, % CaseSensitive ? 1 : 0
    GuiControl,, CaseToggle, % CaseSensitive ? "CaSe" : "case"
    Gosub, UpdateList
    return
}

^h::
{
    Gosub, showHelp
    return
}

Tab::
{
    ControlGetFocus, focusedControl, A
    if (focusedControl != "Edit1")
        return

    GuiControlGet, FilterText,, SearchInput
    if (ItemList.Length() < 2)
        return

    prefix := FilterText
    Loop
    {
        nextChar := ""
        Loop, % ItemList.Length()
        {
            title := ItemList[A_Index].title
            start := InStr(title, prefix)
            if (!start || StrLen(title) < start + StrLen(prefix))
                return
            char := SubStr(title, start + StrLen(prefix), 1)
            if (nextChar = "")
                nextChar := char
            else if (char != nextChar)
                return ; no more matches
        }
        SendInput, %nextChar%
        Sleep, 5
        prefix .= nextChar
    }

    ControlSetText, Edit1, %prefix%, Filteristor
    SearchInput := prefix
    return
}

~+Backspace::
{
    if (SelectedIndex < 1 || SelectedIndex > ItemList.Length())
        return

    selectedItem := ItemList[SelectedIndex]

    if (FilterMode = "openWindows") {
        windowId := selectedItem.id
        WinClose, ahk_id %windowId%
    }
    else if (selectedItem.HasKey("link") && FileExist(selectedItem.link)) {
        FileDelete, % selectedItem.link
        Loop % RecentIndex.Length() {
            if (RecentIndex[A_Index].link = selectedItem.link) {
                RecentIndex.RemoveAt(A_Index)
                break
            }
        }
    }
    OldSelection := SelectedIndex
    Gosub, UpdateList
    SelectedIndex := Min(OldSelection, ItemList.Length())
    GuiControl, Choose, WindowBox, %SelectedIndex%
    return
}

~Up::
~Down::
{
    if (A_ThisHotkey = "~Up")
        SelectedIndex := Max(1, SelectedIndex - 1)
    else
        SelectedIndex := Min(ItemList.Length(), SelectedIndex + 1)

    GuiControl, Choose, WindowBox, %SelectedIndex%
    return
}
~Esc::
GuiClose:
    Gui, Destroy
    PredefinedHotkeys := ["^w", "^x", "^p", "^r", "^1"]
    for hotkey, mode in Config.Modes {
        if !(hotkey in PredefinedHotkeys*)
            Hotkey, %hotkey%, Off
    }
    for hotkey, mode in Config.Sniplets {
        if !(hotkey in PredefinedHotkeys*)
            Hotkey, %hotkey%, Off
    }
    for hotkey, action in Config.Actions {
        if !(hotkey in PredefinedHotkeys*)
            Hotkey, %hotkey%, Off
    }
    return
#IfWinActive

ExitApp:
ExitApp
