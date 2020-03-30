let s:Word = esearch#ui#component()

fu! s:Word.render() abort dict
  return [['NONE', self.props.word ? 'w' : '>']]
endfu

let s:map_state_to_props = esearch#util#slice_factory(['word'])

fu! esearch#ui#prompt#word#import() abort
  return esearch#ui#connect(s:Word, s:map_state_to_props)
endfu
