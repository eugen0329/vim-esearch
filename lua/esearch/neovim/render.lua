local parse = require'esearch/neovim/parse'
local util  = require'esearch/util'

local M = {}

function M.render(data, last_context, files_count, slow_hl_enabled)
  local parsed, separators_count = parse.lines(data)
  local contexts = {last_context}
  local line_numbers_map = {}
  local ctx_ids_map = {}
  local ctx_by_name = {}
  local esearch_win_contexts_syntax_clear_on_files_count =
    vim.api.nvim_eval('g:esearch.win_contexts_syntax_clear_on_files_count')
  local esearch_win_context_syntax_max_line_len =
    vim.api.nvim_eval('g:esearch.win_context_syntax_clear_on_line_len')
  local esearch_win_contexts_syntax_clear_on_line_len =
    vim.api.nvim_eval('g:esearch.win_contexts_syntax_clear_on_line_len')
  local esearch_win_context_len_annotations =
    vim.api.nvim_eval('g:esearch.win_context_len_annotations')

  local start = vim.api.nvim_buf_line_count(0)
  local line = start
  local i = 1
  local limit = #parsed + 1
  local lines = {}

  while(i < limit)
  do
    local filename = parsed[i]['filename']
    local text = parsed[i]['text']

    if filename ~= contexts[#contexts]['filename'] then
      contexts[#contexts]['end'] = line

      if util.is_true(slow_hl_enabled) and
          contexts[#contexts]['id'] > esearch_win_contexts_syntax_clear_on_files_count then
        slow_hl_enabled = false
        vim.api.nvim_eval('esearch#out#win#stop_highlights("too many lines")')
      end

      lines[#lines + 1] = ''
      ctx_ids_map[#ctx_ids_map + 1]  = contexts[#contexts]['id']
      line_numbers_map[#line_numbers_map + 1] = 0
      line = line + 1

      lines[#lines + 1] = util.fnameescape(filename)
      contexts[#contexts + 1] = {
        ['id']            = contexts[#contexts]['id'] + 1,
        ['begin']         = line,
        ['end']           = 0,
        ['filename']      = filename,
        ['filetype']      = 0,
        ['syntax_loaded'] = 0,
        ['lines']         = {},
        }
      ctx_by_name[filename] = contexts[#contexts]
      ctx_ids_map[#ctx_ids_map + 1] = contexts[#contexts]['id']
      line_numbers_map[#line_numbers_map + 1] = 0
      files_count = files_count + 1
      line = line + 1
      contexts[#contexts]['filename'] = filename
    end

    if text:len() > esearch_win_context_syntax_max_line_len then
      if text:len() > esearch_win_contexts_syntax_clear_on_line_len and util.is_true(slow_hl_enabled) then
        slow_hl_enabled = false
        vim.api.nvim_eval('esearch#out#win#stop_highlights("too long line encountered")')
      else
        contexts[#contexts]['syntax_loaded'] = -1
      end
    end

    lines[#lines + 1] = string.format(' %3d %s', parsed[i]['lnum'], text)
    ctx_ids_map[#ctx_ids_map + 1] = contexts[#contexts]['id']
    line_numbers_map[#line_numbers_map + 1] = parsed[i]['lnum']
    contexts[#contexts]['lines'][parsed[i]['lnum']] = text
    line = line + 1
    i = i + 1
  end

  vim.api.nvim_buf_set_lines(0, -1, -1, 0, lines)
  if vim.api.nvim_eval('g:esearch.win_ui_nvim_syntax') == 1 then
    esearch.appearance.highlight_header()
    esearch.appearance.highlight_ui(0, start, -1)
  end
  if esearch_win_context_len_annotations == 1 then
    esearch.appearance.annotate(contexts)
  end

  return {files_count, contexts, ctx_ids_map, line_numbers_map, ctx_by_name, separators_count, slow_hl_enabled}
end

return M
