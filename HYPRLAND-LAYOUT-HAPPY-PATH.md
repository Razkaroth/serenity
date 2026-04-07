# Hyprland Layout Happy Path

This is a quick hands-on path for exploring the workspace-specific layouts now wired into your config.

## First steps

1. Rebuild and log into Hyprland.
2. Open a few tiled apps across the workspaces you want to test, for example:
   - `Super+T` for `kitty`
   - `Super+W` for `zen-beta`
   - `Super+D` for the communication special workspace
3. Keep at least 2-3 windows around on each test workspace so each layout has something to show.

## Workspace map

- `special:communication` -> `master`
- `1` and `5` -> `monocle`
- `2` and `6` -> `scrolling`
- everything else -> `dwindle`

## Layout switching

- `Ctrl+Super+D` -> switch to `dwindle`
- `Super+M` or `Ctrl+Super+M` -> switch to `master`
- `Ctrl+Super+S` -> switch to `scrolling`
- `Ctrl+Super+O` -> switch to `monocle`

## Keybinds to know

- `Super+Left/Right/Up/Down` -> normal focus movement
- `Super+Shift+Left/Right/Up/Down` -> move tiled windows
- `Super+-` and `Super+=` -> normal split resizing
- `Alt+Tab` / `Shift+Alt+Tab` -> cycle windows, including monocle-friendly cycling
- `Super+Alt+Left/Right` -> scrolling column focus
- `Super+Alt+Shift+Left/Right` -> scrolling column swap
- `Super+Alt+Up` -> scrolling promote window into its own column
- `Super+Alt+Down` -> scrolling fit active column
- `Super+Alt+-` and `Super+Alt+=` -> scrolling column resize

## Suggested tour

### 1. Dwindle baseline on normal workspaces

Start here to re-anchor your normal workflow.

- Go to a workspace other than `1`, `2`, `5`, `6`, or `special:communication`, for example `3` or `4`
- Use `Super+Left/Right/Up/Down` to move focus by direction
- Use `Super+Shift+Left/Right/Up/Down` to move windows
- Use `Super+-` and `Super+=` to test split resizing

Expected feel:

- Tree-like tiling
- Best general-purpose layout
- Closest to your current muscle memory

### 2. Master on communication

Now try the communication workspace as a main-pane workflow.

- Press `Super+D` to show the communication special workspace
- Put the app you care about most in focus first, then open or cycle the rest
- Use `Super+Left/Right` and `Alt+Tab` to move through the stack

Good things to notice:

- One window gets the dominant area
- Side windows become a support stack
- This is a good fit for `Ferdium`, `Signal`, `Vesktop`, browser/chat combinations

### 3. Scrolling on workspaces 2 and 6

Now explore the strip-based workflow on your browser workspaces.

- Go to workspace `2` or `6`
- Open browser windows, devtools, docs, terminals, or app tabs you want to compare
- Use `Super+Alt+Left/Right` to move across columns
- Use `Super+Alt+Shift+Left/Right` to swap columns
- Use `Super+Alt+-` and `Super+Alt+=` to resize the current column
- Use `Super+Alt+Up` to promote the current window into its own column
- Use `Super+Alt+Down` to fit the active column back into view

Good things to notice:

- Windows feel like they live on a tape instead of in a split tree
- Left/right becomes the main navigation axis
- Promoting a window makes it easy to break one app out into its own column

### 4. Monocle on workspaces 1 and 5

Finally, explore your terminal workspaces in monocle.

- Go to workspace `1` or `5`
- Open multiple terminals or terminal-heavy tools
- Use `Alt+Tab` and `Shift+Alt+Tab` to cycle the same stack
- Keep several tiled windows open and watch only one stay visible at a time

Good things to notice:

- It behaves like a focused stack of full-size tiled windows
- Great for reading, coding, or single-task sessions
- Cycling matters more than spatial navigation here

## Practical comparison

- `dwindle`: best default, strongest directional control
- `master`: best when one app should dominate and others support it
- `scrolling`: best when you want many tiled windows but only browse a few at once
- `monocle`: best when you want one tiled window visible and fast cycling

## Simple evaluation loop

Try this for a real-world test:

1. Open `kitty` on workspace `1` and `5`.
2. Open `zen-beta` plus dev pages on workspace `2` and `6`.
3. Open `Ferdium`, `Signal`, and `Vesktop` on communication space.
4. Spend 10 minutes on a normal dwindle workspace like `3` or `4`.
5. Spend 10 minutes on communication in `master`.
6. Spend 10 minutes on workspace `2` or `6` using the scrolling helper binds.
7. Spend 10 minutes on workspace `1` or `5` using monocle cycling.
8. Decide which layout feels best for:
   - general work
   - communications
   - focused coding
   - research / browsing many windows

## Notes

- Hyprland 0.54+ supports per-workspace layouts.
- In this config, `special:communication` is pinned to `master`, `1` and `5` are pinned to `monocle`, and `2` and `6` are pinned to `scrolling`.
- The communication special workspace assignment for `Ferdium`, `Signal`, and `Vesktop` remains in place.
- The layout hotkeys are still useful when you want to temporarily switch the current workspace manually.
