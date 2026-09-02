-- oil.nvim — edit your filesystem like a normal buffer.
-- `-` opens the parent directory; edit lines to rename/move/delete, then :w to apply.
return {
  {
    "stevearc/oil.nvim",
    lazy = false, -- so it can hijack netrw when opening a directory
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      default_file_explorer = true,
      view_options = { show_hidden = true },
      keymaps = {
        ["q"] = "actions.close",
      },
    },
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Open parent directory (oil)" },
      { "<leader>o", "<cmd>Oil<cr>", desc = "Oil file explorer" },
    },
  },
}
