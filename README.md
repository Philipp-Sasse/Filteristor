# Filteristor
*Filteristor: Your Friendly Neighborhood Filter Guide*

Filteristor is a lightweight AutoHotkey utility that lets you quickly switch between open windows, recent files, favorites and bookmarks with filtered lists, fast and easy to use with the keyboard alone.

## Features
- Hotkey-driven mode switching (Ctrl+O for **O**pen windows, Ctrl+B for **B**ookmarks, Ctrl-P for recent **P**dfs, etc.)
- Currently 8 built-in modes
- Define additional modes or custom hotkeys with optional config file
- Live filtering of items via text input with Tab completion
- Instant activation of selected item via Return
- Arrow key navigation within the list

## How It Works
- Press Alt+Win+F to open Filteristor (configurable)
- Start typing to filter the list
- Press Tab to auto-complete filter text until next significant letter
- Press Down and Up to navigate the list
- Press Return to run or bring to front the current selection
- Press Ctrl+1 to maximise the current selection on screen 1
- Press Shift+Backspace to close the selected window or remove recent link
- Press Esc to close the Filteristor
- Press Ctrl+C to toggle **C**ase sensitive search
- Switch modes using hotkeys:
    - Ctrl+O → **O**pen windows
    - Ctrl+R → **R**ecent files
    - Ctrl+F → **F**avorites
    - Ctrl+B → **B**ookmarks (Edge only)
    - Ctrl+W/X/P/D → **W**ord/e**X**cel/**P**df/**D**irectories
- Ctrl+H for **H**elp window
- Alternatively, use the mouse to change mode, scroll the list and select an item

## Known Limitations
- Bookmarks support is currently limited to Microsoft Edge format
- No folder grouping in bookmarks
- Only .lnk files are read from Favorites and Recent folders.
- Mouse click limited to selecting the first item with the given name in the list

## Config file
- Plain text file named filteristor.config in the same folder as the script
- One command per line: *`command`* `<space>` *`name`* `:` *`hotkey`* `<tab>` *`argument`*
- Define Windows+Alt+L as launch hotkey: `Hotkey Launch: #!l`
- Define Ctrl+Z as filter mode for powerpoint: `Mode powerpoint:^z<tab>i)\.ppt[xm]?$`
- Define the path for the bookmark file: `Path Bookmarks:c:\Temp\foo`
- Exclude Sticky Notes from open windows list: `Exclude OpenWindows:^Sticky Notes$`
- Exclude all items with "private" in their name: `Exclude *:private`
- Define Ctrl+2 to maximise the selected item on screen 2: `Monitor 2:^2<tab>X`
- Define Ctrl+3 to center the selected item window on screen 3: `Monitor 3:^3<tab>C`
- Define Alt+1 to place the window to the left half of screen 1: `Monitor 1:!1<tab>%,0,50,5,5`

## Requirements
- AutoHotkey v1.1+
- MS Windows 10/11
- MS Edge installed (for bookmark mode)
