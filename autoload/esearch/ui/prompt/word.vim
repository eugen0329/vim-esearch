let s:Word = esearch#ui#component()

fu! s:Word.render() abort dict
  let icon = self.props.current_adapter.spec.word[self.props.word].icon
  return [['NONE', empty(icon) ? '>' : icon]]
endfu

let s:map_state_to_props = esearch#util#slice_factory(['word', 'current_adapter'])

fu! esearch#ui#prompt#word#import() abort
  return esearch#ui#connect(s:Word, s:map_state_to_props)
endfu
