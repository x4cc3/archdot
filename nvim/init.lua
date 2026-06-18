vim.g.mapleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.mouse = ""
vim.opt.termguicolors = true
vim.opt.clipboard = "unnamedplus"

-- ── Lazy.nvim bootstrap ──

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        lazypath,
    })
end

vim.opt.rtp:prepend(lazypath)

-- ── Plugins ──

require("lazy").setup({
    -- Colorscheme
    { "nyoom-engineering/oxocarbon.nvim" },

    -- Syntax highlighting
    { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },

    -- LSP
    { "neovim/nvim-lspconfig" },

    -- Completion
    {
        "hrsh7th/nvim-cmp",
        dependencies = { "hrsh7th/cmp-nvim-lsp" },
    },

    -- File finding
    {
        "nvim-telescope/telescope.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
    },

    -- Git signs in the gutter
    { "lewis6991/gitsigns.nvim" },

    -- File explorer (modal, not tree-based)
    { "stevearc/oil.nvim" },

    -- Floating terminal
    {
        "akinsho/toggleterm.nvim",
        version = "*",
    },

    -- Statusline
    { "nvim-lualine/lualine.nvim" },

    -- Surround with quotes/brackets/tags
    { "kylechui/nvim-surround" },
})

-- ── Colorscheme (applied after lazy ensures the plugin is available) ──

pcall(vim.cmd.colorscheme, "oxocarbon")

-- Transparent background and visible comments
local function set_transparency()
    local groups = { "Normal", "NormalNC", "SignColumn", "FoldColumn" }
    for _, group in ipairs(groups) do
        vim.api.nvim_set_hl(0, group, { bg = "none" })
    end
    vim.api.nvim_set_hl(0, "Comment", { fg = "#7ecf6f", italic = true })
end
set_transparency()

-- ── Plugin configurations ──
-- All wrapped in pcall so first-time bootstrap (before :Lazy sync) doesn't crash.
-- After running `:Lazy sync`, restart nvim and everything works.

pcall(function()
    require("nvim-treesitter.configs").setup({
        ensure_installed = {
            "c", "cpp", "go", "python", "lua", "vim", "vimdoc",
            "javascript", "typescript", "html", "css", "markdown",
        },
        auto_install = true,
        highlight = { enable = true },
    })
end)

-- LSP keymaps (applies whenever any LSP attaches to a buffer)
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local bufopts = { noremap = true, silent = true, buffer = args.buf }
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, bufopts)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
        vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, bufopts)
        vim.keymap.set("n", "]d", vim.diagnostic.goto_next, bufopts)
    end,
})

-- Enable LSP servers (Neovim 0.12 API)
pcall(function()
    require("lspconfig")
    vim.lsp.enable("clangd")
    vim.lsp.enable("gopls")
    vim.lsp.enable("basedpyright")
    vim.lsp.enable("ts_ls")
    vim.lsp.enable("ruff")
end)

pcall(function()
    local cmp = require("cmp")
    cmp.setup({
        mapping = cmp.mapping.preset.insert({
            ["<C-b>"] = cmp.mapping.scroll_docs(-4),
            ["<C-f>"] = cmp.mapping.scroll_docs(4),
            ["<C-Space>"] = cmp.mapping.complete(),
            ["<C-e>"] = cmp.mapping.abort(),
            ["<CR>"] = cmp.mapping.confirm({ select = true }),
        }),
        sources = {
            { name = "nvim_lsp" },
        },
        formatting = {
            format = function(entry, vim_item)
                vim_item.abbr = string.sub(vim_item.abbr, 1, 40)
                return vim_item
            end,
        },
        window = {
            completion = cmp.config.window.bordered({
                max_height = 15,
                max_width = 60,
            }),
        },
    })
end)

pcall(function()
    require("gitsigns").setup()
end)

pcall(function()
    require("oil").setup()
end)

pcall(function()
    require("toggleterm").setup({
        open_mapping = [[<C-\>]],
        direction = "float",
        float_opts = {
            border = "curved",
        },
    })
end)

pcall(function()
    local colors = {
        teal   = "#08bdba",
        blue   = "#78a9ff",
        purple = "#be95ff",
        green  = "#42be65",
        pink   = "#ee5396",
        yellow = "#f1c21b",
        orange = "#ff832b",
        gray   = "#525252",
        bg     = "#161616",
        surf   = "#262626",
        text   = "#f4f4f4",
    }

    local starship_theme = {
        normal = {
            a = { fg = colors.bg, bg = colors.teal, gui = "bold" },
            b = { fg = colors.blue, bg = colors.surf },
            c = { fg = colors.text, bg = colors.bg },
            x = { fg = colors.green, bg = colors.bg },
            y = { fg = colors.yellow, bg = colors.bg },
            z = { fg = colors.teal, bg = colors.bg },
        },
        insert = {
            a = { fg = colors.bg, bg = colors.green, gui = "bold" },
        },
        visual = {
            a = { fg = colors.bg, bg = colors.purple, gui = "bold" },
        },
        replace = {
            a = { fg = colors.bg, bg = colors.pink, gui = "bold" },
        },
        command = {
            a = { fg = colors.bg, bg = colors.orange, gui = "bold" },
        },
        inactive = {
            a = { fg = colors.gray, bg = colors.bg },
            b = { fg = colors.gray, bg = colors.bg },
            c = { fg = colors.gray, bg = colors.bg },
        },
    }

    require("lualine").setup({
        options = {
            theme = starship_theme,
            component_separators = { left = "", right = "" },
            section_separators = { left = " ", right = " " },
            globalstatus = true,
        },
        sections = {
            lualine_a = {
                {
                    "mode",
                    fmt = function(str) return "› " .. str:sub(1, 1) .. " " end,
                },
            },
            lualine_b = {
                { "branch", icon = " " },
                { "diff", colored = true, symbols = { added = "+", modified = "~", removed = "-" } },
            },
            lualine_c = {
                { "filename", path = 1, symbols = { modified = " ●", readonly = " 󰌾", unnamed = "[No Name]" } },
            },
            lualine_x = {
                { "diagnostics", sources = { "nvim_diagnostic" }, symbols = { error = " ", warn = " ", info = " ", hint = "󰌵 " } },
                {
                    "filetype",
                    fmt = function(str) return str:lower() end,
                },
            },
            lualine_y = { "progress" },
            lualine_z = {
                { "location", fmt = function(str) return " " .. str .. " " end },
            },
        },
    })
end)

pcall(function()
    require("nvim-surround").setup()
end)

-- ── Telescope keymaps ──

vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<CR>")
vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<CR>")

-- ── Terminal keymaps ──
-- Ctrl+\ toggles the floating terminal
-- Space tt opens the floating terminal
vim.keymap.set("n", "<leader>t", "<cmd>ToggleTerm direction=horizontal<CR>")
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]])

-- ── Oil keymaps ──
vim.keymap.set("n", "-", "<CMD>Oil<CR>")
