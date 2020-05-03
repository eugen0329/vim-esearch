let s:SelectionController = esearch#ui#controllers#selection#import()
let s:SearchPrompt        = esearch#ui#prompt#search#import()
let s:PathTitlePrompt     = esearch#ui#prompt#path_title#import()

let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
      \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()

cnoremap <Plug>(esearch-toggle-regex)   <C-r>=<SID>interrupt('<SID>next_mode', 'NEXT_REGEX')<CR><CR>
cnoremap <Plug>(esearch-toggle-case)    <C-r>=<SID>interrupt('<SID>next_mode', 'NEXT_CASE')<CR><CR>
cnoremap <Plug>(esearch-toggle-textobj) <C-r>=<SID>interrupt('<SID>next_mode', 'NEXT_TEXTOBJ')<CR><CR>
cnoremap <Plug>(esearch-open-menu)      <C-r>=<SID>interrupt('<SID>open_menu')<CR><CR>

let s:self = s:null
let s:SearchInputController = esearch#ui#component()

fu! s:SearchInputController.render() abort dict
  let s:self = self
  let original_mappings = esearch#map#restorable(g:esearch#cmdline#mappings, {'mode': 'c'})

  try
    return self.render_initial_selection() && self.render_input()
  finally
    call original_mappings.restore()
  endtry
endfu

fu! s:SearchInputController.render_initial_selection() abort dict
  if self.props.did_select_prefilled
    let self.cmdline = self.props.cmdline
  elseif !self.props.select_prefilled
    let self.cmdline = self.props.cmdline
    call self.props.dispatch({'type': 'SET_DID_SELECT_PREFILLED'})
  else
    if empty(self.props.cmdline)
      let self.cmdline = ''
    else
      let [self.cmdline, finish, retype] = s:SelectionController.new().render()
      if finish
        call self.props.dispatch({'type': 'SET_CMDLINE', 'cmdline': self.cmdline})
        call self.props.dispatch({'type': 'SET_LOCATION', 'location': 'exit'})
        return s:false
      elseif !empty(retype)
        call feedkeys(retype)
      endif
    endif

    call self.props.dispatch({'type': 'SET_DID_SELECT_PREFILLED'})
  endif

  return s:true
endfu

fu! s:SearchInputController.render_input() abort
  " redraw is required here to clear possible output leftovers from multiline
  " calls
  redraw
  call esearch#ui#render(s:PathTitlePrompt.new())

  let self.cmdline .= self.restore_cmdpos_chars()
  let self.pressed_mapped_key = s:null
  let self.cmdline = self.input()

  if !empty(self.pressed_mapped_key)
    call call(self.pressed_mapped_key.handler, self.pressed_mapped_key.args)
    return
  endif

  call self.props.dispatch({'type': 'SET_CMDLINE', 'cmdline': self.cmdline})
  call self.props.dispatch({'type': 'SET_LOCATION', 'location': 'exit'})
endfu

fu! s:SearchInputController.input() abort dict
  " NOTE that it's impossible to properly retype keys (see SelectionController
  " for details) when inputsave() and inputrestore() are used.
  return input(esearch#ui#to_string(s:SearchPrompt.new())
        \ , self.cmdline, 'customlist,esearch#ui#complete#search#do')
endfu

fu! s:SearchInputController.restore_cmdpos_chars() abort
  return repeat("\<Left>", strchars(self.cmdline) + 1 - self.props.cmdpos)
endfu

fu! s:interrupt(func, ...) abort
  let s:self.pressed_mapped_key = {'handler': function(a:func), 'args': a:000}
  call s:self.props.dispatch({'type': 'SET_CMDPOS', 'cmdpos': getcmdpos()})
  return ''
endfu

fu! s:open_menu(...) abort dict
  call s:self.props.dispatch({'type': 'SET_CMDLINE', 'cmdline': s:self.cmdline})
  call s:self.props.dispatch({'type': 'SET_LOCATION', 'location': 'menu'})
endfu

fu! s:next_mode(event_type) abort dict
  call s:self.props.dispatch({'type': 'SET_CMDLINE', 'cmdline': s:self.cmdline})
  call s:self.props.dispatch({'type': a:event_type})
endfu

let s:map_state_to_props = esearch#util#slice_factory(['cmdline', 'cmdpos', 'did_select_prefilled', 'select_prefilled'])

fu! esearch#ui#controllers#search_input#import() abort
  return esearch#ui#connect(s:SearchInputController, s:map_state_to_props)
endfu
