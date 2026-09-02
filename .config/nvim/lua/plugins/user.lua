-- ============================================================
-- USER TWEAKS
-- ============================================================
-- Personal overrides on top of LazyVim + the enabled extras.
-- (Colorscheme / theme integration lives in lua/plugins/lazy.lua,
--  which is wired into the ~/.config/themes system — don't set a
--  colorscheme here or it'll fight the theme loader.)
--
-- This file is a normal LazyVim plugin spec: return a table of specs.
-- Add/uncomment things as you go.

return {
  -- Treesitter: make sure the parsers for our languages are installed
  -- (the lang extras already add most of these; this is belt-and-suspenders
  -- plus a few extra parsers worth having).
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "bash",
        "lua",
        "markdown",
        "markdown_inline",
        "regex",
        "toml",
        "yaml",
      })
    end,
  },

  -- LSP: turn on inlay hints everywhere they're supported.
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = { enabled = true },
      -- per-server tweaks can go here, e.g.:
      -- servers = { lua_ls = { settings = { Lua = { hint = { enable = true } } } } },
    },
  },

  -- Prose-friendly defaults for markdown/text/gitcommit buffers.
  {
    "LazyVim/LazyVim",
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "markdown", "text", "gitcommit" },
        callback = function()
          vim.opt_local.wrap = true
          vim.opt_local.linebreak = true
          vim.opt_local.spell = true
        end,
      })
    end,
  },

  -- ---- Examples (uncomment to enable) -------------------------------------
  -- Add Go later in one line by uncommenting:
  -- { import = "lazyvim.plugins.extras.lang.go" },
  --
  -- A plugin you like, fetched from GitHub:
  -- { "folke/zen-mode.nvim", cmd = "ZenMode", opts = {} },
}
