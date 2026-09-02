-- ============================================================
-- STATUSLINE
-- ============================================================
-- Lualine overrides with theme-matched powerline separators.
-- Reads vim.g.theme_separator_style set by the theme loader.

-- stylua: ignore
local separator_map = {
  angular = { left = "\u{e0b0}", right = "\u{e0b2}" },
  flame   = { left = "\u{e0c0}", right = "\u{e0c2} " },
  pixels  = { left = "\u{e0c4}", right = "\u{e0c5} " },
  slashes = { left = "\u{e0bc}", right = "\u{e0be}" },
  rounded = { left = "\u{e0b4}", right = "\u{e0b6}" },
  boxy    = { left = "",         right = ""         },
}

return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      local style = vim.g.theme_separator_style or "rounded"
      local seps = separator_map[style] or separator_map.rounded

      opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
        section_separators = seps,
        component_separators = { left = "\u{2502}", right = "\u{2502}" },
      })
    end,
  },
}
