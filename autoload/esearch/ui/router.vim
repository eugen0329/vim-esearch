let s:OptionsMenu           = esearch#ui#menu#menu#import()
let s:MenuController        = esearch#ui#controllers#menu#import()
let s:PathInputController   = esearch#ui#controllers#path_input#import()
let s:SearchInputController = esearch#ui#controllers#search_input#import()

let s:Router = esearch#ui#component()

fu! s:Router.render() abort dict
  redraw!

  if self.props.route ==# 'menu'
    call s:MenuController.new({'menu_class': s:OptionsMenu}).render()
  elseif self.props.route ==# 'path_input'
    call s:PathInputController.new().render()
  elseif self.props.route ==# 'search_input'
    call s:SearchInputController.new().render()
  elseif self.props.route ==# 'exit'
    return 0
  else
    throw ''
  endif

  return 1
endfu

let s:map_state_to_props = esearch#util#slice_factory(['route'])

fu! esearch#ui#router#import() abort
  return esearch#ui#connect(s:Router, s:map_state_to_props)
endfu
