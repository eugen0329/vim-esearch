let s:Log             = esearch#log#import()
let s:PathInputController = esearch#ui#component()

fu! s:PathInputController.render() abort dict
  let s:self = self
  let user_input_in_shell_format =  join(map(copy(self.props.paths), 'esearch#shell#escape(v:val)'), ' ')

  redraw!
  while 1
    let user_input_in_shell_format = input('[paths] > ',
          \ user_input_in_shell_format,
          \'customlist,esearch#ui#controllers#path_input#complete')

    let [paths, error] = esearch#shell#split(user_input_in_shell_format)

    if error isnot 0
      call s:Log.echon('ErrorMsg', " can't parse paths: " . error)
      call getchar()
      redraw!
    else
      break
    endif
  endwhile

  call self.props.dispatch({'type': 'SET_PATHS',    'paths': paths})
  call self.props.dispatch({'type': 'SET_LOCATION', 'location': 'menu'})
endfu

fu! esearch#ui#controllers#path_input#complete(arglead, cmdline, curpos) abort
  return esearch#ui#complete#paths#do(s:self.props.cwd, a:arglead, a:cmdline, a:curpos)
endfu

fu! s:map_state_to_props(state) abort dict
  return {
        \ 'paths': get(a:state, 'paths', []),
        \ 'cwd':   a:state.cwd,
        \ }
endfu

fu! esearch#ui#controllers#path_input#import() abort
  return esearch#ui#connect(s:PathInputController, function('<SID>map_state_to_props'))
endfu
