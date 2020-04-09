local highlight 

local function ui_cb(event_name, bufnr, changedtick, line_start, old_line_end, line_end, old_byte_size)
  local start = line_start - 1
  if line_start == 0 then start = 0 end

  vim.schedule((function()
    vim.api.nvim_buf_clear_namespace(bufnr, highlight.UI_NS, line_start, line_end)
    highlight.linenrs_range(bufnr, start, line_end)
  end))
end

local function matches_cb(_, bufnr, ct, from, old_to, to, _old_byte_size)
  if to == old_to then
    vim.api.nvim_buf_clear_namespace(0, highlight.MATCHES_NS, from, to)
  end
end

local function linenrs_range(bufnr, line_start, line_end)
  local lines = vim.api.nvim_buf_get_lines(bufnr, line_start, line_end, false)
  for i, text in ipairs(lines) do
    if i == 1 and line_start < 1 then
      vim.api.nvim_buf_add_highlight(bufnr, highlight.UI_NS, 'esearchHeader', 0, 0, -1)
    elseif text:len() == 0 then
      -- noop
    elseif text:sub(1,1) == ' ' then
      pos1, pos2 =  text:find('^%s+%d+%s')
      if pos2 ~= nil then
        vim.api.nvim_buf_add_highlight(bufnr, highlight.UI_NS, 'esearchLineNr', line_start + i - 1 , 0, pos2)
      end
    else
      vim.api.nvim_buf_add_highlight(bufnr, highlight.UI_NS, 'esearchFilename', line_start + i - 1, 0, -1)
    end
  end
end

local function header()
  return highlight.linenrs_range(0, 0, 1)
end

local function cursor_linenr()
  local current_line = vim.api.nvim_get_current_line()
  local _, last_column = current_line:find('^%s+%d+%s')
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  local ns = highlight.CURSOR_LINENR_NS

  vim.schedule((function()
    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
    if last_column ~= nil then
      vim.api.nvim_buf_add_highlight(0, ns, 'esearchCursorLineNr', line, 0, last_column)
    end
  end))
end

highlight = {
  UI_NS            = vim.api.nvim_create_namespace('esearch_highlights'),
  MATCHES_NS       = vim.api.nvim_create_namespace('esearch_matches'),
  CURSOR_LINENR_NS = vim.api.nvim_create_namespace('esearch_cursor_linenr'),
  ui_cb            = ui_cb,
  matches_cb       = matches_cb,
  linenrs_range    = linenrs_range,
  header           = header,
  cursor_linenr    = cursor_linenr,
}

return highlight
