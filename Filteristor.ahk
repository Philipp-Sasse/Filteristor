#!f::   ; the Filteristor switches to windows or opens recent items with given string
{
    global ItemList := []
    RecentIndex := []
    RecentIndexBuilt := false
    FilterMode := "openWindows"

    Gui, +AlwaysOnTop +ToolWindow
    Gui, Font, s10
    Gui, Add, Edit, x10 y10 w370 vSearchInput gUpdateList
    Gui, Add, DropDownList, x+10 yp w120 vModeSelector gModeChanged, openWindows|favorites|bookmarks|recent|word|excel|pdf|directories|filtering ...
    Gui, Add, ListBox, x10 y+10 w500 h200 vWindowBox
    Gui, Show,, Filteristor
    GuiControl, ChooseString, ModeSelector, %FilterMode%
    Gosub, UpdateList
    return
}
ModeChanged:
{
    GuiControlGet, FilterMode,, ModeSelector
    Gosub, UpdateList
    return
}
UpdateList:
{
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
            if (title != "" && title != "Filteristor" && title != "Program Manager" && InStr(title, FilterText) && class != "PopupHost") {
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
            FileGetTime, modTime, %A_LoopFileFullPath%, M

            if !FileExist(target)
                continue
            if (!InStr(target, FilterText))
                continue

            displayName := StrReplace(A_LoopFileName, ".lnk", "")
            ItemList.Push({path: target, title: displayName})
            GuiControl,, WindowBox, %displayName%
        }
    } else if (FilterMode = "bookmarks") {
        EnvGet, localAppData, LOCALAPPDATA
        bookmarksFile := localAppData "\Microsoft\Edge\User Data\Default\Bookmarks"
        if !FileExist(bookmarksFile)
            return

        FileRead, rawJson, %bookmarksFile%
        ItemList := []
        GuiControl,, WindowBox, |

        currentName := ""
        Loop, Parse, rawJson, `n, `r
        {
            line := Trim(A_LoopField)
            if (RegExMatch(line, """name"":\s*""(.*?)""", nameMatch)) {
                currentName := nameMatch1
            } else if (RegExMatch(line, """url"":\s*""(.*?)""", urlMatch)) {
                if (InStr(currentName, FilterText)) {
                    ItemList.Push({title: currentName, path: urlMatch1})
                    GuiControl,, WindowBox, %currentName%
                }
                currentName := ""  ; Reset für nächsten Block
            }
        }
    } else if (FilterMode ~= "i)recent|word|excel|pdf|directories") {
        if (!RecentIndexBuilt) {
            recentFolder := A_AppData "\Microsoft\Windows\Recent"
            tempList := []

            Loop, Files, %recentFolder%\*.lnk
            {
                FileGetShortcut, %A_LoopFileFullPath%, target
                FileGetTime, modTime, %A_LoopFileFullPath%, M

                if !FileExist(target)
                    continue

                displayName := StrReplace(A_LoopFileName, ".lnk", "")
                tempList.Push({path: target, title: displayName, time: modTime})
            }
            tempList.Sort("time D")
            RecentIndex := tempList
            RecentIndexBuilt := true
        }
        recentFolder := A_AppData "\Microsoft\Windows\Recent"

        for index, item in RecentIndex {
            if (FilterMode = "word" && !InStr(item.path, ".docx"))
                continue
            if (FilterMode = "excel" && !InStr(item.path, ".xlsx"))
                continue
            if (FilterMode = "pdf" && !InStr(item.path, ".pdf"))
                continue
            if (FilterMode = "directories" && !InStr(FileExist(item.path), "D"))
                continue
            if (!InStr(item.title, FilterText))
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

#IfWinActive Filteristor
^o::
^f::
^b::
^r::
^w::
^x::
^p::
^d::
{
    Switch, SubStr(A_ThisHotkey, StrLen(A_ThisHotkey))
    {
        Case "o": FilterMode := "openWindows"
        Case "f": FilterMode := "favorites"
        Case "b": FilterMode := "bookmarks"
        Case "r": FilterMode := "recent"
        Case "p": FilterMode := "pdf"
        Case "w": FilterMode := "word"
        Case "x": FilterMode := "excel"
        Case "d": FilterMode := "directories"
    }
    GuiControl, ChooseString, ModeSelector, filtering ...
    Gosub, UpdateList
    GuiControl, ChooseString, ModeSelector, %FilterMode%
    return
}

~Enter::
{
    GuiControlGet, selectedTitle,, WindowBox
    if (selectedTitle != "") {
        if (FilterMode = "openWindows") {
            cleanTitle := StrReplace(selectedTitle, ">>>", "|")
            WinActivate, %cleanTitle%
        } else if (FilterMode = "bookmarks") {
            Run, % ItemList[selectedIndex].path
        } else {
            selectedIndex := 0
            Loop, % ItemList.Length()
            {
                if (ItemList[A_Index].title = selectedTitle) {
                    selectedIndex := A_Index
                    break
                }
            }
            Run, % ItemList[selectedIndex].path
        }
        Gui, Destroy
    }
    return
}

Tab::
{
    ControlGetFocus, focusedControl, A
    if (focusedControl != "Edit1")  ; Name des Eingabefelds prüfen
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
            if (StrLen(title) < StrLen(prefix) + 1)
                return

            char := SubStr(title, StrLen(prefix) + 1, 1)
            if (nextChar = "")
                nextChar := char
            else if (char != nextChar)
                return
        }
        SendInput, %nextChar%
        Sleep, 10
        prefix .= nextChar
    }

ControlSetText, Edit1, %prefix%, Filteristor
SearchInput := prefix
    Gosub, UpdateList
    return
}

~Up::
~Down::
{
    GuiControlGet, currentSelection,, WindowBox
    selectedIndex := 0
    Loop, % ItemList.Length()
    {
        if (ItemList[A_Index].title = currentSelection) {
            selectedIndex := A_Index
            break
        }
    }

    if (A_ThisHotkey = "~Up")
        selectedIndex := Max(1, selectedIndex - 1)
    else
        selectedIndex := Min(ItemList.Length(), selectedIndex + 1)

    GuiControl, Choose, WindowBox, %selectedIndex%
    return
}
~Esc::
    Gui, Destroy
    return
GuiClose:
    Gui, Destroy
    return
#IfWinActive
