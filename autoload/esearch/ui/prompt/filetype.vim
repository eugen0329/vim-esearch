let s:Dict  = vital#esearch#import('Data.Dict')
let s:FiletypePrompt = esearch#ui#component()

fu! s:FiletypePrompt.render() abort dict
  if empty(self.props.filetypes) || empty(self.props._adapter.filetypes)
    return []
  endif

  let result = []
  let available_filetypes = s:Dict.make_index(self.props._adapter.filetypes)
  for filetype in split(self.props.filetypes)
    let highlight = get(available_filetypes, filetype) ? 'Typedef' : self.props.normal_hl
    let result += [[highlight, '<.'.filetype.'>']] + [[self.props.normal_hl, ' ']]
  endfor

  return result
endfu

let s:FiletypePrompt.default_props = {'normal_hl': 'NONE'}
let s:map_state_to_props = esearch#util#slice_factory(['_adapter', 'filetypes'])

fu! esearch#ui#prompt#filetype#import() abort
  return esearch#ui#connect(s:FiletypePrompt, s:map_state_to_props)
endfu
