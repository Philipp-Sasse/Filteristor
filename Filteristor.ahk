; the Filteristor switches to windows or opens recent items with given string

global Config := {}
Config.Launch := "#!f"
Config.Path["Bookmarks"] := localAppData "\Microsoft\Edge\User Data\Default\Bookmarks"
Config.Modes := {}  ; leeres Map-Objekt
Config.Modes["^r"] := {name: "Recent", filter: "."}
Config.Modes["^w"] := {name: "Word", filter: "i)\.doc[xm]?$"}
Config.Modes["^x"] := {name: "eXcel", filter: "i)\.xls[xm]?$"}
Config.Modes["^p"] := {name: "Pdf", filter: "i)\.pdf$"}

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
            Case "Macros": Config.Modes[match3] := {name: match2, path: match5}
            Case "Path": Config.Path[match2] := match3
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
    for hotkey, mode in Config.Modes
    {
        if (hotkey != "^w" && hotkey != "^x" && hotkey != "^p" && hotkey != "^r")
            Hotkey, %hotkey%, HandleModeHotkey
    }
    for hotkey, mode in Config.Macros
    {
        if (hotkey != "^w" && hotkey != "^x" && hotkey != "^p" && hotkey != "^r")
            Hotkey, %hotkey%, HandleModeHotkey
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
 - Press Shift-Backspace to close the selected window
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
            if (title != "" && title != "Filteristor" && title != "Program Manager" && InStr(title, FilterText, CaseSensitive ? 1 : 0) && class != "PopupHost") {
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

            FileGetTime, modTime, %A_LoopFileFullPath%, M
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
                if (InStr(currentName, FilterText, CaseSensitive ? 1 : 0)) {
                    ItemList.Push({title: currentName, path: urlMatch1})
                    GuiControl,, WindowBox, %currentName%
                }
                currentName := ""  ; Reset für nächsten Block
            }
        }
    } else { ; if (FilterMode ~= "i)recent|word|excel|pdf|directories") {
        filterRegex := "."
        for hotkey, mode in Config.Modes
        {
            if (mode.name = FilterMode)
            {
                filterRegex := mode.filter
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

                displayName := StrReplace(A_LoopFileName, ".lnk", "")
                tempList.Push({path: target, title: displayName, time: modTime})
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
        itemId := selectedItem.id
        WinActivate, ahk_id %itemId%
    } else {
        Run, % selectedItem.path
    }
    Gui, Destroy
    return
}

HandleModeHotkey:
{
    ;if !WinActive("ahk_class AutoHotkeyGUI")
        ;return
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
    mode := Config.Macros[A_ThisHotkey]
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
        itemId := selectedItem.id
        WinClose, ahk_id %itemId%
        Gosub, UpdateList
    }
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
    for hotkey, mode in Config.Modes
        if (hotkey != "^w" && hotkey != "^x" && hotkey != "^p" && hotkey != "^r")
            Hotkey, %hotkey%, Off
    return
#IfWinActive

ExitApp:
ExitApp
