-- ============================================================
-- DASHBOARD
-- ============================================================
-- NEOVIM banner with theme gradient colors.
-- Colors come from DashGrad0-9 highlight groups set by the
-- theme system in nvim-colors.lua.

-- stylua: ignore start
local art = {
  { "                ▄   ▄███▄   ████▄     ▄   ▄█ █▀▄▀█", hl = "DashGrad0" },
  { "                 █  █▀   ▀  █   █      █  ██ █ █ █", hl = "DashGrad2" },
  { "             ██   █ ██▄▄    █   █ █     █ ██ █ ▄ █", hl = "DashGrad4" },
  { "             █ █  █ █▄   ▄▀ ▀████  █    █ ▐█ █   █", hl = "DashGrad5" },
  { "             █  █ █ ▀███▀           █  █   ▐    █ ", hl = "DashGrad7" },
  { "             █   ██                  █▐        ▀  ", hl = "DashGrad8" },
  { "                                     ▐            ", hl = "DashGrad9" },
}
-- stylua: ignore end

local function make_art_sections()
  local items = { gap = 0, padding = 0 }
  for _, row in ipairs(art) do
    items[#items + 1] = {
      text = { { row[1], hl = row.hl } },
    }
  end
  return items
end

return {
  {
    "snacks.nvim",
    opts = {
      dashboard = {
        width = 64,
        preset = {
          -- stylua: ignore
          keys = {
            { icon = "\u{f002} ",  key = "f", desc = "Find File",       action = ":lua Snacks.dashboard.pick('files')" },
            { icon = "\u{f15b} ",  key = "n", desc = "New File",         action = ":ene | startinsert" },
            { icon = "\u{f022} ",  key = "g", desc = "Find Text",       action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = "\u{f0c5} ",  key = "r", desc = "Recent Files",    action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = "\u{f423} ",  key = "c", desc = "Config",           action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
            { icon = "\u{e348} ",  key = "s", desc = "Restore Session",  section = "session" },
            { icon = "\u{ea8c} ",  key = "x", desc = "Lazy Extras",     action = ":LazyExtras" },
            { icon = "\u{f04b2} ", key = "l", desc = "Lazy",            action = ":Lazy" },
            { icon = "\u{f426} ",  key = "q", desc = "Quit",             action = ":qa" },
          },
        },
        sections = {
          make_art_sections(),
          { padding = 1 },
          { section = "keys", gap = 1, padding = 1 },
          { section = "startup" },
        },
      },
    },
  },
}
