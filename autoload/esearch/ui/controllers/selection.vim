let s:SearchPrompt    = esearch#ui#prompt#search#import()
let s:PathTitlePrompt = esearch#ui#prompt#path_title#import()

let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
      \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()

let s:SelectionController = esearch#ui#component()

fu! s:SelectionController.new(props) abort dict
  let instance = extend(copy(self), {'props': a:props})
  return instance
endfu

fu! s:SelectionController.render() abort dict
  let paths = s:PathTitlePrompt.new({}).render()
  if !empty(paths)
    call esearch#ui#render(paths)
    call esearch#ui#render([['NONE', "\n"]])
  endif
  call esearch#ui#render(s:SearchPrompt.new({}))
  call esearch#ui#render([['Visual', substitute(self.props.str, "\n", ' ', 'g')]])

  let retype = s:null
  let str =  self.props.str
  let finish = s:false

  let char = esearch#util#getchar()

  if index(g:esearch#cmdline#clear_selection_chars, char) >= 0
    let str = ''
  elseif index(g:esearch#cmdline#start_search_chars, char) >= 0
    let finish = s:true
  elseif index(g:esearch#cmdline#cancel_selection_and_retype_chars, char) >= 0
    let retype = char
  elseif index(g:esearch#cmdline#cancel_selection_chars, char) >= 0
    " no-op
  elseif esearch#util#escape_kind(char) isnot 0
    let retype = char
  elseif mapcheck(char, 'c') !=# ''
    let retype = char
  else
    let str = char
  endif

  redraw!
  return [str, finish, retype]
endfu

let s:map_state_to_props = esearch#util#slice_factory(['str'])

fu! esearch#ui#controllers#selection#import() abort
  return esearch#ui#connect(s:SelectionController, s:map_state_to_props)
endfu
