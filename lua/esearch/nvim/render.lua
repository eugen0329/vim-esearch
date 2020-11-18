local parse = require('esearch/nvim/parse').parse
local util  = require('esearch/shared/util')

local M = {}

function M.prepare(last_context, files_count, slow_hl_enabled, parsed, from, to, lines_delta, from_line)
  local contexts = {last_context}
  local state = {}
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
      contexts[#contexts]['end'] = line + 1

      if util.is_true(slow_hl_enabled) and contexts[#contexts].id > win_contexts_syntax_clear_on_files_count then
        slow_hl_enabled = false
        table.insert(deferred_calls, 'esearch#out#win#stop_highlights("too many lines")')
      end

      -- add SEPARATOR
      lines[#lines + 1] = ''
      state[#state + 1]  = contexts[#contexts].id
      line = line + 1

      -- add FILENAME
      lines[#lines + 1] = util.fnameescape(filename)
      contexts[#contexts + 1] = {
        ['id']            = contexts[#contexts].id + 1,
        ['begin']         = line + 1,
        ['end']           = 0,
        ['filename']      = filename,
        ['filetype']      = 0,
        ['loaded_syntax'] = 0,
        ['lines']         = {},
        ['rev']           = entry.rev and 1 or 0,
      }
      ctx_by_name[filename] = contexts[#contexts]
      state[#state + 1] = contexts[#contexts].id
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
    state[#state + 1] = contexts[#contexts].id
    contexts[#contexts]['lines'][entry.lnum] = text
    line = line + 1
  end

  return lines, files_count, contexts, state, ctx_by_name,
         lines_delta, slow_hl_enabled, deferred_calls
end

function M.submit_updates(bufnr, lines, contexts, deferred_calls, from_line)
  for _, call in pairs(deferred_calls) do vim.api.nvim_eval(call) end

  vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, lines)
  if vim.api.nvim_eval('g:esearch.win_ui_nvim_syntax') == 1 then
    esearch.highlight_header(bufnr)
    esearch.highlight_ui(bufnr, from_line, -1)
  end
  if vim.api.nvim_eval('g:esearch.win_context_len_annotations') == 1 then
    esearch.annotate(contexts)
  end
end

function M.render(bufnr, data, last_context, files_count, slow_hl_enabled, parser)
  local parsed, lines_delta, errors = parse(data, parser)
  local lines, contexts, state, ctx_by_name, deferred_calls
  local from_line = vim.api.nvim_buf_line_count(0)

  lines,
  files_count,
  contexts,
  state,
  ctx_by_name,
  lines_delta,
  slow_hl_enabled,
  deferred_calls = M.prepare(last_context, files_count, slow_hl_enabled, parsed,
                             1, #parsed, lines_delta, from_line)

  M.submit_updates(bufnr, lines, contexts, deferred_calls, from_line)

  return {
    files_count,
    lines_delta,
    contexts,
    state,
    ctx_by_name,
    slow_hl_enabled,
    errors
  }
end

return M
