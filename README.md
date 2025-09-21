# Filteristor
*Filteristor: Your Friendly Neighborhood Filter Guide*

Filteristor is a lightweight AutoHotkey utility that lets you quickly switch between open windows, recent files, favorites and bookmarks with filtered lists, fast and easy to use with the keyboard alone.

## Features
- Hotkey-driven mode switching (Ctrl+O for **O**pen windows, Ctrl+B for **B**ookmarks, Ctrl-P for recent **P**dfs, etc.)
- Currently 8 modes
- Live filtering of items via text input with Tab completion
- Instant activation of selected item via Return
- Arrow key navigation within the list

## How It Works
- Press Alt+Win+F to open Filteristor
- Start typing to filter the list
- Press Tab to auto-complete filter text until next significant letter
- Press Down and Up to navigate the list
- Press Return to run or bring to front the current selection
- Press Shift-Backspace to close the selected window
- Press Esc to close the Filteristor
- Press Ctrl+C to toggle **C**ase sensitive search
- Switch modes using hotkeys:
    - Ctrl+O → **O**pen windows
    - Ctrl+R → **R**ecent files
    - Ctrl+F → **F**avorites
    - Ctrl+B → **B**ookmarks (Edge only)
    - Ctrl+W/X/P/D → **W**ord/e**X**cel/**P**df/**D**irectories
- Ctrl+H for **H**elp window

## Known Limitations
- Bookmarks support is currently limited to Microsoft Edge
- No folder grouping in bookmarks
- Only .lnk files are read from Favorites and Recent folders.
- Mouse click limited to selecting the first item with the given name in the list

## Requirements
- AutoHotkey v1.1+
- MS Windows 10/11
- MS Edge installed (for bookmark mode)
