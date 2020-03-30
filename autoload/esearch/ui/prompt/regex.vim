let s:Regex = esearch#ui#component()

fu! s:Regex.render() abort dict
  return [['NONE', self.props.regex ? 'r' : '>']]
endfu

let s:map_state_to_props = esearch#util#slice_factory(['regex'])

fu! esearch#ui#prompt#regex#import() abort
  return esearch#ui#connect(s:Regex, s:map_state_to_props)
endfu
