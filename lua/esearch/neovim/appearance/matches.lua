local debounce = require('esearch/util').debounce

local M = {
  MATCHES_NS       = vim.api.nvim_create_namespace('esearch_matches'),
  ATTACHED_MATCHES = {},
}

local function on_lines(_event_name, bufnr, _changedtick, from, old_to, to, _old_byte_size)
  if to == old_to then
    vim.api.nvim_buf_clear_namespace(bufnr, M.MATCHES_NS, from, to)
  end
end

local function on_detach(bufnr)
  M.ATTACHED_MATCHES[bufnr] = nil
end

function M.buf_attach_matches()
  local bufnr = vim.api.nvim_get_current_buf()
  if not M.ATTACHED_MATCHES[bufnr] then
    M.ATTACHED_MATCHES[bufnr] = true
    vim.api.nvim_buf_attach(0, false, {on_lines=on_lines, on_detach=on_detach})
  end
end

local function advance(lnum, offset, col_from, col_to)
  if col_from == col_to then -- if zero length match
    return  {lnum, col_from + offset, col_to + offset + 1}, offset + 1
  else
    return {lnum, col_from + offset, col_to + offset}, offset + col_to
  end
end

local function matches_ranges(bufnr, pattern_string, lnum_from, lnum_to)
  local pattern = vim.regex(pattern_string)
  local ranges = {}
  local columns = vim.fn.winsaveview().leftcol + vim.o.columns
  local range

  local lines = vim.api.nvim_buf_get_lines(bufnr, lnum_from, lnum_to, false)
  for lnum = lnum_from, lnum_to - 1 do
    local offset = 0
    local col_lim = math.min(lines[lnum - lnum_from + 1]:len(), columns)
    while true do
      local col_from, col_to = pattern:match_line(bufnr, lnum, offset, col_lim)
      if not col_from then break end

      range, offset = advance(lnum, offset, col_from, col_to)
      table.insert(ranges, range)
    end
  end

  return ranges
end

local function set_matches_in_ranges(bufnr, ranges, lnum_from, lnum_to)
  vim.api.nvim_buf_clear_namespace(bufnr, M.MATCHES_NS, lnum_from, lnum_to)
  for _, range in pairs(ranges) do
    vim.api.nvim_buf_add_highlight(bufnr, M.MATCHES_NS, 'esearchMatch', unpack(range))
  end
end

local function viewport()
  local win_viewport_off_screen_margin = vim.api.nvim_eval('b:esearch.win_viewport_off_screen_margin')
  local lnum_from = math.max(3, vim.fn.line('w0') - 1 - win_viewport_off_screen_margin)
  local lnum_to = math.min(vim.api.nvim_buf_line_count(0), vim.fn.line('w$') + win_viewport_off_screen_margin)
  return lnum_from, lnum_to
end

local old_coordinates
function M.deferred_highlight_viewport(bufnr)
  vim.schedule(function()
    if vim.api.nvim_get_current_buf() ~= bufnr then return end
    local lnum_from, lnum_to = viewport()
    local pattern_string = vim.api.nvim_eval('b:esearch.pattern.hl_match')
    local changedtick = vim.api.nvim_buf_get_var(0, 'changedtick')
    local new_coordinates = {changedtick, lnum_from, lnum_to, vim.fn.winsaveview().leftcol, bufnr}
    if vim.deep_equal(old_coordinates, new_coordinates) then return end
    old_coordinates = new_coordinates
    if not vim.api.nvim_buf_is_loaded(bufnr) then return end

    local ranges = matches_ranges(bufnr, pattern_string, lnum_from, lnum_to)
    set_matches_in_ranges(bufnr, ranges, lnum_from, lnum_to)
  end)
end
-- Collecting match ranges in the background is more preferable, but it cause
-- seg fault when "|" in the pattern are used and cannot work properly with "^",
-- as column offsets only work for buffer lines.
M.deferred_highlight_viewport = debounce(
  M.deferred_highlight_viewport,
  vim.api.nvim_eval('g:esearch.win_matches_highlight_debounce_wait')
)

function M.highlight_viewport()
  local lnum_from, lnum_to = viewport()
  local bufnr = vim.api.nvim_get_current_buf()
  local pattern_string = vim.api.nvim_eval('b:esearch.pattern.hl_match')
  local ranges = matches_ranges(bufnr, pattern_string, lnum_from, lnum_to)
  set_matches_in_ranges(bufnr, ranges, lnum_from, lnum_to)
end

return M
