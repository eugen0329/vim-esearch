let s:Case = esearch#ui#component()

fu! s:Case.render() abort dict
  if empty(self.props._adapter.case) | return [] | endif

  let icon = self.props._adapter.case[self.props.case].icon
  return [['NONE', empty(icon) ? '>' : icon]]
endfu

let s:map_state_to_props = esearch#util#slice_factory(['case', '_adapter'])

fu! esearch#ui#prompt#case#import() abort
  return esearch#ui#connect(s:Case, s:map_state_to_props)
endfu
