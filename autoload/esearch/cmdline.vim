let s:Context = esearch#ui#context()
let s:App  = esearch#ui#app#import()

let g:esearch#cmdline#mappings = {
      \ '<C-o>':      '<Plug>(esearch-open-menu)',
      \ '<C-r><C-r>': '<Plug>(esearch-toggle-regex)',
      \ '<C-s><C-s>': '<Plug>(esearch-toggle-case)',
      \ '<C-b><C-b>': '<Plug>(esearch-toggle-word)',
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
  let esearch = s:app(a:esearch)

  if empty(esearch.cmdline)
    let esearch.exp = {}
    return esearch
  endif

  if esearch.is_regex()
    let esearch.exp.literal = esearch.cmdline
    let esearch.exp.pcre = esearch.cmdline
    let esearch.exp.vim = esearch#regex#pcre2vim(esearch.cmdline)
  else
    let esearch.exp.literal = esearch.cmdline
    let esearch.exp.pcre = esearch.cmdline
    let esearch.exp.vim = '\M'.escape(esearch.cmdline, '\$^')
  endif

  return esearch
endfu

fu! esearch#cmdline#map(lhs, rhs) abort
  let g:esearch#cmdline#mappings[a:lhs] = '<Plug>(esearch-'.a:rhs.')'
endfu

fu! s:app(esearch) abort
  let initial_state = s:initial_state(a:esearch)
  let store = esearch#ui#create_store(function('<SID>reducer'), initial_state)
  let context = s:Context.new().provide({'store': store})
  let app = s:App.new(store)

  try
    while app.render()
    endwhile
  finally
    call app.component_will_unmount()
    call context.restore()
  endtry

  return store.state
endfu

fu! s:initial_state(esearch) abort
  let initial_state = a:esearch
  let initial_state.location = 'search_input'
  let initial_state.did_initial = 0
  let initial_state.cursor = 0
  let initial_state.cmdline = initial_state.pattern()
  let initial_state.cmdpos = strchars(initial_state.cmdline) + 1
  return initial_state
endfu

fu! s:reducer(state, action) abort
  if a:action.type ==# 'NEXT_CASE'
    return extend(copy(a:state), {'case': s:cycle_mode(a:state, 'case')})
  elseif a:action.type ==# 'NEXT_REGEX'
    return extend(copy(a:state), {'regex': s:cycle_mode(a:state, 'regex')})
  elseif a:action.type ==# 'NEXT_BOUND'
    return extend(copy(a:state), {'bound': s:cycle_mode(a:state, 'bound')})
  elseif a:action.type ==# 'SET_CURSOR'
    return extend(copy(a:state), {'cursor': a:action.cursor})
  elseif a:action.type ==# 'INCREMENT'
    let incrementable = {}
    let incrementable[a:action.name] = a:state[a:action.name] + 1
    return extend(copy(a:state), incrementable)
  elseif a:action.type ==# 'DECREMENT'
    let decrementable = {}
    let decrementable[a:action.name] = max([0, a:state[a:action.name] - 1])
    return extend(copy(a:state), decrementable)
  elseif a:action.type ==# 'SET_CMDPOS'
    return extend(copy(a:state), {'cmdpos': a:action.cmdpos})
  elseif a:action.type ==# 'SET_PATHS'
    return extend(copy(a:state), {'paths': a:action.paths, 'metadata': a:action.metadata})
  elseif a:action.type ==# 'SET_DID_INITIAL'
    return extend(copy(a:state), {'did_initial': 1})
  elseif a:action.type ==# 'SET_CMDLINE'
    return extend(copy(a:state), {'cmdline': a:action.cmdline})
  elseif a:action.type ==# 'SET_LOCATION'
    return extend(copy(a:state), {'location': a:action.location})
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
