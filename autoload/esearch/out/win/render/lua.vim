fu! esearch#out#win#render#lua#do(bufnr, data, from, to, esearch) abort
  lua << EOF
  local parsed = {}
  local data = vim.api.nvim_eval('a:data[a:from : a:to]')
  local cwd = vim.api.nvim_eval('a:esearch.lua_cwd_prefix')
  for i = 1, #data do
    if data[i]:len() > 0 then
      filename, lnum, col, text = string.match(data[i], '([^:]+):(%d+):(%d+):(.*)')
      parsed[i] = {['filename'] = string.gsub(filename, cwd, ''),
      ['lnum'] = lnum, ['col'] = col, ['text'] = text:gsub("[\r\n]", '')}
    end
  end

  contexts = {vim.api.nvim_eval('a:esearch.contexts[-1]')}
  line_numbers_map = {}
  context_ids_map = {}
  files_count = vim.api.nvim_eval('a:esearch.files_count')
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

      -- colors

      lines[#lines + 1] = ''
      context_ids_map[#context_ids_map + 1]  = contexts[#contexts]['id']
      line_numbers_map[#line_numbers_map + 1] = 0
      line = line + 1


      lines[#lines + 1] = filename
      id = #contexts
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
EOF

  let a:esearch.files_count = luaeval('files_count')
  call extend(a:esearch.contexts, luaeval('contexts')[1:])
  call extend(a:esearch.context_ids_map, luaeval('context_ids_map'))
  call extend(a:esearch.line_numbers_map, luaeval('line_numbers_map'))
  let context_by_name = luaeval('context_by_name')
  if type(context_by_name) ==# type({})
    call extend(a:esearch.context_by_name, context_by_name)
  endif
endfu
