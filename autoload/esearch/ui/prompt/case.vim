let s:Case = esearch#ui#component()

fu! s:Case.render() abort dict
  let icon = self.props.current_adapter.case[self.props.case].icon
  return [['NONE', empty(icon) ? '>' : icon]]
endfu

let s:map_state_to_props = esearch#util#slice_factory(['case', 'current_adapter'])

fu! esearch#ui#prompt#case#import() abort
  return esearch#ui#connect(s:Case, s:map_state_to_props)
endfu
