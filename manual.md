# Keyboard Manual

This documents `vial/v-l-2.vil` for the left Corne half and how it maps into your Hyprland workflow.

## Layer 0 - Base / Homerow Mods

| Area | Mapping | Purpose |
|---|---|---|
| Left homerow | `A=Gui`, `S=Alt`, `D=Shift`, `F=Ctrl` | Hold for modifiers, tap for letters |
| Right homerow | `;=Gui`, `L=Alt`, `K=Shift`, `J=Ctrl` | Hold for modifiers, tap for letters |
| `Esc` key | tap `Esc`, hold `Layer 5` | Workspace/navigation leader |
| `Tab` key | tap `Tab`, hold `Layer 4` | Function/system layer access |
| Thumb keys | `MO(1)`, `MO(2)`, `MO(4)` | Quick access to numbers/nav, symbols, and function layer |

This is the normal typing layer. It is optimized for homerow mods, with `Esc` now acting as the hold key for the dedicated workspace layer.

## Layer 1 - Numbers / Navigation

| Area | Mapping | Purpose |
|---|---|---|
| Left top row | `1 2 3 4 5` | Fast number entry |
| Right top row | `0 9 8 7 6` | Fast number entry |
| Right homerow cluster | arrows on `L K J H` positions | Cursor movement without leaving home position |
| Right bottom row | `End PgUp PgDn Home` | Document navigation |
| Edge keys | `Super+1..6` style outputs | App/workspace shortcuts |

This is the everyday navigation and number layer. You said this is one of the layers you already live in most comfortably.

## Layer 2 - Symbols / Media

| Area | Mapping | Purpose |
|---|---|---|
| Top rows | shifted number symbols and punctuation | Symbol-heavy typing |
| Right cluster | brackets, braces, minus, equals, slash, backslash | Programming punctuation |
| Left lower row | volume / prev / play-pause / next / volume | Media control |
| `DF(3)` | switch to Layer 3 default | Fallback non-homerow default |

This is your symbol and media layer, mainly for coding punctuation and quick media control.

## Layer 3 - Plain Base / Fallback

| Area | Mapping | Purpose |
|---|---|---|
| Alpha keys | normal alphas without mod-taps | Compatibility / fallback typing |
| Bottom left | `DF(0)` | Return to homerow-mod base layer |

This is the simpler fallback base layer for cases where homerow mods are inconvenient.

## Layer 4 - Functions / Mouse / System

| Area | Mapping | Purpose |
|---|---|---|
| Top rows | `F1`-`F12` | Function keys |
| Left/middle | `Super+1..5`, `Super+Left/Right` | System and workspace helpers |
| Right side | mouse move / buttons / wheel | Mouse emulation |
| Held from base | hold `Tab` | Fast access without leaving base layer |

This is your function and system-control layer. It stays on hold-tab because you already rely on it heavily.

## Layer 5 - Workspace / Hyprland

| Area | Mapping | Purpose |
|---|---|---|
| Left top row | `6 7 8 9 0` | Jump to workspaces `6..10` |
| Left middle row | `1 2 3 4 5` | Jump to workspaces `1..5` |
| Left bottom row | `Shift+1 2 3 4 5` via `F13..F17` aliases | Move window to workspaces `1..5` |
| Right bottom row | `Shift+6 7 8 9 0` via `F18..F22` aliases | Move window to workspaces `6..10` |
| Right homerow `H J K L` | `Super+Left`, `Super+Down`, `Super+Up`, `Super+Right` | Move focus between windows in the current layout |
| Right inner top key | previous workspace | Step workspace backward |
| Right inner middle key | next workspace | Step workspace forward |
| Right outer top key | toggle special workspace | Quick scratch workspace |
| Right outer middle key | toggle communication workspace | `Ferdium`, `Signal`, `Vesktop` |
| Right outer bottom key | toggle music workspace | Music special workspace |
| Access | hold `Esc` from base | Enter workspace/navigation mode |

Layer 5 is now a dedicated Hyprland layer:
- left hand = direct workspace targeting
- bottom rows = move window to workspace
- right hand = focus movement and workspace stepping
- far-right extra column = special workspace toggles

## Hyprland alias notes

`Layer 5` uses function-key aliases in Hyprland so the keyboard does not need uncomfortable homerow modifier chains:
- `F13`-`F22` -> jump to workspaces `1`-`10`
- `Shift+F13`-`Shift+F22` -> move window to workspaces `1`-`10`
- `Ctrl+F23` / `Ctrl+F24` -> previous / next workspace

The actual Hyprland bindings live in `common/hm/confs/caelestia/hypr/hyprland/keybinds.conf`.
