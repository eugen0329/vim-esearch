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
    let cwd = esearch#win#lcd(a:esearch.cwd)
    try
      let [a:esearch.files_count, lines_delta, contexts, state,
         \ ctx_by_name, a:esearch.slow_hl_enabled, errors] =
         \   luaeval('esearch.render(_A[1], _A[2], _A[3], _A[4], _A[5], _A[6])', [
         \     a:bufnr, a:data[a:from : a:to], a:esearch.contexts[-1],
         \     a:esearch.files_count, a:esearch.slow_hl_enabled, a:esearch._adapter.parser])
    finally
      call cwd.restore()
    endtry
    let a:esearch.lines_delta += lines_delta
    let a:esearch.contexts[-1] = contexts[0]
    call extend(a:esearch.contexts, contexts[1:])
    call extend(a:esearch.state, state)
    if !empty(errors) | call esearch#stderr#append(a:esearch, errors) | endif
    if type(ctx_by_name) ==# type({})
      call extend(a:esearch.ctx_by_name, ctx_by_name)
    endif
  endfu
else
  fu! esearch#out#win#render#lua#do(bufnr, data, from, to, esearch) abort
    let cwd = esearch#win#lcd(a:esearch.cwd)
    try
      let [a:esearch.files_count, a:esearch.lines_delta, errors] =
            \ luaeval('vim.list({esearch.render(_A.d, _A.e, _A.p)})', 
            \   {'d': a:data[a:from : a:to], 'e': a:esearch, 'p': a:esearch._adapter.parser})
      if !empty(errors) | call esearch#stderr#append(a:esearch, errors) | endif
    finally
      call cwd.restore()
    endtry
  endfu
endif
