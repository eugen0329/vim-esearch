let s:String    = vital#esearch#import('Data.String')
let s:List      = vital#esearch#import('Data.List')
let s:WordEntry = esearch#ui#component()

fu! s:WordEntry.render() abort dict
  let hint = s:String.pad_right(self.props.keys[0], 8, ' ')
  let hint .= 'toggle word regex match'
  let result = [['NONE', hint]]
  let option = self.props.current_adapter.spec.word[self.props.word].option
  if !empty(option)
    let result += [['Comment', ' (' . option  . ')']]
  endif

  return result
endfu

fu! s:WordEntry.keypress(event) abort dict
  if s:List.has(self.props.keys, a:event.key) || a:event.key ==# "\<Enter>"
    call self.props.dispatch({'type': 'next_word'})
  endif
endfu

let s:map_state_to_props = esearch#util#slice_factory(['word', 'current_adapter'])

fu! esearch#ui#menu#word_entry#import() abort
  return esearch#ui#connect(s:WordEntry, s:map_state_to_props)
endfu
