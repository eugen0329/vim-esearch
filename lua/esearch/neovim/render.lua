local parse = require'esearch/neovim/parse'
local util  = require'esearch/util'

local M = {renderers = {}}

function M.prepare(last_context, files_count, slow_hl_enabled, parsed, from, to, separators_count, from_line)
  local contexts = {last_context}
  local line_numbers_map = {}
  local ctx_ids_map = {}
  local ctx_by_name = {}
  local win_contexts_syntax_clear_on_files_count =
    vim.api.nvim_eval('g:esearch.win_contexts_syntax_clear_on_files_count')
  local win_context_syntax_max_line_len =
    vim.api.nvim_eval('g:esearch.win_context_syntax_clear_on_line_len')
  local win_contexts_syntax_clear_on_line_len =
    vim.api.nvim_eval('g:esearch.win_contexts_syntax_clear_on_line_len')

  local line = from_line
  local lines = {}

  local deferred_calls = {}

  for i = from, to do
    local entry = parsed[i]
    local filename = entry.filename
    local text = entry.text

    -- IF new filename encountered
    if filename ~= contexts[#contexts].filename then
      contexts[#contexts]['end'] = line

      if util.is_true(slow_hl_enabled) and contexts[#contexts].id > win_contexts_syntax_clear_on_files_count then
        slow_hl_enabled = false
        table.insert(deferred_calls, 'esearch#out#win#stop_highlights("too many lines")')
      end

      -- add SEPARATOR
      lines[#lines + 1] = ''
      ctx_ids_map[#ctx_ids_map + 1]  = contexts[#contexts].id
      line_numbers_map[#line_numbers_map + 1] = 0
      line = line + 1

      -- add FILENAME
      lines[#lines + 1] = util.fnameescape(filename)
      contexts[#contexts + 1] = {
        ['id']            = contexts[#contexts].id + 1,
        ['begin']         = line,
        ['end']           = 0,
        ['filename']      = filename,
        ['filetype']      = 0,
        ['loaded_syntax'] = 0,
        ['lines']         = {},
        ['rev']           = entry.rev,
        }
      ctx_by_name[filename] = contexts[#contexts]
      ctx_ids_map[#ctx_ids_map + 1] = contexts[#contexts].id
      line_numbers_map[#line_numbers_map + 1] = 0
      files_count = files_count + 1
      line = line + 1
    end

    if text:len() > win_context_syntax_max_line_len then
      if text:len() > win_contexts_syntax_clear_on_line_len and util.is_true(slow_hl_enabled) then
        slow_hl_enabled = false
        table.insert(deferred_calls, 'esearch#out#win#stop_highlights("too long line encountered")')
      else
        contexts[#contexts]['loaded_syntax'] = -1
      end
    end

    -- add LINE
    lines[#lines + 1] = string.format(' %3d %s', entry.lnum, text)
    ctx_ids_map[#ctx_ids_map + 1] = contexts[#contexts].id
    line_numbers_map[#line_numbers_map + 1] = entry.lnum
    contexts[#contexts]['lines'][entry.lnum] = text
    line = line + 1
  end

  return lines, files_count, contexts, ctx_ids_map, line_numbers_map, ctx_by_name,
         separators_count, slow_hl_enabled, deferred_calls
end

function M.submit_updates(lines, contexts, deferred_calls, from_line)
  for _, call in pairs(deferred_calls) do vim.api.nvim_eval(call) end

  vim.api.nvim_buf_set_lines(0, -1, -1, 0, lines)
  if vim.api.nvim_eval('g:esearch.win_ui_nvim_syntax') == 1 then
    esearch.appearance.highlight_header()
    esearch.appearance.highlight_ui(0, from_line, -1)
  end
  if vim.api.nvim_eval('g:esearch.win_context_len_annotations') == 1 then
    esearch.appearance.annotate(contexts)
  end
end

function M.render(data, last_context, files_count, slow_hl_enabled, parser)
  local parsed, separators_count = parse.lines(data, parser)
  local lines, contexts, ctx_ids_map, line_numbers_map, ctx_by_name, deferred_calls
  local from_line = vim.api.nvim_buf_line_count(0)

  lines,
  files_count,
  contexts,
  ctx_ids_map,
  line_numbers_map,
  ctx_by_name,
  separators_count,
  slow_hl_enabled,
  deferred_calls = M.prepare(last_context, files_count, slow_hl_enabled, parsed,
                             1, #parsed, separators_count, from_line)

  M.submit_updates(lines, contexts, deferred_calls, from_line)

  return {
    files_count,
    separators_count,
    contexts,
    ctx_ids_map,
    line_numbers_map,
    ctx_by_name,
    slow_hl_enabled,
  }
end

return M
