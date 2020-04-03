let s:String    = vital#esearch#import('Data.String')
let s:List      = vital#esearch#import('Data.List')
let s:FullEntry = esearch#ui#component()

fu! s:FullEntry.render() abort dict
  let hint = s:String.pad_right(self.props.keys[0], 7, ' ')
  let hint .= 'full textobj match'
  let result = [['NONE', hint]]
  let option = self.props.current_adapter.spec.full[self.props.full].option
  let option = join(filter([self.props.full, option], '!empty(v:val)'), ': ')
  let result += [['Comment', ' (' . option  . ')']]

  return result
endfu

fu! s:FullEntry.keypress(event) abort dict
  if s:List.has(self.props.keys, a:event.key) || a:event.key ==# "\<Enter>"
    call self.props.dispatch({'type': 'NEXT_FULL'})
  endif
endfu

let s:map_state_to_props = esearch#util#slice_factory(['full', 'current_adapter'])

fu! esearch#ui#menu#full_entry#import() abort
  return esearch#ui#connect(s:FullEntry, s:map_state_to_props)
endfu
