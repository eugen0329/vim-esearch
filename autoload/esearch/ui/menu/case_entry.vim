let s:String    = vital#esearch#import('Data.String')
let s:List      = vital#esearch#import('Data.List')
let s:CaseEntry = esearch#ui#component()

fu! s:CaseEntry.render() abort dict
  let hint = s:String.pad_right(self.props.keys[0], 8, ' ')
  let hint .= 'toggle case match'
  let result = [['NONE', hint]]
  let option = self.props.current_adapter.spec.case[self.props.case].option
  if !empty(option)
    let result += [['Comment', ' (' . option  . ')']]
  endif

  return result
endfu

fu! s:CaseEntry.keypress(event) abort dict
  if s:List.has(self.props.keys, a:event.key) || a:event.key ==# "\<Enter>"
    call self.props.dispatch({'type': 'next_case'})
  endif
endfu

let s:map_state_to_props = esearch#util#slice_factory(['case', 'current_adapter'])

fu! esearch#ui#menu#case_entry#import() abort
  return esearch#ui#connect(s:CaseEntry, s:map_state_to_props)
endfu
