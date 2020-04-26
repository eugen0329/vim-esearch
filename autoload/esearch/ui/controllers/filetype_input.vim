let s:Message             = esearch#message#import()
let s:FiletypeInputController = esearch#ui#component()

fu! s:FiletypeInputController.render() abort dict
  let s:current_adapter = self.props.current_adapter
  redraw!
  let filetypes = input('[filetypes] > ',
        \ self.props.filetypes,
        \ 'customlist,esearch#ui#controllers#filetype_input#complete')

  call self.props.dispatch({'type': 'SET_FILETYPES', 'filetypes': filetypes})
  call self.props.dispatch({'type': 'SET_LOCATION', 'location': 'menu'})
endfu

fu! esearch#ui#controllers#filetype_input#complete(arglead, cmdline, curpos) abort
  return esearch#ui#complete#filetypes#do(s:current_adapter.filetypes, a:arglead, a:cmdline, a:curpos)
endfu

let s:map_state_to_props = esearch#util#slice_factory(['filetypes', 'current_adapter'])

fu! esearch#ui#controllers#filetype_input#import() abort
  return esearch#ui#connect(s:FiletypeInputController, s:map_state_to_props)
endfu
