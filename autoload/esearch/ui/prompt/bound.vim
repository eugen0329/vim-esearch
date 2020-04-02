let s:Bound = esearch#ui#component()

fu! s:Bound.render() abort dict
  let icon = self.props.current_adapter.spec.bound[self.props.bound].icon
  return [['NONE', empty(icon) ? '>' : icon]]
endfu

let s:map_state_to_props = esearch#util#slice_factory(['bound', 'current_adapter'])

fu! esearch#ui#prompt#bound#import() abort
  return esearch#ui#connect(s:Bound, s:map_state_to_props)
endfu
