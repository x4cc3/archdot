----------------
-- General window decoration
----------------
hl.config({
    decoration = {
        rounding = 5,
        blur = {
            enabled = true,
            size = 4,
            passes = 1,
            new_optimizations = true,
            ignore_opacity = true,
            xray = false,
        },
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        fullscreen_opacity = 1.0,
    },
})
