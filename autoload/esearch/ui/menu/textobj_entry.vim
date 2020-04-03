let s:String    = vital#esearch#import('Data.String')
let s:List      = vital#esearch#import('Data.List')
let s:TextobjEntry = esearch#ui#component()

fu! s:TextobjEntry.render() abort dict
  let hint = s:String.pad_right(self.props.keys[0], 7, ' ')
  let hint .= 'textobj textobj match'
  let result = [['NONE', hint]]
  let option = self.props.current_adapter.spec.textobj[self.props.textobj].option
  let option = join(filter([self.props.textobj, option], '!empty(v:val)'), ': ')
  let result += [['Comment', ' (' . option  . ')']]

  return result
endfu

fu! s:TextobjEntry.keypress(event) abort dict
  if s:List.has(self.props.keys, a:event.key) || a:event.key ==# "\<Enter>"
    call self.props.dispatch({'type': 'NEXT_TEXTOBJ'})
    let stop_propagation = 1
    return stop_propagation
  endif
endfu

let s:map_state_to_props = esearch#util#slice_factory(['textobj', 'current_adapter'])

fu! esearch#ui#menu#textobj_entry#import() abort
  return esearch#ui#connect(s:TextobjEntry, s:map_state_to_props)
endfu
