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
    let original_cwd = esearch#util#lcd(a:esearch.cwd)
    try
      let [files_count, contexts, ctx_ids_map, line_numbers_map, context_by_name, separators_count, highlights_enabled] =
            \ luaeval('esearch.render(_A[1], _A[2], _A[3], _A[4], _A[5], _A[6])',
            \ [a:data[a:from : a:to],
            \ get(a:esearch.paths, 0, ''),
            \ a:esearch.contexts[-1],
            \ a:esearch.files_count,
            \ a:esearch.highlights_enabled])
    finally
      call original_cwd.restore()
    endtry

    let a:esearch.files_count = files_count
    let a:esearch.separators_count += separators_count
    let a:esearch.highlights_enabled = highlights_enabled
    let a:esearch.contexts[-1] = contexts[0]
    call extend(a:esearch.contexts, contexts[1:])
    call extend(a:esearch.ctx_ids_map, ctx_ids_map)
    call extend(a:esearch.line_numbers_map, line_numbers_map)
    let context_by_name = context_by_name
    if type(context_by_name) ==# type({})
      call extend(a:esearch.context_by_name, context_by_name)
    endif
  endfu

  fu! esearch#out#win#render#lua#nvim_syntax_attach_callback(esearch) abort
  endfu
else
  fu! esearch#out#win#render#lua#do(bufnr, data, from, to, esearch) abort
    let original_cwd = esearch#util#lcd(a:esearch.cwd)
    try
      let a:esearch['files_count'] = luaeval('esearch.render(_A[0], _A[1], _A[2], _A[3], _A[4])',
            \ [a:data[a:from : a:to],
            \ get(b:esearch.paths, 0, ''),
            \ a:esearch])
    finally
      call original_cwd.restore()
    endtry
  endfu
endif
