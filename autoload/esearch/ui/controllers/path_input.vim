let s:Message             = esearch#message#import()
let s:PathInputController = esearch#ui#component()

fu! s:PathInputController.render() abort dict
  let s:self = self
  let user_input_in_shell_format =
        \ esearch#shell#fnamesescape_and_join(self.props.paths, self.props.metadata)

  while 1
    let user_input_in_shell_format = input('[path] > ',
          \ user_input_in_shell_format,
          \'customlist,esearch#ui#controllers#path_input#_complete_files')

    let [paths, metadata, error] = esearch#shell#split(user_input_in_shell_format)

    if error isnot 0
      call s:Message.echon('ErrorMsg', " can't parse paths: " . error, 0)
      call getchar()
      redraw!
    else
      break
    endif
  endwhile

  call self.props.dispatch({'type': 'paths', 'paths': paths, 'metadata': metadata})
  call self.props.dispatch({'type': 'route', 'route': 'menu'})
endfu

fu! s:map_state_to_props(state) abort dict
  return {
        \ 'paths':    get(a:state, 'paths', []),
        \ 'metadata': get(a:state, 'metadata', []),
        \ 'cwd':      a:state.cwd,
        \ }
endfu

fu! esearch#ui#controllers#path_input#_complete_files(A,L,P) abort
  return esearch#completion#complete_files(s:self.props.cwd, a:A, a:L, a:P)
endfu

fu! esearch#ui#controllers#path_input#import() abort
  return esearch#ui#connect(s:PathInputController, function('<SID>map_state_to_props'))
endfu
