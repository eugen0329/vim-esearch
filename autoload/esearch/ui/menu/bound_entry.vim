let s:String    = vital#esearch#import('Data.String')
let s:List      = vital#esearch#import('Data.List')
let s:BoundEntry = esearch#ui#component()

fu! s:BoundEntry.render() abort dict
  let hint = s:String.pad_right(self.props.keys[0], 8, ' ')
  let hint .= 'toggle match bounds'
  let result = [['NONE', hint]]
  let option = self.props.current_adapter.spec.bound[self.props.bound].option
  let option = join(filter([self.props.bound, option], '!empty(v:val)'), ': ')
  let result += [['Comment', ' (' . option  . ')']]

  return result
endfu

fu! s:BoundEntry.keypress(event) abort dict
  if s:List.has(self.props.keys, a:event.key) || a:event.key ==# "\<Enter>"
    call self.props.dispatch({'type': 'next_bound'})
  endif
endfu

let s:map_state_to_props = esearch#util#slice_factory(['bound', 'current_adapter'])

fu! esearch#ui#menu#bound_entry#import() abort
  return esearch#ui#connect(s:BoundEntry, s:map_state_to_props)
endfu
