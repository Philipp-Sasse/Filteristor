# Filteristor
A handy ahk script to quickly switch windows or open bookmarks, favorites or recent items with filtered lists.

Filteristor is a lightweight AutoHotkey utility that lets you quickly switch between open windows, recent files, favorites and bookmarks with filtered lists, fast and easy to use with the keyboard alone.

**Features**
- Hotkey-driven mode switching (Ctrl+O for open windows, Ctrl+B for bookmarks, Ctrl-P for recent PDFs, etc.)
- Currently 8 modes
- Live filtering of items via text input with Tab completion
- Instant activation of selected item via Return
- Arrow key navigation within the list

**How It Works**
- Press Alt+Win+F to open Filteristor
- Use the input box to filter items by name or title
- Press Tab to auto-complete filter text until next significant letter
- Switch modes using hotkeys:
- Ctrl+O → Open windows
- Ctrl+R → Recent files
- Ctrl+F → Favorites
- Ctrl+B → Bookmarks (Edge only)
- Ctrl+W/X/P/D → Word/Excel/PDF/Directories
- Use Up and Down arrow keys to select from the list
- Press Return to activate the selected item
- Windows are brought to the foreground
- Files and URLs are opened via Run

**Known Limitations**
- Bookmarks support is currently limited to Microsoft Edge
- No folder grouping or sorting in bookmarks
- Only .lnk files are read from Favorites and Recent folders.
- No fuzzy matching or advanced search logic.

**Requirements**
- AutoHotkey v1.1+
- MS Windows 10/11
- MS Edge installed (for bookmark mode)
