if !g:esearch#has#lua
  finish
endif

" Vim and neovim use completely different approaches to work with lua, so it's
" not obvious yet how to reuse the code without affecting the performance (as
" it's the most intensively called function and is the only bottleneck so far).
"
" Major differences are:
"   - Different api's are used. Vim exposes vim.* methods, neovim mostly use
"   vim.api.*
"   - In vim data is changed directly by changing a lua structure, in neovim we
"   have to return a value using luaeval() and merge using extend() (still
"   haven't found a way except nvim_buf_set_var that is running twice longer).
"   - Vim wraps data structures to partially implement viml-like api on top of
"   them, neovim uses lua primitives
"   - Due to the note above, in vim indexing starts from 0, in neovim - from 1.
"   The same is with luaeval magic _A global constant
"   - Different serialization approaches. Ex: vim doesn't distinguish float and
"   int, while neovim does

if g:esearch#has#nvim_lua
  fu! esearch#out#win#render#lua#do(bufnr, data, from, to, esearch) abort
    let [files_count, contexts, context_ids_map, line_numbers_map, context_by_name] =
          \ luaeval('esearch_out_win_render_nvim(_A[1], _A[2], _A[3], _A[4], _A[5], _A[6], _A[7])',
          \ [a:data[a:from : a:to],
          \ a:esearch.is_single_file(),
          \ get(a:esearch.paths, 0, ''),
          \ a:esearch.lua_cwd_prefix,
          \ a:esearch.contexts[-1],
          \ a:esearch.files_count,
          \ a:esearch.highlights_enabled])

    let a:esearch.files_count = files_count
    call extend(a:esearch.contexts, contexts[1:])
    call extend(a:esearch.context_ids_map, context_ids_map)
    call extend(a:esearch.line_numbers_map, line_numbers_map)
    let context_by_name = context_by_name
    if type(context_by_name) ==# type({})
      call extend(a:esearch.context_by_name, context_by_name)
    endif
  endfu
else
  fu! esearch#out#win#render#lua#do(bufnr, data, from, to, esearch) abort
  call luaeval('esearch_out_win_render_vim(_A[0], _A[1], _A[2], _A[3], _A[4], _A[5])',
          \ [a:data[a:from : a:to],
          \ a:esearch.is_single_file(),
          \ get(a:esearch.paths, 0, ''),
          \ a:esearch.lua_cwd_prefix,
          \ a:esearch])
  endfu
endif

if g:esearch#has#nvim_lua
lua << EOF
function parse_from_1_file(data, path, cwd_prefix)
  local parsed = {}

  for i = 1, #data do
    if data[i]:len() > 0 then
      lnum, text = string.match(data[i], '(%d+):(.*)')
      parsed[#parsed + 1] = {
        ['filename'] = path,
        ['lnum']     = lnum,
        ['text']     = text:gsub("[\r\n]", '')
      }
    end
  end

  return parsed
end

function parse_from_multiple_files_file(data, cwd_prefix)
  local parsed = {}

  for i = 1, #data do
    if data[i]:len() > 0 then
      filename, lnum, text = string.match(data[i], '([^:]+):(%d+):(.*)')
      if filename == nil or lnum == nil or text == nil then
        -- TODO errors handling
      else
        parsed[#parsed + 1] = {
          ['filename'] = string.gsub(filename, cwd_prefix, ''),
          ['lnum']     = lnum,
          ['text']     = text:gsub("[\r\n]", '')
        }
      end
    end
  end

  return parsed
end

function esearch_out_win_render_nvim(data, is_single_file, path, cwd_prefix, last_context, files_count, highlights_enabled)
  if is_single_file == 1 then
    parsed = parse_from_1_file(data, path, cwd_prefix)
  else
    parsed = parse_from_multiple_files_file(data, cwd_prefix)
  end

  contexts = {last_context}
  line_numbers_map = {}
  context_ids_map = {}
  context_by_name = {}
  esearch_win_disable_context_highlights_on_files_count =
    vim.api.nvim_get_var('esearch_win_disable_context_highlights_on_files_count')

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

      if highlights_enabled == 1 and
          contexts[#contexts]['id'] > esearch_win_disable_context_highlights_on_files_count then
        highlights_enabled = 0
        vim.api.nvim_call_function('esearch#out#win#unload_highlights', {})
      end

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
lua << EOF
function parse_from_1_file(data, path, cwd_prefix)
  local parsed = vim.list()

  for i = 0, #data - 1 do
    if data[i]:len() > 0 then
      lnum, text = string.match(data[i], '(%d+):(.*)')
      parsed:add(vim.dict({
        ['filename'] = path,
        ['lnum']     = lnum,
        ['text']     = text:gsub("[\r\n]", '')
      }))
    end
  end

  return parsed
end

function parse_from_multiple_files_file(data, cwd_prefix)
  local parsed = vim.list()

  for i = 0, #data - 1 do
    if data[i]:len() > 0 then
      filename, lnum, text = string.match(data[i], '([^:]+):(%d+):(.*)')
      if filename == nil or lnum == nil or text == nil then
        -- TODO errors handling
      else
        parsed:add(vim.dict({
          ['filename'] = string.gsub(filename, cwd_prefix, ''),
          ['lnum']     = lnum,
          ['text']     = text:gsub("[\r\n]", '')
        }))
      end
    end
  end

  return parsed
end

function esearch_out_win_render_vim(data, is_single_file, path, cwd_prefix, esearch)
  if is_single_file == 1 then
    parsed = parse_from_1_file(data, path, cwd_prefix)
  else
    parsed = parse_from_multiple_files_file(data, cwd_prefix)
  end

  contexts         = esearch['contexts']
  line_numbers_map = esearch['line_numbers_map']
  context_ids_map  = esearch['context_ids_map']
  files_count      = esearch['files_count']
  context_by_name  = esearch['context_by_name']

  esearch_win_disable_context_highlights_on_files_count =
    vim.eval('g:esearch_win_disable_context_highlights_on_files_count')
  local b = vim.buffer()
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

      if esearch['highlights_enabled'] == 1 and
          #contexts > esearch_win_disable_context_highlights_on_files_count then
        esearch['highlights_enabled'] = false
        vim.eval('esearch#out#win#unload_highlights()')
      end

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
        ['lines']         = vim.dict(),
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
  esearch['files_count'] = tostring(files_count)
end
EOF
endif
