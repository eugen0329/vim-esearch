local ui = require('esearch/neovim/appearance/ui')

local M = {
  CURSOR_LINENR_NS = vim.api.nvim_create_namespace('esearch_cursor_linenr'),
}

function M.highlight_cursor_linenr()
  local current_line = vim.api.nvim_get_current_line()
  local _, last_column = current_line:find(ui.LINENR_RE)
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  local ns = M.CURSOR_LINENR_NS
  local bufnr = vim.api.nvim_get_current_buf()

  vim.schedule(function()
    if vim.api.nvim_call_function('bufexists', {bufnr}) == 0 then return end

    -- the condition below is needed to prevent adding highlights to buffer when leaving them
    if bufnr == vim.api.nvim_get_current_buf() then
      vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
      if last_column then
        vim.api.nvim_buf_add_highlight(bufnr, ns, 'esearchCursorLineNr', line, 0, last_column)
      end
    end
  end)
end

return M
