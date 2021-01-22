let s:String     = vital#esearch#import('Data.String')
let s:List       = vital#esearch#import('Data.List')
let s:RegexEntry = esearch#ui#component()

fu! s:RegexEntry.render() abort dict
  let icon = self.props.regex is# 'literal' ? ['Comment', '\.\*'] : ['String', '/.*/']

  let result = [['None', s:String.pad_right(self.props.keys[0], 7, ' ')], icon, ['NONE', ' regex match']]
  let option = self.props._adapter.regex[self.props.regex].option
  let option = join(filter([self.props.regex, option], '!empty(v:val)'), ': ')
  let result += [['Comment', ' (' . option  . ')']]

  return result
endfu

fu! s:RegexEntry.keypress(event) abort dict
  if s:List.has(self.props.keys, a:event.key) || a:event.key ==# "\<enter>"
    call self.props.dispatch({'type': 'NEXT_REGEX'})
    let stop_propagation = 1
    return stop_propagation
  endif
endfu

let s:map_state_to_props = esearch#util#slice_factory(['regex', '_adapter'])

fu! esearch#ui#menu#regex_entry#import() abort
  return esearch#ui#connect(s:RegexEntry, s:map_state_to_props)
endfu
