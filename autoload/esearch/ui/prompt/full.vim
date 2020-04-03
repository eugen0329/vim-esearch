let s:Full = esearch#ui#component()

fu! s:Full.render() abort dict
  let icon = self.props.current_adapter.spec.full[self.props.full].icon
  return [['NONE', empty(icon) ? '>' : icon]]
endfu

let s:map_state_to_props = esearch#util#slice_factory(['full', 'current_adapter'])

fu! esearch#ui#prompt#full#import() abort
  return esearch#ui#connect(s:Full, s:map_state_to_props)
endfu
