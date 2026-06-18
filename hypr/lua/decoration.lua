----------------
-- General window decoration
----------------
hl.config({
    decoration = {
        rounding = 0,
        blur = {
            enabled = false,
            size = 8,
            passes = 4,
            new_optimizations = true,
            ignore_opacity = false,
            xray = false,
        },
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        fullscreen_opacity = 1.0,
    },
    layerrule = {
    },
})
