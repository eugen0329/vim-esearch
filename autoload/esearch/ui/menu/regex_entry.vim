let s:String     = vital#esearch#import('Data.String')
let s:List       = vital#esearch#import('Data.List')
let s:RegexEntry = esearch#ui#component()

fu! s:RegexEntry.render() abort dict
  let text = s:String.pad_right(self.props.keys[0], 8, ' ')
  let text .= (self.props.regex ? 'enable ' : 'disable') . ' regex match'

  return [['NONE', text]]
endfu

fu! s:RegexEntry.keypress(event) abort dict
  if s:List.has(self.props.keys, a:event.key) || a:event.key ==# "\<Enter>"
    call self.props.dispatch({'type': 'regex'})
  endif
endfu

let s:map_state_to_props = esearch#util#slice_factory(['regex'])

fu! esearch#ui#menu#regex_entry#import() abort
  return esearch#ui#connect(s:RegexEntry, s:map_state_to_props)
endfu
