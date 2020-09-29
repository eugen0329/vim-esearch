local ui = require('esearch/neovim/appearance/ui')
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

local function matches_ranges(pattern, lines, lnum_from)
  local ranges = {}

  for i, line in ipairs(lines) do
    if line:sub(1,1) ~= ' ' then goto continue end

    local _, offset = line:find(ui.LINENR_RE)
    if not offset then goto continue end
    offset = offset + 1

    while true do
      if offset > line:len() then break end
      local col_from, col_to = pattern:match_str(line:sub(offset))
      if not col_from then break end

      if col_from == col_to then
        table.insert(ranges, {lnum_from + i - 1, col_from + offset - 1, col_to + offset})
        offset = offset + 1
      else
        table.insert(ranges, {lnum_from + i - 1, col_from + offset - 1, col_to + offset - 1})
        offset = offset + col_to
      end
    end

    ::continue::
  end

  return ranges
end

local function set_matches_in_ranges(bufnr, ranges, lnum_from, lnum_to)
  -- without this check neovim throws segmentation fault
  if vim.api.nvim_get_current_buf() == bufnr then
    vim.api.nvim_buf_clear_namespace(bufnr, M.MATCHES_NS, lnum_from, lnum_to)
    for _, range in pairs(ranges) do
      vim.api.nvim_buf_add_highlight(bufnr, M.MATCHES_NS, 'esearchMatch', unpack(range))
    end
  end
end

local function viewport()
  local win_viewport_off_screen_margin = vim.api.nvim_eval('b:esearch.win_viewport_off_screen_margin')
  local lnum_from = math.max(3, vim.fn.line('w0') - 1 - win_viewport_off_screen_margin)
  local lnum_to = vim.fn.line('w$') + win_viewport_off_screen_margin
  return lnum_from, lnum_to
end

local function _deferred_highlight_viewport(pattern_string, changedtick, lnum_from, lnum_to, bufnr)
  vim.schedule(function()
    local lines = vim.api.nvim_buf_get_lines(bufnr, lnum_from, lnum_to, false)
    local pattern = vim.regex(pattern_string)
    local ranges = matches_ranges(pattern, lines, lnum_from, bufnr, changedtick)
    set_matches_in_ranges(bufnr, ranges, lnum_from, lnum_to)
  end)
end
-- highlighting using set_timeout(cb, 0), but it cause seg fault when "|" in the
-- pattern are used
_deferred_highlight_viewport = debounce(
  _deferred_highlight_viewport,
  vim.api.nvim_eval('g:esearch.win_matches_highlight_debounce_wait')
)

local old_coordinates
function M.deferred_highlight_viewport(bufnr)
  local changedtick = vim.api.nvim_buf_get_var(0, 'changedtick')
  local lnum_from, lnum_to = viewport()
  local new_coordinates = {changedtick, lnum_from, lnum_to, bufnr}
  if vim.deep_equal(old_coordinates, new_coordinates) then return end
  old_coordinates = new_coordinates
  local pattern_string = vim.api.nvim_eval('b:esearch.pattern.vim')
  _deferred_highlight_viewport(pattern_string, changedtick, lnum_from, lnum_to, bufnr)
end

function M.highlight_viewport()
  local lnum_from, lnum_to = viewport()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, lnum_from, lnum_to, false)
  local pattern = vim.regex(vim.api.nvim_eval('b:esearch.pattern.vim'))
  local ranges = matches_ranges(pattern, lines, lnum_from)
  set_matches_in_ranges(bufnr, ranges, lnum_from, lnum_to)
end

return M
