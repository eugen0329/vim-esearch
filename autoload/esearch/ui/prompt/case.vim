let s:Case = esearch#ui#component()

fu! s:Case.render() abort dict
  return [['NONE', self.props.case ? 'c' : '>']]
endfu

let s:map_state_to_props = esearch#util#slice_factory(['case'])

fu! esearch#ui#prompt#case#import() abort
  return esearch#ui#connect(s:Case, s:map_state_to_props)
endfu
