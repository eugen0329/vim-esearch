-- nvim_buf_add_highlight() is deprecated since Neovim 0.11, extmarks are the
-- replacement. Same signature: col_end == -1 highlights till the end of the line.
local M = {}

function M.add(bufnr, ns, hl_group, line, col_start, col_end)
  local opts = {hl_group = hl_group, strict = false}
  if col_end == -1 then
    opts.end_row, opts.end_col = line + 1, 0
  else
    opts.end_col = col_end
  end
  -- strict = false: ignore out of range columns like nvim_buf_add_highlight did,
  -- the callbacks are scheduled and the text may have changed since
  pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, line, col_start, opts)
end

return M
