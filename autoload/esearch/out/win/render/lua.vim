if g:esearch#has#nvim_lua
  fu! esearch#out#win#render#lua#do(bufnr, data, from, to, esearch) abort
    let [files_count, contexts, context_ids_map, line_numbers_map, context_by_name] =
          \ luaeval('esearch_out_win_render_nvim(_A[1], _A[2], _A[3], _A[4])',
          \ [a:data[a:from : a:to], a:esearch.lua_cwd_prefix, a:esearch.contexts[-1], a:esearch.files_count])

    let a:esearch.files_count = files_count
    " let a:esearch.contexts =  contexts
    call extend(a:esearch.contexts, contexts[1:], len(a:esearch.contexts))
    call extend(a:esearch.context_ids_map, context_ids_map)
    call extend(a:esearch.line_numbers_map, line_numbers_map)
    let context_by_name = context_by_name
    if type(context_by_name) ==# type({})
      call extend(a:esearch.context_by_name, context_by_name)
    endif
  endfu

lua << EOF
function esearch_out_win_render_nvim(data, cwd, last_context, files_count)
  local parsed = {}
  -- local data = vim.api.nvim_eval('a:data[a:from : a:to]')
  -- local cwd = vim.api.nvim_eval('a:esearch.lua_cwd_prefix')
  for i = 1, #data do
    if data[i]:len() > 0 then
      filename, lnum, col, text = string.match(data[i], '([^:]+):(%d+):(%d+):(.*)')
      parsed[i] = {['filename'] = string.gsub(filename, cwd, ''),
      ['lnum'] = lnum, ['col'] = col, ['text'] = text:gsub("[\r\n]", '')}
    end
  end

  contexts = {last_context}
  line_numbers_map = {}
  context_ids_map = {}
  context_by_name = {}

  line = vim.api.nvim_buf_line_count(0)
  i = 1
  limit = #parsed + 1
  lines = {}

  while(i < limit)
  do
    filename = parsed[i]['filename']
    text = parsed[i]['text']

    if filename ~= contexts[#contexts]['filename'] then
      contexts[#contexts]['end'] = line

      -- unload colors

      lines[#lines + 1] = ''
      context_ids_map[#context_ids_map + 1]  = contexts[#contexts]['id']
      line_numbers_map[#line_numbers_map + 1] = 0
      line = line + 1


      lines[#lines + 1] = filename
      id = contexts[#contexts]['id'] + 1
      contexts[#contexts + 1] = {
        ['id'] = id,
        ['begin'] = line,
        ['end'] = 0,
        ['filename'] = filename,
        ['filetype'] = 0,
        ['syntax_loaded'] = 0,
        ['lines'] = {},
        }
      context_by_name[filename] = contexts[#contexts]
      context_ids_map[#context_ids_map + 1] = contexts[#contexts]['id']
      line_numbers_map[#line_numbers_map + 1] = 0
      files_count = files_count + 1
      line = line + 1
      contexts[#contexts]['filename'] = filename
    end

    lines[#lines + 1] = string.format(' %3d %s', parsed[i]['lnum'], text)
    context_ids_map[#context_ids_map + 1] = contexts[#contexts]['id']
    line_numbers_map[#line_numbers_map + 1] = parsed[i]['lnum']
    contexts[#contexts]['lines'][parsed[i]['lnum']] = text
    line = line + 1
    i = i + 1
  end

  vim.api.nvim_buf_set_lines(0, -1, -1, 0, lines)


  return {files_count, contexts, context_ids_map, line_numbers_map, context_by_name}

end
EOF

else
  fu! esearch#out#win#render#lua#do(bufnr, data, from, to, esearch) abort
    lua << EOF
    local parsed = vim.list()
    local cwd = vim.eval('a:esearch.lua_cwd_prefix')
    for raw_line in vim.eval('a:data[a:from : a:to]')() do
      if raw_line:len() > 0 then
        filename, lnum, col, text = string.match(raw_line, '([^:]+):(%d+):(%d+):(.*)')
        parsed:add(vim.dict({['filename'] = string.gsub(filename, cwd, ''), ['lnum'] = lnum, ['col'] = col, ['text'] = text}))
      end
    end

    local b = vim.buffer()

    contexts = vim.eval('a:esearch.contexts')
    line_numbers_map = vim.eval('a:esearch.line_numbers_map')
    context_ids_map = vim.eval('a:esearch.context_ids_map')
    files_count = vim.eval('a:esearch.files_count')
    context_by_name = vim.eval('a:esearch.context_by_name')

    line = vim.eval('line("$") + 1')
    i = 0
    limit = #parsed
    lines = {}

    while(i < limit)
    do
      filename = parsed[i]['filename']
      text = parsed[i]['text']

      if filename ~= contexts[#contexts - 1]['filename'] then
        contexts[#contexts - 1]['end'] = line

        -- colors

        b:insert('')
        context_ids_map:add(tostring(contexts[#contexts - 1]['id']))
        line_numbers_map:add(false)
        line = line + 1

        b:insert(filename)
        contexts:add(vim.dict({
          ['id']            = tostring(tonumber(contexts[#contexts - 1]['id']) + 1),
          ['begin']         = tostring(line),
          ['end']           = false,
          ['filename']      = filename,
          ['filetype']      = false,
          ['syntax_loaded'] = false,
          ['lines']         = vim.list({}),
          }))
        context_by_name[filename] = contexts[#contexts - 1]
        context_ids_map:add(contexts[#contexts - 1]['id'])
        line_numbers_map:add(false)
        files_count = files_count + 1
        line = line + 1
        contexts[#contexts - 1]['filename'] = filename
      end

      b:insert(string.format(' %3d %s', parsed[i]['lnum'], text))
      context_ids_map:add(contexts[#contexts - 1]['id'])
      line_numbers_map:add(parsed[i]['lnum'])
      contexts[#contexts - 1]['lines'][parsed[i]['lnum']] = text
      line = line + 1
      i = i + 1
    end
    vim.command('let a:esearch.files_count = ' .. files_count)
EOF
  endfu
endif
