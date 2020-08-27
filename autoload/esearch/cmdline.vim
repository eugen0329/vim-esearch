let s:Context = esearch#ui#context()
let s:App  = esearch#ui#app#import()

let g:esearch#cmdline#mappings = [
      \ ['c', '<C-o>',      '<Plug>(esearch-open-menu)'],
      \ ['c', '<C-r><C-r>', '<Plug>(esearch-toggle-regex)'],
      \ ['c', '<C-s><C-s>', '<Plug>(esearch-toggle-case)'],
      \ ['c', '<C-t><C-t>', '<Plug>(esearch-toggle-textobj)'],
      \]

if !exists('g:esearch#cmdline#dir_icon')
  if g:esearch#has#unicode
    let g:esearch#cmdline#dir_icon = g:esearch#unicode#dir_icon
  else
    let g:esearch#cmdline#dir_icon = 'D '
  endif
endif

if !exists('g:esearch#cmdline#clear_selection_chars')
  let g:esearch#cmdline#clear_selection_chars = []
endif
let g:esearch#cmdline#clear_selection_chars += [
      \ "\<Del>",
      \ "\<Bs>",
      \ "\<C-w>",
      \ "\<C-h>",
      \ "\<C-u>",
      \ ]
if g:esearch#has#meta_key
  let g:esearch#cmdline#clear_selection_chars += [
        \ "\<M-d>",
        \ "\<M-BS>",
        \ "\<M-C-h>",
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
if !exists('g:esearch#cmdline#insert_register_content_chars')
  let g:esearch#cmdline#insert_register_content_chars = [
        \ "\<C-r>",
        \ ]
endif

fu! esearch#cmdline#read(esearch) abort
  return s:app(a:esearch)
endfu

fu! esearch#cmdline#map(lhs, rhs) abort
  " TODO deprecate
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
  let initial_state.did_select_prefilled = 0
  let initial_state.cursor = 0
  let initial_state.cmdpos = strchars(initial_state.cmdline) + 1
  return initial_state
endfu

fu! s:reducer(state, action) abort
  if a:action.type ==# 'NEXT_CASE'
    return extend(copy(a:state), {'case': s:cycle_mode(a:state, 'case')})
  elseif a:action.type ==# 'NEXT_REGEX'
    return extend(copy(a:state), {'regex': s:cycle_mode(a:state, 'regex')})
  elseif a:action.type ==# 'NEXT_TEXTOBJ'
    return extend(copy(a:state), {'textobj': s:cycle_mode(a:state, 'textobj')})
  elseif a:action.type ==# 'SET_CURSOR'
    return extend(copy(a:state), {'cursor': a:action.cursor})
  elseif a:action.type ==# 'SET_VALUE'
    let settable = {}
    let settable[a:action.name] = a:action.value
    return extend(copy(a:state), settable)
  elseif a:action.type ==# 'SET_CMDPOS'
    return extend(copy(a:state), {'cmdpos': a:action.cmdpos})
  elseif a:action.type ==# 'SET_PATHS'
    return extend(copy(a:state), {'paths': a:action.paths})
  elseif a:action.type ==# 'SET_FILETYPES'
    return extend(copy(a:state), {'filetypes': a:action.filetypes})
  elseif a:action.type ==# 'SET_DID_SELECT_PREFILLED'
    return extend(copy(a:state), {'did_select_prefilled': 1})
  elseif a:action.type ==# 'SET_CMDLINE'
    return extend(copy(a:state), {'cmdline': a:action.cmdline})
  elseif a:action.type ==# 'SET_LOCATION'
    return extend(copy(a:state), {'location': a:action.location})
  else
    throw 'Unknown action ' . string(a:action)
  endif
endfu

fu! s:cycle_mode(state, mode_name) abort
  let kinds = keys(a:state.current_adapter[a:mode_name])
  let i = index(kinds, a:state[a:mode_name])

  if i >= len(kinds) - 1
    let i = 0
  else
    let i += 1
  endif

  return kinds[i]
endfu
