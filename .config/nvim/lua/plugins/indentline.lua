-- ============================================================
-- INDENT GUIDES
-- ============================================================
-- Rainbow indent guides using theme gradient colors.
-- Each depth level cycles through IndentGrad0-9 highlights.
-- Active scope highlighted with IndentScope (accent color).

return {
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = "LazyFile",
    opts = {
      indent = {
        char = "\u{250a}", -- dotted line
        highlight = {
          "IndentGrad0",
          "IndentGrad1",
          "IndentGrad2",
          "IndentGrad3",
          "IndentGrad4",
          "IndentGrad5",
          "IndentGrad6",
          "IndentGrad7",
          "IndentGrad8",
          "IndentGrad9",
        },
      },
      scope = {
        show_start = false,
        show_end = false,
        highlight = "IndentScope",
      },
    },
  },
}
