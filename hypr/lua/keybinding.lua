----------------
-- Key bindings
----------------
local mainMod = "SUPER"

-- Applications
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("ghostty"), { desc = "Terminal (ghostty)" })
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("zen-browser"), { desc = "Browser" })
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("thunar"), { desc = "File Explorer (Thunar)" })
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("code"), { desc = "VSCode" })
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("webcord"))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("spotify"))

-- Windows
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { desc = "Kill active window" })
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen(), { desc = "Set active window to fullscreen" })
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }), { desc = "Toggle active windows into floating mode" })
hl.bind(mainMod .. " + S", hl.dsp.layout("togglesplit"), { desc = "Toggle splitting" })
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, desc = "Move window with the mouse" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, desc = "Resize window with the mouse" })

-- Vim-style focus movement
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }), { desc = "Focus window left" })
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }), { desc = "Focus window down" })
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }), { desc = "Focus window up" })
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }), { desc = "Focus window right" })

-- Vim-style window movement
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }), { desc = "Move window left" })
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }), { desc = "Move window down" })
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }), { desc = "Move window up" })
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }), { desc = "Move window right" })

-- Actions
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh"), { desc = "Screenshot menu" })
hl.bind("Print", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | wl-copy --type image/png && notify-send "Screenshot copied" "Area copied to clipboard"]]), { desc = "Screenshot area to clipboard" })
hl.bind("SHIFT + Print", hl.dsp.exec_cmd([[mkdir -p ~/Pictures/Screenshots && grim -g "$(slurp)" ~/Pictures/Screenshots/screenshot_$(date +%Y-%m-%d_%H-%M-%S).png && notify-send "Screenshot saved" "Area saved to ~/Pictures/Screenshots"]]), { desc = "Screenshot selected area" })
hl.bind("CTRL + Print", hl.dsp.exec_cmd([[sh -c 'mkdir -p "$HOME/Pictures/Screenshots"; file="$HOME/Pictures/Screenshots/screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"; grim "$file" && wl-copy --type image/png < "$file" && notify-send "Screenshot copied" "Fullscreen copied to clipboard"']]), { desc = "Screenshot fullscreen to clipboard" })
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd("sleep 0.1 && wlogout -b 2 -c 70 -r 50 -L 690 -R 690 -T 300 -B 300 -n"), { desc = "Start wlogout" })
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("rofi -show drun -replace -i -theme ~/.config/rofi/launchers/type-1/glass-compact.rasi"), { desc = "Open application launcher" })
hl.bind(mainMod .. " + CTRL + H", hl.dsp.exec_cmd("~/.config/hypr/scripts/keybindings.sh"), { desc = "Show keybindings" })
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("~/.config/waybar/launch.sh"), { desc = "Reload waybar" })
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("~/.config/hypr/scripts/loadconfig.sh"), { desc = "Reload hyprland config" })
hl.bind(mainMod .. " + CTRL + C", hl.dsp.exec_cmd("~/.config/scripts/cliphist.sh"), { desc = "Open clipboard manager" })


-- Workspaces
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }), { desc = "Open workspace " .. i })
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), { desc = "Move active window to workspace " .. i })
end
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { desc = "Open next workspace" })
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { desc = "Open previous workspace" })
hl.bind(mainMod .. " + CTRL + down", hl.dsp.focus({ workspace = "empty" }), { desc = "Open the next empty workspace" })

-- Fn keys
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -q s +10%"), { locked = true, repeating = true, desc = "Increase brightness by 10%" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -q s 10%-"), { locked = true, repeating = true, desc = "Reduce brightness by 10%" })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true, desc = "Increase volume by 5%" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true, desc = "Reduce volume by 5%" })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true, desc = "Toggle mute" })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, desc = "Audio play pause" })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl pause"), { locked = true, desc = "Audio pause" })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true, desc = "Audio next" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true, desc = "Audio previous" })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("pactl set-source-mute @DEFAULT_SOURCE@ toggle"), { locked = true, repeating = true, desc = "Toggle microphone" })
hl.bind("XF86Calculator", hl.dsp.exec_cmd("qalculate-gtk"), { locked = true, desc = "Open calculator" })
hl.bind("XF86ScreenSaver", hl.dsp.exec_cmd("hyprlock"), { locked = true, desc = "Open screenlock" })

-- Wallpaper management
hl.bind(mainMod .. " + CTRL + W", hl.dsp.exec_cmd("~/.config/hypr/scripts/random_wallpaper.sh"), { desc = "Cycle to next wallpaper" })
