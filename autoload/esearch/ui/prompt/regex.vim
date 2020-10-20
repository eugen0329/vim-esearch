let s:Regex = esearch#ui#component()

fu! s:Regex.render() abort dict
  if empty(self.props._adapter.regex) | return [] | endif

  let icon = self.props._adapter.regex[self.props.regex].icon
  return [['NONE', empty(icon) ? '>' : icon]]
endfu

let s:map_state_to_props = esearch#util#slice_factory(['regex', '_adapter'])

fu! esearch#ui#prompt#regex#import() abort
  return esearch#ui#connect(s:Regex, s:map_state_to_props)
endfu
