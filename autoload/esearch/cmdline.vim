let s:cmdline_mappings = {
      \ '<C-o>': '<Plug>(esearch-cmdline-open-menu)',
      \ '<C-r><C-r>': '<Plug>(esearch-toggle-regex)',
      \ '<C-s><C-s>': '<Plug>(esearch-toggle-case)',
      \ '<C-b><C-b>': '<Plug>(esearch-toggle-word)',
      \ 'dict':  function('esearch#util#dict'),
      \}

if !exists('g:esearch#cmdline#dir_icon')
  if g:esearch#has#unicode
    let g:esearch#cmdline#dir_icon = g:esearch#unicode#dir_icon
  else
    let g:esearch#cmdline#dir_icon = 'D '
  endif
endif

if !exists('g:esearch#cmdline#clear_selection_chars')
  let g:esearch#cmdline#clear_selection_chars = [
        \ "\<Del>",
        \ "\<Bs>",
        \ "\<C-w>",
        \ ]
endif
if !exists('g:esearch#cmdline#start_search_chars')
  let g:esearch#cmdline#start_search_chars = [
        \ "\<Enter>",
        \ ]
endif
if !exists('g:esearch#cmdline#cancel_selection_and_retype_chars')
  let g:esearch#cmdline#cancel_selection_and_retype_chars = [
        \ "\<Left>",
        \ "\<Right>",
        \ "\<Up>",
        \ "\<Down>",
        \ ]
endif
if !exists('g:esearch#cmdline#cancel_selection_chars')
  let g:esearch#cmdline#cancel_selection_chars = [
        \ "\<Esc>",
        \ "\<C-c>",
        \ ]
endif

if !exists('g:esearch#cmdline#select_initial')
  let g:esearch#cmdline#select_initial = 1
endif

fu! esearch#cmdline#read(esearch) abort
  let esearch = a:esearch
  let old_mapargs = {}
  try
    let old_mapargs = s:init_mappings()
    let esearch = s:app(a:esearch, 'search_input')
  finally
    call s:recover_mappings(old_mapargs)
  endtry

  if empty(esearch.str)
    let esearch.exp = {}
    return esearch
  endif

  if esearch.regex
    let esearch.exp.literal = esearch.str
    let esearch.exp.pcre = esearch.str
    let esearch.exp.vim = esearch#regex#pcre2vim(esearch.str)
  else
    let esearch.exp.literal = esearch.str
    let esearch.exp.pcre = esearch.str
    let esearch.exp.vim = '\M'.escape(esearch.str, '\$^')
  endif

  return esearch
endfu

fu! s:is_commandline_hotkey_prefix(char) abort
  return mapcheck(a:char, 'c') !=# ''
endfu

fu! s:is_cmdline_mapping(char) abort
  " NOTE mapcheck is not working
  let ma = maparg(a:char, 'c', 0,1)
  return !empty(ma)
endfu

fu! s:init_mappings() abort
  let mapargs =  {}
  let s:mapargs = []
  " TODO add support for g:esearch.default_mappings
  for map in keys(s:cmdline_mappings.dict())
    let mapargs[map] = maparg(map, 'c', 0, 1)
    exe 'cmap ' . map . ' ' . s:cmdline_mappings[map]
    let  s:mapargs += [maparg(map)]
  endfor

  return mapargs
endfu

fu! s:recover_mappings(mapargs) abort
  for map in keys(a:mapargs)
    let maparg = a:mapargs[map]
    if empty(maparg)
      exe 'cunmap '.map
    else
      let cmd  = 'silent ' . maparg.mode . (maparg.noremap ? 'nore': '')
      let cmd .= 'map ' . maparg.lhs . maparg.rhs
      exe cmd
    endif
  endfor
endfu

fu! esearch#cmdline#map(lhs, rhs) abort
  let s:cmdline_mappings[a:lhs] = '<Plug>(esearch-'.a:rhs.')'
endfu

let s:Context = esearch#ui#context()
let s:Router = esearch#ui#router#import()

fu! s:app(esearch, route) abort
  let initial_state = a:esearch
  let initial_state.route = a:route
  let initial_state.did_initial = 0
  let initial_state.str = initial_state.regex ? initial_state.exp.pcre : initial_state.exp.literal
  let initial_state.cmdpos = strchars(initial_state.str) + 1
  let store = esearch#ui#create_store(function('<SID>reducer'), initial_state)

  let context = s:Context.new().provide({'store': store})
  try
    while s:Router.new({}).render()
    endwhile
  finally
    call context.restore()
  endtry

  return store.state
endfu

fu! s:reducer(state, action) abort
  if a:action.type ==# 'next_case'
    return extend(copy(a:state), {'case': s:cycle_mode(a:state, 'case')})
  elseif a:action.type ==# 'next_regex'
    return extend(copy(a:state), {'regex': s:cycle_mode(a:state, 'regex')})
  elseif a:action.type ==# 'next_word'
    return extend(copy(a:state), {'word': s:cycle_mode(a:state, 'word')})
  elseif a:action.type ==# 'cmdpos'
    return extend(copy(a:state), {'cmdpos': a:action.cmdpos})
  elseif a:action.type ==# 'paths'
    return extend(copy(a:state), {'paths': a:action.paths, 'metadata': a:action.metadata})
  elseif a:action.type ==# 'did_initial'
    return extend(copy(a:state), {'did_initial': 1})
  elseif a:action.type ==# 'str'
    return extend(copy(a:state), {'str': a:action.str})
  elseif a:action.type ==# 'route'
    return extend(copy(a:state), {'route': a:action.route})
  else
    throw 'Unknown action ' . string(a:action)
  endif
endfu

fu! s:cycle_mode(state, mode_name) abort
  let kinds = keys(a:state.current_adapter.spec[a:mode_name])
  let i = index(kinds, a:state[a:mode_name])

  if i >= len(kinds) - 1
    let i = 0
  else
    let i += 1
  endif

  return kinds[i]
endfu
