----------------
-- Animation
----------------
hl.config({
    animations = {
        enabled = true,
    },
})

hl.curve("quick", { type = "bezier", points = { { 0.2, 0.0 }, { 0.1, 1.0 } } })
hl.curve("snappy", { type = "bezier", points = { { 0.1, 0.9 }, { 0.2, 1.0 } } })

hl.animation({ leaf = "border", enabled = true, speed = 1, bezier = "quick" })
hl.animation({ leaf = "windows", enabled = true, speed = 1, bezier = "snappy", style = "popin" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1, bezier = "quick", style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 1, bezier = "snappy" })
hl.animation({ leaf = "fade", enabled = true, speed = 1, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 1, bezier = "quick", style = "slide" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1, bezier = "snappy", style = "slidefade" })
