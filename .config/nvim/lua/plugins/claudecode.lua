-- ============================================================
-- CLAUDE CODE
-- ============================================================
-- Terminal provider and split configuration for claudecode.nvim.

return {
  {
    "coder/claudecode.nvim",
    opts = {
      terminal = {
        split_side = "right",
        split_width_percentage = 0.40,
        snacks_win_opts = {
          position = "bottom",
          height = 0.35,
        },
      },
    },
  },
}
