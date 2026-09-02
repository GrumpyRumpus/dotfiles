-- leetcode.nvim — solve LeetCode problems inside nvim.
-- Description/code/run/test/submit all happen in-editor against leetcode.com.
--
-- One-time setup before run/submit work: sign in with your browser session
-- cookie via  :Leet cookie update  (paste the `Cookie` request header, not
-- set-cookie). The description renders without auth; submitting needs it.
--
-- Custom bit for the leetcode-srs integration: a `:LeetSlug <slug>` command
-- that opens a SPECIFIC problem directly (the plugin only ships a picker).
-- srs.py shells out to `kitty nvim -c "LeetSlug <slug>"` on the `o` keypress.
return {
  {
    "kawre/leetcode.nvim",
    build = ":TSUpdate html",
    -- Lazy-load on these commands. LeetSlug is ours (defined in config below);
    -- listing it here lets `nvim -c "LeetSlug ..."` trigger the load + dispatch.
    cmd = { "Leet", "LeetSlug" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      -- picker provider: LazyVim already ships snacks.nvim, which leetcode.nvim
      -- auto-detects. No extra picker dep needed.
    },
    opts = {
      arg = "leetcode.nvim", -- `nvim leetcode.nvim` opens the dashboard
      lang = "python3",      -- default solution language
    },
    config = function(_, opts)
      require("leetcode").setup(opts)
      -- Open one problem straight to its description by title slug.
      -- Question{ title_slug = ... } is exactly what the picker hands :mount();
      -- mount() fetches the full question itself.
      vim.api.nvim_create_user_command("LeetSlug", function(o)
        local slug = vim.trim(o.args)
        if slug == "" then
          vim.notify("LeetSlug: need a problem slug", vim.log.levels.ERROR)
          return
        end
        local ok, Question = pcall(require, "leetcode-ui.question")
        if not ok then
          vim.notify("LeetSlug: leetcode.nvim not loaded", vim.log.levels.ERROR)
          return
        end
        Question({ title_slug = slug }):mount()
      end, { nargs = 1, desc = "Open a LeetCode problem by slug" })
    end,
  },
}
