local ui = require('esearch/neovim/appearance/ui')
local set_timeout = require('esearch/util').set_timeout

local M = {
  MATCHES_NS       = vim.api.nvim_create_namespace('esearch_matches'),
  ATTACHED_MATCHES = {},
}

local function matches_cb(_event_name, _bufnr, _changedtick, from, old_to, to, _old_byte_size)
  if to == old_to then
    vim.api.nvim_buf_clear_namespace(0, M.MATCHES_NS, from, to)
  end
end

local function detach_matches_cb(bufnr)
  M.ATTACHED_MATCHES[bufnr] = nil
end

function M.buf_attach_matches()
  local bufnr = vim.api.nvim_get_current_buf()
  if not M.ATTACHED_MATCHES[bufnr] then
    M.ATTACHED_MATCHES[bufnr] = true
    vim.api.nvim_buf_attach(0, false, {on_lines=matches_cb, on_detach=detach_matches_cb})
  end
end

local function matches_ranges(pattern_string, lines, lnum_from)
  local pattern = vim.regex(pattern_string)
  local ranges = {}

  for i, line in ipairs(lines) do
    if line:sub(1,1) ~= ' ' then goto continue end

    local _, offset = line:find(ui.LINENR_RE)
    if not offset then goto continue end

    while true do
      if offset >= line:len() then break end
      local col_from, col_to = pattern:match_str(line:sub(offset))
      if not col_from then break end

      table.insert(ranges, {lnum_from + i - 1, col_from + offset - 1, col_to + offset - 1})
      offset = offset + col_to
    end

    ::continue::
  end

  return ranges
end

local function set_matches_at_ranges(bufnr, ranges, lnum_from, lnum_to)
  vim.api.nvim_buf_clear_namespace(bufnr, M.MATCHES_NS, lnum_from, lnum_to)
  for _, range in pairs(ranges) do
    vim.api.nvim_buf_add_highlight(bufnr, M.MATCHES_NS, 'esearchMatch', unpack(range))
  end
end

local function viewport()
  return vim.fn.line('w0') - 1, vim.fn.line('w$')
end

local old_coordinates

function M.deferred_highlight_viewport()
  local changedtick = vim.api.nvim_eval('b:changedtick')
  local bufnr = vim.api.nvim_get_current_buf()
  local lnum_from, lnum_to = viewport()
  local new_coordinates = {changedtick, lnum_from, lnum_to, bufnr}
  if vim.deep_equal(old_coordinates, new_coordinates) then return end
  old_coordinates = new_coordinates

  local lines = vim.api.nvim_buf_get_lines(bufnr, lnum_from, lnum_to, 1)
  local pattern = vim.api.nvim_eval('b:esearch.pattern.vim')

  M.timer = set_timeout(function()
    local ranges = matches_ranges(pattern, lines, lnum_from, bufnr, changedtick)

    vim.schedule(function()
      if vim.api.nvim_eval('b:changedtick') ~= changedtick then return end
      set_matches_at_ranges(bufnr, ranges, lnum_from, lnum_to)
    end)
  end, 0)
end

function M.highlight_viewport()
  local lnum_from, lnum_to = viewport()
  local lines = vim.api.nvim_buf_get_lines(0, lnum_from, lnum_to, 1)
  local pattern = vim.api.nvim_eval('b:esearch.pattern.vim')
  local ranges = matches_ranges(pattern, lines, lnum_from)
  set_matches_at_ranges(0, ranges, lnum_from, lnum_to)
end

return M
