local parse = require'esearch/vim/parse'
local util  = require'esearch/util'

function apply(data, path, esearch)
  local parsed, separators_count = parse.lines(data)
  local contexts                 = esearch['contexts']
  local line_numbers_map         = esearch['line_numbers_map']
  local ctx_ids_map              = esearch['ctx_ids_map']
  local files_count              = esearch['files_count']
  local context_by_name          = esearch['context_by_name']
  local esearch_win_disable_context_highlights_on_files_count =
    vim.eval('g:esearch_win_disable_context_highlights_on_files_count')
  local unload_context_syntax_on_line_length =
    vim.eval('g:unload_context_syntax_on_line_length')
  local unload_global_syntax_on_line_length =
    vim.eval('g:unload_global_syntax_on_line_length')

  local b = vim.buffer()
  local line = vim.eval('line("$") + 1')
  local i = 0
  local limit = #parsed
  local lines = {}

  while(i < limit)
  do
    local filename = parsed[i]['filename']
    local text = parsed[i]['text']

    if filename ~= contexts[#contexts - 1]['filename'] then
      contexts[#contexts - 1]['end'] = line

      if esearch['highlights_enabled'] == 1 and
          #contexts > esearch_win_disable_context_highlights_on_files_count then
        esearch['highlights_enabled'] = false
        vim.eval('esearch#out#win#unload_highlights()')
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
        ['syntax_loaded'] = false,
        ['lines']         = vim.dict(),
        }))
      context_by_name[filename] = contexts[#contexts - 1]
      ctx_ids_map:add(contexts[#contexts - 1]['id'])
      line_numbers_map:add(false)
      files_count = files_count + 1
      line = line + 1
      contexts[#contexts - 1]['filename'] = filename
    end

    if text:len() > unload_context_syntax_on_line_length then
      if text:len() > unload_global_syntax_on_line_length then
        vim.eval('esearch#out#win#_blocking_unload_syntaxes(b:esearch)')
      else
        contexts[#contexts - 1]['syntax_loaded'] = true
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

return { apply = apply }
