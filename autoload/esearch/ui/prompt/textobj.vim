let s:Textobj = esearch#ui#component()

fu! s:Textobj.render() abort dict
  let icon = self.props.current_adapter.textobj[self.props.textobj].icon
  return [['NONE', empty(icon) ? '>' : icon]]
endfu

let s:map_state_to_props = esearch#util#slice_factory(['textobj', 'current_adapter'])

fu! esearch#ui#prompt#textobj#import() abort
  return esearch#ui#connect(s:Textobj, s:map_state_to_props)
endfu
