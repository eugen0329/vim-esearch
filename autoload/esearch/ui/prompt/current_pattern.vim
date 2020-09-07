let s:CurrentPattern = esearch#ui#component()

fu! s:CurrentPattern.render() abort dict
  if empty(self.props._adapter.patterns) | return [] | endif

  let opt = self.props.pattern.curr().opt
  return [['NONE', empty(opt) ? '>' : opt]]
endfu

let s:map_state_to_props = esearch#util#slice_factory(['pattern', '_adapter'])

fu! esearch#ui#prompt#current_pattern#import() abort
  return esearch#ui#connect(s:CurrentPattern, s:map_state_to_props)
endfu
