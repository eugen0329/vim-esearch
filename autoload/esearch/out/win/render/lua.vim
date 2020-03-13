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
    let [files_count, contexts, ctx_ids_map, line_numbers_map, context_by_name] =
          \ luaeval('esearch_out_win_render_nvim(_A[1], _A[2], _A[3], _A[4], _A[5], _A[6], _A[7])',
          \ [a:data[a:from : a:to],
          \ get(a:esearch.paths, 0, ''),
          \ a:esearch.lua_cwd_prefix,
          \ a:esearch.contexts[-1],
          \ a:esearch.files_count,
          \ a:esearch.highlights_enabled])

    let a:esearch.files_count = files_count
    call extend(a:esearch.contexts, contexts[1:])
    call extend(a:esearch.ctx_ids_map, ctx_ids_map)
    call extend(a:esearch.line_numbers_map, line_numbers_map)
    let context_by_name = context_by_name
    if type(context_by_name) ==# type({})
      call extend(a:esearch.context_by_name, context_by_name)
    endif
  endfu

  fu! esearch#out#win#render#lua#init_nvim_syntax(esearch) abort
    call luaeval('highlight_linenrs_in_range(0,1)')
    let a:esearch.lines_changed_callback_enabled = 0
  endfu

  fu! esearch#out#win#render#lua#nvim_syntax_attach_callback(esearch) abort
    if b:esearch.lines_changed_callback_enabled | return | endif

    let a:esearch.lines_changed_callback_enabled = 1
    call luaeval('vim.api.nvim_buf_attach(0, false, {on_lines=update_linenrs_highlights_cb})')
  endfu
else
  fu! esearch#out#win#render#lua#do(bufnr, data, from, to, esearch) abort
  let a:esearch['files_count'] = luaeval('esearch_out_win_render_vim(_A[0], _A[1], _A[2], _A[3], _A[4], _A[5])',
          \ [a:data[a:from : a:to],
          \ get(b:esearch.paths, 0, ''),
          \ a:esearch.lua_cwd_prefix,
          \ a:esearch])
  endfu
endif

lua << EOF
function parse_line(filereadable_cache, line)
  local offset = 1
  local filename = ''

  while true do
    local _, idx = line:find(':', offset)

    if idx == nil then
      return
    end

    filename = line:sub(1, idx - 1)
    offset = idx + 1
    if filereadable(filename) == 1 then
      break
    end
  end

  local line, text = string.match(line, '(%d+)[-:](.*)', offset)
  if line == nil or text == nil then
    return
  end

  return filename, line, text
end

EOF

if g:esearch#has#nvim_lua
lua << EOF
function filereadable(path)
  return vim.api.nvim_call_function('filereadable', {path})
end
function fnameescape(path)
  return vim.api.nvim_call_function('fnameescape', {path})
end

function parse_from_multiple_files_file(data, cwd_prefix)
  local parsed = {}
  local filereadable_cache = {}

  for i = 1, #data do
    local line = data[i]

    if line:len() > 0 then
      local filename, lnum, text = parse_line(filereadable_cache, line)

      if filename ~= nil then
        filereadable_cache[filename] = true
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

function esearch_out_win_render_nvim(data, path, cwd_prefix, last_context, files_count, highlights_enabled)
  local parsed = parse_from_multiple_files_file(data, cwd_prefix)
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

      lines[#lines + 1] = fnameescape(filename)
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

    lines[#lines + 1] = linenr_text .. (text)
    ctx_ids_map[#ctx_ids_map + 1] = contexts[#contexts]['id']
    line_numbers_map[#line_numbers_map + 1] = parsed[i]['lnum']
    contexts[#contexts]['lines'][parsed[i]['lnum']] = text
    line = line + 1
    i = i + 1
  end

  vim.api.nvim_buf_set_lines(0, -1, -1, 0, lines)
  if vim.api.nvim_eval('g:esearch_out_win_nvim_lua_syntax') == 1 then
    highlight_linenrs_in_range(start, -1)
  end

  return {files_count, contexts, ctx_ids_map, line_numbers_map, context_by_name}
end

function update_linenrs_highlights_cb(_, bufnr, ct, from, old_to, to, _old_byte_size)
  if vim.api.nvim_call_function('exists', {'b:esearch'}) == 0 then
    return true
  end

  if to > old_to then -- if lines are added
    highlight_linenrs_in_range(from, to)
  end
end

function highlight_linenrs_in_range(from, to)
  local lines = vim.api.nvim_buf_get_lines(0, from, to, false)

  for i, text in ipairs(lines) do
    if i == 0 then
      vim.api.nvim_buf_add_highlight(0, -1, 'esearchHeader', 0, 0, -1)
    elseif text:len() == 0 then
      -- noop
    elseif text:sub(1,1) == ' ' then
      pos1, pos2 =  text:find('%s+%d+%s')
      if pos2 ~= nil then
        vim.api.nvim_buf_add_highlight(0, -1, 'esearchLineNr', i + from - 1 , 0, pos2)
      end
    else
      vim.api.nvim_buf_add_highlight(0, -1, 'esearchFilename', i + from - 1 , 0, -1)
    end
  end
end
EOF

else

lua << EOF
function filereadable(path)
  return vim.funcref('filereadable')(path)
end
function fnameescape(path)
  return vim.funcref('fnameescape')(path)
end

function parse_from_multiple_files_file(data, cwd_prefix)
  local parsed = vim.list()
  local filereadable_cache = {}

  for i = 0, #data - 1 do
    local line = data[i]

    if line:len() > 0 then
      local filename, lnum, text = parse_line(filereadable_cache, line)

      if filename ~= nil  then
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

function esearch_out_win_render_vim(data, path, cwd_prefix, esearch)
  local parsed           = parse_from_multiple_files_file(data, cwd_prefix)
  local contexts         = esearch['contexts']
  local line_numbers_map = esearch['line_numbers_map']
  local ctx_ids_map      = esearch['ctx_ids_map']
  local files_count      = esearch['files_count']
  local context_by_name  = esearch['context_by_name']
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

      b:insert(fnameescape(filename))
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
        contexts[#contexts - 1]['syntax_loaded'] = -1
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
EOF
endif
