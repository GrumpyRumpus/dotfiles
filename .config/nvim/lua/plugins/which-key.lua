-- ============================================================
-- WHICH-KEY ICONS
-- ============================================================
-- Nerd Font icon overrides for which-key group labels.
-- Replaces stock text-only labels with matching icons.

return {
  {
    "folke/which-key.nvim",
    opts = {
      -- stylua: ignore
      spec = {
        -- ---- Groups ----
        { "<leader>c",     group = "code",             icon = "\u{f121} " },
        { "<leader>d",     group = "debug",            icon = "\u{f188} " },
        { "<leader>dp",    group = "profiler",         icon = "\u{f0104} " },
        { "<leader>f",     group = "file/find",        icon = "\u{f15b} " },
        { "<leader>g",     group = "git",              icon = "\u{f1d3} " },
        { "<leader>gh",    group = "hunks",            icon = "\u{f02a2} " },
        { "<leader>s",     group = "search",           icon = "\u{f002} " },
        { "<leader>u",     group = "ui",               icon = "\u{f0ad} " },
        { "<leader>x",     group = "diagnostics",      icon = "\u{f071} " },
        { "<leader><tab>", group = "tabs",             icon = "\u{f04e9} " },
        { "<leader>b",     group = "buffer",           icon = "\u{f0c5} " },
        { "<leader>w",     group = "windows",          icon = "\u{f2d2} " },
        { "<leader>q",     group = "quit/session",     icon = "\u{f011} " },
        { "gs",            group = "surround",         icon = "\u{f0172} " },
        { "[",             group = "prev",             icon = "\u{f053} " },
        { "]",             group = "next",             icon = "\u{f054} " },
        { "g",             group = "goto",             icon = "\u{f064} " },
        { "z",             group = "fold",             icon = "\u{f066} " },
        -- ---- Standalone items ----
        { "<leader>e",     icon = "\u{f07c} " },
        { "<leader>E",     icon = "\u{f07b} " },
        { "<leader>l",     icon = "\u{f04b2} " },
        { "<leader>L",     icon = "\u{f06a} " },
        { "<leader>K",     icon = "\u{f02d} " },
        { "<leader>-",     icon = "\u{f0c8} " },
        { "<leader>|",     icon = "\u{f0c9} " },
        { "<leader>`",     icon = "\u{f0c5} " },
      },
    },
  },
}
