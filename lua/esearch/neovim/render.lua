local parse = require'esearch/neovim/parse'
local util  = require'esearch/util'

local function apply(data, path, last_context, files_count, highlights_enabled)
  local parsed, separators_count = parse.lines(data)
  local contexts = {last_context}
  local line_numbers_map = {}
  local ctx_ids_map = {}
  local context_by_name = {}
  local esearch_win_disable_context_highlights_on_files_count =
    vim.api.nvim_get_var('esearch_win_disable_context_highlights_on_files_count')
  local unload_context_syntax_on_line_length =
    vim.api.nvim_get_var('unload_context_syntax_on_line_length')
  local unload_global_syntax_on_line_length =
    vim.api.nvim_get_var('unload_global_syntax_on_line_length')

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

      if highlights_enabled == 1 and
          contexts[#contexts]['id'] > esearch_win_disable_context_highlights_on_files_count then
        highlights_enabled = false
        vim.api.nvim_call_function('esearch#out#win#unload_highlights', {})
      end

      lines[#lines + 1] = ''
      ctx_ids_map[#ctx_ids_map + 1]  = contexts[#contexts]['id']
      line_numbers_map[#line_numbers_map + 1] = 0
      line = line + 1

      lines[#lines + 1] = util.fnameescape(filename)
      id = contexts[#contexts]['id'] + 1
      contexts[#contexts + 1] = {
        ['id']            = id,
        ['begin']         = line,
        ['end']           = 0,
        ['filename']      = filename,
        ['filetype']      = 0,
        ['syntax_loaded'] = 0,
        ['lines']         = {},
        }
      context_by_name[filename] = contexts[#contexts]
      ctx_ids_map[#ctx_ids_map + 1] = contexts[#contexts]['id']
      line_numbers_map[#line_numbers_map + 1] = 0
      files_count = files_count + 1
      line = line + 1
      contexts[#contexts]['filename'] = filename
    end

    if text:len() > unload_context_syntax_on_line_length then
      if text:len() > unload_global_syntax_on_line_length then
        vim.api.nvim_eval('esearch#out#win#_blocking_unload_syntaxes(b:esearch)')
      else
        contexts[#contexts]['syntax_loaded'] = -1
      end
    end

    linenr_text = string.format(' %3d ', parsed[i]['lnum'])

    lines[#lines + 1] = linenr_text .. text
    ctx_ids_map[#ctx_ids_map + 1] = contexts[#contexts]['id']
    line_numbers_map[#line_numbers_map + 1] = parsed[i]['lnum']
    contexts[#contexts]['lines'][parsed[i]['lnum']] = text
    line = line + 1
    i = i + 1
  end

  vim.api.nvim_buf_set_lines(0, -1, -1, 0, lines)
  if vim.api.nvim_eval('g:esearch_out_win_nvim_lua_syntax') == 1 then
    esearch.highlight.linenrs_range(0, start, -1)
  end

  return {files_count, contexts, ctx_ids_map, line_numbers_map, context_by_name, separators_count}
end

return { apply = apply }
