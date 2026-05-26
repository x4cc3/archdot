----------------
-- Flickering fixes
----------------
hl.config({
    opengl = {
        nvidia_anti_flicker = false,
    },
})

hl.window_rule({
    match = { class = "^(jetbrains-.*)$" },
    no_initial_focus = true,
})
