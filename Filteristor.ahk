; the Filteristor switches to windows or opens recent items with given string

global MyWindowId := 0
global Config := {}
Config.FilterModes := {"^f":"Favorites", "^b":"Bookmarks", "^r":"Recent", "^w":"Word", "^x":"eXcel", "^p":"Pdf"}
Config.Launch := {}
Config.Path["Bookmarks"] := localAppData "\Microsoft\Edge\User Data\Default\Bookmarks"
Config.Modes := {"Recent": ".", "Word": "i)\.doc[xm]?$", "eXcel": "i)\.xls[xm]?$", "Pdf": "i)\.pdf$"}
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
        Switch, match1 {
            Case "Hotkey":
                Switch, match2 {
                    Case "Launch": Config.Launch[match3] := match5
                    Case "Save": Config.Hotkey["Save"] := match3
                    Default: Config.FilterModes[match3] := match2
                }
            Case "Mode": {
                Config.Filtermodes[match3] := match2
                Config.Modes[match2] := match5
                }
            Case "Sniplets": {
                Config.Filtermodes[match3] := match2
                Config.Sniplets[match2] := match5
            }
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
modeList := "openWindows|Directories"
for hotkey, mode in Config.FilterModes
    modeList .= "|" mode
Menu, Tray, NoStandard
Menu, Tray, Add, Help, ShowHelp
Menu, Tray, Add, Exit, ExitApp
Menu, Tray, Default, Help

if (Config.Launch.Count() = 0)
    Config.Launch := {"#!f":"openWindows"}
for hotkey, mode in Config.Launch
    Hotkey, %hotkey%, LaunchFilteristor
return

LaunchFilteristor:
{
    if (MyWindowId > 0) {
        WinActivate, ahk_id %MyWindowId%
        WinRestore, ahk_id %MyWindowId%
        Return
    }
    global CachedList := []
    global ItemList := []
    global SelectedIndex := 1
    global PresetIndex := 1
    global CaseSensitive := false
    RecentItemList := []
    RecentItemListBuilt := false
    if (Config.Launch.HasKey(A_ThisHotkey))
        FilterMode := Config.Launch[A_ThisHotkey]
    else
        FilterMode := "openWindows"

    Gui, +AlwaysOnTop +ToolWindow
    Gui, +LastFound
    Gui, Font, s10
    Gui, Add, Edit, x10 y10 w280 vSearchInput gUpdateList
    Gui, Add, Checkbox, x+10 yp w50 h22 vCaseToggle gToggleCase, case
    Gui, Add, DropDownList, x+8 yp w120 vModeSelector gModeChanged, %modeList%
    Gui, Add, Button, x+10 yp w22 h22 gShowHelp, ?
    Gui, Add, ListBox, x10 y+10 w500 h200 vWindowBox gListBoxChanged
    Gui, Show,, Filteristor
    GuiControl, ChooseString, ModeSelector, %FilterMode%
    MyWindowId := WinExist()
    global PredefinedHotkeys := "^f,^b,^w,^x,^p,^r,^1"
    for hotkey, mode in Config.FilterModes {
        if hotkey not in %PredefinedHotkeys%
        {
            Hotkey, %hotkey%, HandleModeHotkey
            Hotkey, %hotkey%, On
        }
    }
    for hotkey, action in Config.Actions {
        if hotkey not in %PredefinedHotkeys%
        {
            Hotkey, %hotkey%, selection
            Hotkey, %hotkey%, On
        }
    }
    if (Config.Hotkey.HasKey("Save")) {
        Hotkey, % Config.Hotkey["Save"], SaveSniplets
        Hotkey, % Config.Hotkey["Save"], On
    }
    Gosub, ModeChanged
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
 - Press Ctrl-1 to maximise the current selection on screen 1 (more keys configurable)
 - Press Shift-Backspace to close the selected window or remove the recent item link or sniplet line
 – Press Ctrl-Plus to add the current filter text to the sniplet collection
 - Press Esc to close the Filteristor

Modes & Shortcuts:
 - Ctrl-O to switch between your (O)pen windows (default)
 - Ctrl-F to open one of your (F)avorites
 - Ctrl-B to open one of your (B)ookmarks
 - Ctrl-R to open (R)ecently used documents or directories
 - Ctrl-D to open recently used (D)irectories
 - Ctrl-P to open recently used (P)df documents
 - Ctrl-W to open recently used (W)ord documents
 - Ctrl-X to open recently used e(X)cel sheets
 - Ctrl-C to toggle (C)ase sensitive search
 - Ctrl-H to show this beautiful little (H)elp
)
    Gui, +AlwaysOnTop
return

ModeChanged:
{
    Gosub, CheckPendingSaves
    CachedList := []
    GuiControlGet, FilterMode,, ModeSelector
    if (Config.Sniplets.HasKey(FilterMode)) {
        path := Config.Sniplets[FilterMode]
        Loop, Read, %path%
        {
            line := Trim(A_LoopReadLine)
            if (line != "")
                CachedList.Push({title: line, path: path})
        }
    }
    if (Config.Modes.HasKey(FilterMode)) {
        GuiControl, , ModeSelector, filtering ...
        GuiControl, ChooseString, ModeSelector, filtering ...
        Gosub, UpdateList
        GuiControl, , ModeSelector, |
        GuiControl, , ModeSelector, %modeList%
        GuiControl, ChooseString, ModeSelector, %FilterMode%
        return
    } else if (FilterMode = "Bookmarks") {
        EnvGet, localAppData, LOCALAPPDATA
        bookmarksFile := Config.Path["Bookmarks"]
        if !FileExist(bookmarksFile)
            return
        FileRead, rawJson, %bookmarksFile%
        currentName := ""
        Loop, Parse, rawJson, `n, `r
        {
            line := Trim(A_LoopField)
            if (RegExMatch(line, """name"":\s*""(.*?)""", nameMatch)) {
                currentName := nameMatch1
            } else if (RegExMatch(line, """url"":\s*""(.*?)""", urlMatch)) {
                CachedList.Push({title: currentName, path: urlMatch1})
                currentName := ""  ; Reset für nächsten Block
            }
        }
        Gosub, UpdateList
    } else if (FilterMode = "Favorites") {
        EnvGet, userProfile, USERPROFILE
        favFolder := userProfile "\Favorites"
        Loop, Files, %favFolder%\*.lnk
        {
            FileGetShortcut, %A_LoopFileFullPath%, target
            if (target = "" || !FileExist(target))
                continue
            FileGetTime, modTime, %A_LoopFileFullPath%, M
            if ErrorLevel
                continue
            displayName := StrReplace(A_LoopFileName, ".lnk", "")
            CachedList.Push({path: target, title: displayName})
        }
        Gosub, UpdateList
    } else
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
    } else if (FilterMode = "Favorites" || FilterMode = "Bookmarks" || Config.Sniplets.HasKey(FilterMode)) {
         for index, item in CachedList {
             if InStr(item.title, FilterText) {
                 ItemList.Push(item)
                 GuiControl,, WindowBox, % item.title
             }
         }
     } else if (Filtermode = "Directories" || Config.Modes.HasKey(FilterMode)) { ; recentItems-based filters
        filterRegex := Config.Modes[FilterMode]

        recentFolder := A_AppData "\Microsoft\Windows\Recent"
        if (!RecentItemListBuilt) {
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
            RecentItemList := tempList
            RecentItemListBuilt := true
        }

        for index, item in RecentItemList {
            if (FilterMode = "Directories" && !InStr(FileExist(item.path), "D"))
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
    } else {
        MsgBox, Unhandled FilterMode %FilterMode%
    }
    if (ItemList.Length() > 0) {
        SelectedIndex := PresetIndex
        PresetIndex := 1
        GuiControl, Choose, WindowBox, %SelectedIndex%
    }
    return
}

Selection:
{
    if (SelectedIndex < 1 || SelectedIndex > ItemList.Length())
        return
    Hotkey := A_ThisHotkey
    selectedItem := ItemList[SelectedIndex]
    windowId := ""

    if (FilterMode = "openWindows") {
        windowId := selectedItem.id
        WinActivate, ahk_id %windowId%
    } else if (Config.Sniplets.HasKey(FilterMode)) {
        MyWindowId := 0
        Gui, Destroy
        SendInput, % selectedItem.title
        return
    } else {
        Run, % selectedItem.path,,, pid
        if (pid != "") {
            WinWait, ahk_pid %pid%,, 5
            windowId := WinExist("ahk_pid " pid)
        } else {
            WinWaitActive,, 5
            windowId := WinExist("A")
        }
    }
    if (windowId && Config.Actions.HasKey(Hotkey)) {
        action := Config.Actions[Hotkey]
        monitorNr := action.monitor
        dim := StrSplit(action.dimensions, ",", " ")
        ; MsgBox hotkey %Hotkey%, action %action% --> Config.Actions["^1"] :: %monitorNr% ::: %dim%, 3
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
    }
    MyWindowId := 0
    Gui, Destroy
    return
}
SnipletsChanged:
{
    SavePending := FilterMode
    if (!Config.Hotkey.HasKey("Save"))
        Gosub, SaveSniplets
    return
}
CheckPendingSaves:
{
    if (SavePending) {
        MsgBox, 4100,, Save unsaved changes?
        IfMsgBox, Yes
            Gosub, SaveSniplets
    }
    SavePending := ""
    return
}
SaveSniplets:
{
    if !Config.Sniplets.HasKey(SavePending)
        return

    path := Config.Sniplets[SavePending]
    FileDelete, %path%

    Loop, % CachedList.MaxIndex()
    {
        item := CachedList[A_Index]
        FileAppend, % item.title . "`n", %path%
    }
    SavePending := ""
    return
}
HandleModeHotkey:
{
    if !WinActive("ahk_class AutoHotkeyGUI") {
        SendInput, %A_ThisHotkey%
        return
    }
    if (Config.FilterModes.HasKey(A_ThisHotkey)) {
        FilterMode := Config.FilterModes[A_ThisHotkey]
        GuiControl, ChooseString, ModeSelector, %FilterMode%
        Gosub, ModeChanged
        return
    } else {
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
^b::
^f::
    Gosub, HandleModeHotkey
    return

^o::
^d::
{
    Switch, SubStr(A_ThisHotkey, StrLen(A_ThisHotkey))
    {
        Case "o": FilterMode := "openWindows"
        Case "d": FilterMode := "Directories"
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

^Backspace::
{
    if (SelectedIndex < 1 || SelectedIndex > ItemList.Length())
        return

    selectedItem := ItemList[SelectedIndex]

    if (FilterMode = "openWindows") {
        windowId := selectedItem.id
        WinClose, ahk_id %windowId%
    } else if (Config.Sniplets.HasKey(FilterMode)) {
        Loop, % CachedList.MaxIndex()
        {
            if (CachedList[A_Index].title = selectedItem.title) {
                CachedList.RemoveAt(A_Index)
                Gosub, SnipletsChanged
                break
            }
        }
    } else if (selectedItem.HasKey("link") && FileExist(selectedItem.link)) {
        FileDelete, % selectedItem.link
        Loop % RecentItemList.Length() {
            if (RecentItemList[A_Index].link = selectedItem.link) {
                RecentItemList.RemoveAt(A_Index)
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

^+:: ; Ctrl-Plus to add new Sniplet
{
    if (Config.Sniplets.HasKey(FilterMode)) {
        GuiControlGet, newText,, SearchInput
        if (newText != "") {
            path := Config.Sniplets[FilterMode]
            CachedList.Push({title: newText, path: path})
            if (Config.Hotkey.HasKey("Save"))
                SavePending := FilterMode
            else
                FileAppend, %newText%`n, %path%
            GuiControl,, SearchInput,
            SearchInput := ""
            PresetIndex := CachedList.Length()
        }
    }
    return
}

Up::
Down::
{
    if (A_ThisHotkey = "Up")
        SelectedIndex := Max(1, SelectedIndex - 1)
    else
        SelectedIndex := Min(ItemList.Length(), SelectedIndex + 1)

    GuiControl, Choose, WindowBox, %SelectedIndex%
    return
}
^Up::
^Down::
{
    if (Config.Sniplets.HasKey(FilterMode) && SelectedIndex >= 1 && SelectedIndex <= ItemList.Length()) {
        selectedTitle := ItemList[SelectedIndex].title
        currentIndex := 0
        newIndex := 1
        Loop, % CachedList.MaxIndex()
        {
            if (CachedList[A_Index].title = selectedTitle) {
                if (A_ThisHotkey = "^Up") {
                    movedItem := CachedList.RemoveAt(A_Index)
                    CachedList.InsertAt(newIndex, movedItem)
                    Gosub, SnipletsChanged
                    PresetIndex := Max(1, SelectedIndex - 1)
                    Gosub, UpdateList
                    return
                } else
                    currentIndex := A_Index
            }
            else if (InStr(CachedList[A_Index].title, FilterText, CaseSensitive ? 1 : 0)) {
                newIndex := A_Index
                if (A_ThisHotkey = "^Down" && currentIndex > 0)
                    break
            }
        }
    }
    if (newIndex > currentIndex) {
        movedItem := CachedList.RemoveAt(currentIndex)
        CachedList.InsertAt(Min(newIndex, CachedList.Length() + 1), movedItem)
        Gosub, SnipletsChanged
        PresetIndex := Min(SelectedIndex + 1, CachedList.Length())
        Gosub, UpdateList
    }
    return
}
Esc::
GuiClose:
    MyWindowId := 0
    Gosub, CheckPendingSaves
    for hotkey, mode in Config.FilterModes {
        if hotkey not in %PredefinedHotkeys%
            Hotkey, %hotkey%, Off
    }
    for hotkey, action in Config.Actions {
        if hotkey not in %PredefinedHotkeys%
            Hotkey, %hotkey%, Off
    }
    if (Config.Hotkey.HasKey("Save"))
        Hotkey, % Config.Hotkey["Save"], Off
    Gui, Destroy
    return
#IfWinActive

ExitApp:
ExitApp
