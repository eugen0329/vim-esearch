let s:SearchPrompt    = esearch#ui#prompt#search#import()

let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
      \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()

let s:SelectionController = esearch#ui#component()

fu! s:SelectionController.render() abort dict
  let str =  self.props.pattern.peek().str

  call esearch#ui#render(s:SearchPrompt.new())
  call esearch#ui#render([['Visual', substitute(str, "\n", '\\n', 'g')]])

  let retype = ''
  let finish = s:false
  let char = esearch#util#getchar()

  if index(g:esearch#cmdline#insert_register_content_chars, char) >= 0
    let retype = char
    let char = esearch#util#getchar()
    let retype .= char

    " From :h c_CTRL-R
    if char =~# '^[0-9a-z"%#:\-=.]$'
      let str = ''
    endif
  elseif index(g:esearch#cmdline#clear_selection_chars, char) >= 0
    let str = ''
    let retype = char
  elseif index(g:esearch#cmdline#start_search_chars, char) >= 0
    let finish = s:true
  elseif index(g:esearch#cmdline#cancel_selection_and_retype_chars, char) >= 0
    let retype = char
  elseif index(g:esearch#cmdline#cancel_selection_chars, char) >= 0
    " no-op
  elseif !empty(esearch#keymap#escape_kind(char))
    let retype = char
  elseif mapcheck(char, 'c') !=# ''
    let retype = char
  else
    let str = char
  endif
  redraw!

  return [str, finish, retype]
endfu

let s:map_state_to_props = esearch#util#slice_factory(['pattern'])

fu! esearch#ui#controllers#selection#import() abort
  return esearch#ui#connect(s:SelectionController, s:map_state_to_props)
endfu
