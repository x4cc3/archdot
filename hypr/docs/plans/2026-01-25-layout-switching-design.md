# Layout Switching Design

## Goal
Enable dynamic switching between the default `dwindle` layout and the `scroller` / `hyprscroller` layout using one keybind.

## Current Config Model
This Hyprland setup is Lua-based:

- Entry point: `hyprland.lua`
- Autostart: `lua/autostart.lua`
- Keybinds: `lua/keybinding.lua`
- Layout config: `lua/layout.lua`
- User extension point: `lua/custom.lua`

Do not implement this plan using old `*.conf` snippets such as `autostart.conf`, `keybinding.conf`, or `conf/custom.conf` unless the config is migrated away from Lua first.

## Architecture
1. **Plugin Management**
   - Use `hyprpm` to manage `hyprscroller`.
   - Add `hyprpm reload -n` to `lua/autostart.lua` if the plugin needs to be reloaded automatically on session start.

2. **Configuration**
   - Prefer adding plugin settings in `lua/custom.lua` or a new module such as `lua/scroller.lua` required from `hyprland.lua`.
   - Keep the default layout as `dwindle` in `lua/window.lua` until the toggle is explicitly used.

## Switching Mechanism Options

### Option 1: Direct Keybinds
Use two binds in `lua/keybinding.lua`:

```lua
hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd("hyprctl keyword general:layout scroller"), { desc = "Use scroller layout" })
hl.bind(mainMod .. " + SHIFT + TAB", hl.dsp.exec_cmd("hyprctl keyword general:layout dwindle"), { desc = "Use dwindle layout" })
```

Pros: simple and fast.  
Cons: two keybinds.

### Option 2: Toggle Script
Create `scripts/switch_layout.sh` and bind it from `lua/keybinding.lua`:

```lua
hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd("~/.config/hypr/scripts/switch_layout.sh"), { desc = "Toggle layout" })
```

Pros: single keybind, can send notifications.  
Cons: requires a script.

## Decision
Use **Option 2** for better UX: one keybind plus a notification showing the active layout.

## Implementation Plan
1. Install/enable `hyprscroller` with `hyprpm`.
2. Add plugin reload to `lua/autostart.lua` if needed.
3. Add scroller settings in `lua/custom.lua` or a new `lua/scroller.lua` module.
4. Create `scripts/switch_layout.sh`.
5. Add `SUPER + TAB` bind in `lua/keybinding.lua`.
6. Reload Hyprland and verify with:
   - `hyprctl configerrors`
   - `hyprctl getoption general:layout`

## Conflict Check
Runtime bind check showed no duplicate bind groups. `SUPER + TAB` was not bound in the current Lua config at analysis time.
