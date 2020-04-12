local highlight 

local ATTACHED_UI      = {}
local ATTACHED_MATCHES = {}

local function ui_cb(event_name, bufnr, changedtick, from, old_to, to, old_byte_size)
  local start = from - 1
  if from == 0 then start = 0 end

  vim.schedule((function()
    vim.api.nvim_buf_clear_namespace(bufnr, highlight.UI_NS, from, to)
    highlight.linenrs_range(bufnr, start, to)
  end))
end

local function matches_cb(_, bufnr, ct, from, old_to, to, _old_byte_size)
  if to == old_to then
    vim.api.nvim_buf_clear_namespace(0, highlight.MATCHES_NS, from, to)
  end
end

local function buf_attach_matches()
  local bufnr = vim.api.nvim_get_current_buf()
  if not ATTACHED_MATCHES[bufnr] then
    ATTACHED_MATCHES[bufnr] = true
    vim.api.nvim_buf_attach(0, false, {on_lines=matches_cb, on_detach=detach_matches_cb})
  end
end

local function detach_matches_cb(bufnr)
  ATTACHED_MATCHES[bufnr] = nil
end

local function buf_attach_ui()
  local bufnr = vim.api.nvim_get_current_buf()
  if not ATTACHED_UI[bufnr] then
    ATTACHED_UI[bufnr] = true
    vim.api.nvim_buf_attach(0, false, {on_lines=ui_cb, on_detach=detach_ui_cb})
  end
end

local function detach_ui_cb(bufnr)
  ATTACHED_UI[bufnr] = nil
end

local function linenrs_range(bufnr, from, to)
  local lines = vim.api.nvim_buf_get_lines(bufnr, from, to, false)
  for i, text in ipairs(lines) do
    if i == 1 and from < 1 then
      vim.api.nvim_buf_add_highlight(bufnr, highlight.UI_NS, 'esearchHeader', 0, 0, -1)
    elseif text:len() == 0 then
      -- noop
    elseif text:sub(1,1) == ' ' then
      pos1, pos2 =  text:find('^%s+%d+%s')
      if pos2 ~= nil then
        vim.api.nvim_buf_add_highlight(bufnr, highlight.UI_NS, 'esearchLineNr', from + i - 1 , 0, pos2)
      end
    else
      vim.api.nvim_buf_add_highlight(bufnr, highlight.UI_NS, 'esearchFilename', from + i - 1, 0, -1)
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
  UI_NS              = vim.api.nvim_create_namespace('esearch_highlights'),
  MATCHES_NS         = vim.api.nvim_create_namespace('esearch_matches'),
  CURSOR_LINENR_NS   = vim.api.nvim_create_namespace('esearch_cursor_linenr'),
  ATTACHED_UI        = ATTACHED_UI,
  ATTACHED_MATCHES   = ATTACHED_MATCHES,
  buf_attach_ui      = buf_attach_ui,
  buf_attach_matches = buf_attach_matches,
  linenrs_range      = linenrs_range,
  header             = header,
  cursor_linenr      = cursor_linenr,
}

return highlight