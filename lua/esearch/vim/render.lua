local parse = require'esearch/vim/parse'
local util  = require'esearch/util'

local M = {}

function M.render(data, esearch)
  local parsed, _separators_count = parse.lines(data)
  local contexts                 = esearch['contexts']
  local line_numbers_map         = esearch['line_numbers_map']
  local ctx_ids_map              = esearch['ctx_ids_map']
  local files_count              = esearch['files_count']
  local ctx_by_name              = esearch['ctx_by_name']
  local esearch_win_contexts_syntax_clear_on_files_count =
    vim.eval('g:esearch.win_contexts_syntax_clear_on_files_count')
  local esearch_win_context_syntax_max_line_len =
    vim.eval('g:esearch.win_context_syntax_clear_on_line_len')
  local esearch_win_contexts_syntax_clear_on_line_len =
    vim.eval('g:esearch.win_contexts_syntax_clear_on_line_len')

  local b = vim.buffer()
  local line = vim.eval('line("$") + 1')
  local i = 0
  local limit = #parsed

  while(i < limit) do
    local filename = parsed[i]['filename']
    local text = parsed[i]['text']

    if filename ~= contexts[#contexts - 1]['filename'] then
      contexts[#contexts - 1]['end'] = line

      if util.is_true(esearch['slow_hl_enabled']) and
          #contexts > esearch_win_contexts_syntax_clear_on_files_count then
        esearch['slow_hl_enabled'] = false
        vim.eval('esearch#out#win#stop_highlights("too many lines")')
      end

      b:insert('')
      ctx_ids_map:add(tostring(contexts[#contexts - 1]['id']))
      line_numbers_map:add(false)
      line = line + 1

      b:insert(util.fnameescape(filename))
      contexts:add(vim.dict({
        ['id']            = tostring(tonumber(contexts[#contexts - 1]['id']) + 1),
        ['begin']         = tostring(line),
        ['end']           = false,
        ['filename']      = filename,
        ['filetype']      = false,
        ['loaded_syntax'] = false,
        ['lines']         = vim.dict(),
        }))
      ctx_by_name[filename] = contexts[#contexts - 1]
      ctx_ids_map:add(contexts[#contexts - 1]['id'])
      line_numbers_map:add(false)
      files_count = files_count + 1
      line = line + 1
      contexts[#contexts - 1]['filename'] = filename
    end

    if text:len() > esearch_win_context_syntax_max_line_len then
      if text:len() > esearch_win_contexts_syntax_clear_on_line_len and util.is_true(esearch['slow_hl_enabled']) then
        esearch['slow_hl_enabled'] = false
        vim.eval('esearch#out#win#stop_highlights("too long line encountered")')
      else
        contexts[#contexts - 1]['loaded_syntax'] = true
      end
    end

    b:insert(string.format(' %3d %s', parsed[i]['lnum'], text))
    ctx_ids_map:add(contexts[#contexts - 1]['id'])
    line_numbers_map:add(parsed[i]['lnum'])
    contexts[#contexts - 1]['lines'][parsed[i]['lnum']] = text
    line = line + 1
    i = i + 1
  end

  return tostring(files_count)
end

return M
