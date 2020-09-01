let s:SelectionController = esearch#ui#controllers#selection#import()
let s:SearchPrompt        = esearch#ui#prompt#search#import()
let s:PathTitlePrompt     = esearch#ui#prompt#path_title#import()

cnoremap <Plug>(esearch-toggle-regex)   <C-r>=<SID>interrupt('<SID>next_mode', 'NEXT_REGEX')<CR><CR>
cnoremap <Plug>(esearch-toggle-case)    <C-r>=<SID>interrupt('<SID>next_mode', 'NEXT_CASE')<CR><CR>
cnoremap <Plug>(esearch-toggle-textobj) <C-r>=<SID>interrupt('<SID>next_mode', 'NEXT_TEXTOBJ')<CR><CR>
cnoremap <Plug>(esearch-open-menu)      <C-r>=<SID>interrupt('<SID>open_menu')<CR><CR>

let s:self = 0
let s:SearchInputController = esearch#ui#component()

fu! s:SearchInputController.render() abort dict
  let s:self = self
  let original_mappings = esearch#keymap#restorable(g:esearch#cmdline#mappings)
  let prompt = s:PathTitlePrompt.new().render()
  if !empty(prompt)
    let options = esearch#let#restorable({
          \ '&statusline': esearch#ui#to_statusline(prompt),
          \ })
    redrawstatus!
  endif

  try
    if self.props.live_update | call self.init_live_update() | endif
    return self.render_initial_selection() && self.render_input()
  finally
    if self.props.live_update | call self.uninit_live_update() | endif
    if exists('options') | call options.restore() | endif
    call original_mappings.restore()
  endtry
endfu

fu! s:SearchInputController.init_live_update() dict abort
  let self.executed_cmdline = ''
  let s:live_update = esearch#async#debounce(function('s:live_update'), self.props.live_update_throttle_wait)
  aug esearch_live_update
    au!
    au CmdlineChanged * call s:live_update.apply() | redraw!
  aug END
  let self.redraw_timer = timer_start(
        \ self.props.win_update_throttle_wait,
        \ function('s:redraw'),
        \ {'repeat': -1})
  call s:live_update.apply(self.props.cmdline)
endfu

fu! s:SearchInputController.final_live_update() dict abort
  " if changes were made before live_update_throttle_wait is exceeded
  if self.executed_cmdline !=# self.cmdline
    call s:live_update(self.cmdline)
  endif
endfu

fu! s:redraw(_) abort
  redraw
endfu

fu! s:SearchInputController.uninit_live_update() dict abort
  au! esearch_live_update *
  call timer_stop(self.redraw_timer)
endfu

fu! s:live_update(...) abort
  let cmdline = a:0 ? a:1 : getcmdline()
  if empty(cmdline) | return | endif
  let s:self.executed_cmdline = cmdline
  call esearch#init(extend(copy(s:self.__context__().store.state), {
        \ 'pattern': cmdline,
        \ 'remember': [],
        \ 'live_exec': 1,
        \ 'title': '[esearch]',
        \ }, 'force'))
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
        return 0
      elseif !empty(retype)
        call feedkeys(retype)
      endif
    endif

    call self.props.dispatch({'type': 'SET_DID_SELECT_PREFILLED'})
  endif

  return 1
endfu

fu! s:SearchInputController.render_input() abort
  " redraw is required here to clear possible output leftovers from multiline calls
  call esearch#ui#soft_clear()

  let self.cmdline .= self.restore_cmdpos_chars()
  let self.pressed_mapped_key = 0
  let self.cmdline = self.input()

  if !empty(self.pressed_mapped_key)
    return call(self.pressed_mapped_key.handler, self.pressed_mapped_key.args)
  endif

  if self.props.live_update | call self.final_live_update() | endif
  call self.props.dispatch({'type': 'SET_CMDLINE', 'cmdline': self.cmdline})
  call self.props.dispatch({'type': 'SET_LOCATION', 'location': 'exit'})
endfu

fu! s:SearchInputController.input() abort dict
  " NOTE that it's impossible to properly retype keys (see SelectionController
  " for details) when inputsave() and inputrestore() are used.
  return input(esearch#ui#to_string(s:SearchPrompt.new()),
        \ self.cmdline, 'customlist,esearch#ui#complete#search#do')
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

let s:map_state_to_props = esearch#util#slice_factory(['cmdline', 'cmdpos',
      \ 'did_select_prefilled', 'select_prefilled', 'win_update_throttle_wait',
      \ 'live_update_throttle_wait', 'live_update'])

fu! esearch#ui#controllers#search_input#import() abort
  return esearch#ui#connect(s:SearchInputController, s:map_state_to_props)
endfu
