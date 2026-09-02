-- ============================================================
-- COLORIZER
-- ============================================================
-- Inline color previews for hex, rgb, hsl values.

return {
  {
    "NvChad/nvim-colorizer.lua",
    event = "BufReadPost",
    opts = {
      filetypes = { "*" },
      user_default_options = {
        names = false,
        rgb_fn = true,
        hsl_fn = true,
        css = true,
        css_fn = true,
        tailwind = false,
        mode = "virtualtext",
        virtualtext = "\u{25cf}",
        virtualtext_inline = true,
      },
    },
  },
}
