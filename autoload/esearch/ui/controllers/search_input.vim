let s:Selection       = esearch#ui#controllers#selection#import()
let s:SearchPrompt    = esearch#ui#prompt#search#import()
let s:PathTitlePrompt = esearch#ui#prompt#path_title#import()

let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
      \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()

cnoremap <Plug>(esearch-toggle-regex)      <C-r>=<SID>interrupt('s:next_mode', 'next_regex')<CR><CR>
cnoremap <Plug>(esearch-toggle-case)       <C-r>=<SID>interrupt('s:next_mode', 'next_case')<CR><CR>
cnoremap <Plug>(esearch-toggle-word)       <C-r>=<SID>interrupt('s:next_mode', 'next_word')<CR><CR>
cnoremap <Plug>(esearch-cmdline-open-menu) <C-r>=<SID>interrupt('s:open_menu')<CR><CR>

let s:self = s:null
let s:SearchInputController = esearch#ui#component()

fu! s:SearchInputController.render() abort dict
  let s:self = self
  return self.render_initial_selection() && self.render_input()
endfu

fu! s:SearchInputController.render_initial_selection() abort dict
  if self.props.did_initial
    let self.str = self.props.str
  else
    if empty(self.props.str)
      let self.str = ''
    else
      let [self.str, finish, retype] = s:Selection.new({}).render()
      if finish
        call self.props.dispatch({'type': 'str', 'str': self.str})
        call self.props.dispatch({'type': 'route', 'route': 'exit'})
        return s:false
      elseif !empty(retype)
        call feedkeys(retype)
      endif
    endif
    call self.props.dispatch({'type': 'did_initial'})
  endif

  return s:true
endfu

fu! s:SearchInputController.render_input() abort
  call esearch#ui#render(s:PathTitlePrompt.new({}))

  let self.str .= self.restore_cmdpos_chars()
  let self.pressed_mapped_key = s:null
  let self.str = self.input()

  if !empty(self.pressed_mapped_key)
    call call(self.pressed_mapped_key.handler, self.pressed_mapped_key.args)
    return
  endif

  call self.props.dispatch({'type': 'str', 'str': self.str})
  call self.props.dispatch({'type': 'route', 'route': 'exit'})
endfu

if has('nvim')
  fu! s:SearchInputController.input() abort dict
    return input({
          \ 'prompt': esearch#ui#to_string(s:SearchPrompt.new({})),
          \ 'default': self.str,
          \ 'completion': 'customlist,esearch#completion#buffer_words',
          \})
  endfu
    " echohl NONE
else
  fu! s:SearchInputController.input() abort dict
    return input(esearch#ui#to_string(s:SearchPrompt.new({}))
          \ , self.str, 'customlist,esearch#completion#buffer_words')
  endfu
endif

fu! s:SearchInputController.restore_cmdpos_chars() abort
  return repeat("\<Left>", strchars(self.str) + 1 - self.props.cmdpos)
endfu

fu! s:interrupt(func, ...) abort
  let s:self.pressed_mapped_key = {'handler': function(a:func), 'args': a:000}
  call s:self.props.dispatch({'type': 'cmdpos', 'cmdpos': getcmdpos()})
  return ''
endfu

fu! s:open_menu(...) abort dict
  call s:self.props.dispatch({'type': 'str', 'str': s:self.str})
  call s:self.props.dispatch({'type': 'route', 'route': 'menu'})
endfu

fu! s:next_mode(type) abort dict
  call s:self.props.dispatch({'type': 'str', 'str': s:self.str})
  call s:self.props.dispatch({'type': a:type})
endfu

let s:map_state_to_props = esearch#util#slice_factory(['str', 'cmdpos', 'did_initial'])

fu! esearch#ui#controllers#search_input#import() abort
  return esearch#ui#connect(s:SearchInputController, s:map_state_to_props)
endfu
