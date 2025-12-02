# Filtronaut
*The Filtronaut has the filters to navigate you to open windows, recent documents, bookmarks and more.*

Filtronaut is a lightweight AutoHotkey utility that lets you quickly switch between open windows, recent files, favorites and bookmarks with filtered lists, fast and easy to use with the keyboard alone.

## Features
- Hotkey-driven mode switching (Alt-O for **O**pen windows, Alt-B for **B**ookmarks, Alt-P for recent **P**dfs, etc.)
- Currently 8 built-in modes
- Define additional modes or custom hotkeys with optional config file
- Live filtering of items via text input with Tab completion
- Instant activation of selected item via Return
- Arrow key navigation within the list

## How It Works
- Press Alt-Esc to open Filtronaut (see *Config File*)
- Start typing to filter the list
- Press Tab to auto-complete filter text until next significant letter
- Press Down and Up to navigate the list
- Press Return to run or bring to front the current selection
- Press Alt-1 to maximise the current selection on screen 1 (see *Config File*)
- Press Ctrl-Plus to add the current input to sniplets or current item to favorites
- Press Ctrl-Backspace to close the selected window, remove recent link or sniplet
- Sort the sniplet list with Ctrl-Up and Ctrl-Down
- Press Esc to close the Filtronaut
- Press Alt-C to toggle **C**ase sensitive search
- Switch modes using hotkeys (see *Config File*):
    - Alt-O → **O**pen windows
    - Alt-R → **R**ecent files
    - Alt-F → **F**avorites
    - Alt-B → **B**ookmarks (MS Edge only)
    - Alt-W/X/P/D → **W**ord/e**X**cel/**P**df/**D**irectories
- Ctrl-H for **H**elp window
- Alternatively, use the mouse to change mode, scroll the list and select an item

## Known Limitations
- Bookmarks support is currently limited to Microsoft Edge format
- Opening windows with given layout does not always work
- Only .lnk files are read from Favorites and Recent folders.
- Mouse click limited to selecting the first item with the given name in the list

## Config file
- Plain text file named Filtronaut.config in the same folder as the script
- One command per line: *`command`* <kbd>space</kbd> *`name`* `:` *`hotkey`* <kbd>tab</kbd> *`argument`*
- Define Windows-Alt-B to launch in Bookmark mode: `Hotkey Launch: #!l`<kbd>tab</kbd>`Bookmarks`
- Define Ctrl-Z as filter mode for powerpoint: `Mode powerpoint:^z`<kbd>tab</kbd>`i)\.ppt[xm]?$`
- Define the path for the bookmark file: `Path Bookmarks:c:\Temp\foo`
- Exclude Sticky Notes from open windows list: `Exclude OpenWindows:^Sticky Notes$`
- Exclude all items with "private" in their name: `Exclude *:private`
- Define Ctrl-2 to maximise the selected item on screen 2: `Monitor 2:^2`<kbd>tab</kbd>`X`
- Define Ctrl-3 to center the selected item window on screen 3: `Monitor 3:^3<`<kbd>tab</kbd>`C`
- Define Alt-1 to place the window to the left half of screen 1: `Monitor 1:!1`<kbd>tab</kbd>`%,0,50,5,5`
- Define Alt-L to define a phrase library: `Sniplets PhraseLib:!l`<kbd>tab</kbd>`c:\Temp\Phraselib.txt`
- Define Ctrl-S as Save hotkey to switch off auto-saving: `Hotkey Save: ^s`

## Requirements
- AutoHotkey v1.1+
- MS Windows 10/11
- MS Edge installed (for bookmark mode)
