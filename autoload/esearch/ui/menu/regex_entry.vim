let s:String     = vital#esearch#import('Data.String')
let s:List       = vital#esearch#import('Data.List')
let s:RegexEntry = esearch#ui#component()

fu! s:RegexEntry.render() abort dict
  let hint = s:String.pad_right(self.props.keys[0], 8, ' ')
  let hint .= 'toggle regex regex match'
  let result = [['NONE', hint]]
  let option = self.props.current_adapter.spec.regex[self.props.regex].option
  if !empty(option)
    let result += [['Comment', ' (' . option  . ')']]
  endif

  return result
endfu

fu! s:RegexEntry.keypress(event) abort dict
  if s:List.has(self.props.keys, a:event.key) || a:event.key ==# "\<Enter>"
    call self.props.dispatch({'type': 'next_regex'})
  endif
endfu

let s:map_state_to_props = esearch#util#slice_factory(['regex', 'current_adapter'])

fu! esearch#ui#menu#regex_entry#import() abort
  return esearch#ui#connect(s:RegexEntry, s:map_state_to_props)
endfu
