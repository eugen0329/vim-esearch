let s:String    = vital#esearch#import('Data.String')
let s:List      = vital#esearch#import('Data.List')
let s:CaseEntry = esearch#ui#component()

fu! s:CaseEntry.render() abort dict
  let icon = self.props.case ==# 'ignore' ? ['Comment', '(?i)'] :
        \ self.props.case ==# 'sensitive' ? ['Constant', '[Cs]'] :  ['String', '[Sc]']

  let result = [['None', s:String.pad_right(self.props.keys[0], 7, ' ')], icon, ['NONE', ' case match']]
  let option = self.props._adapter.case[self.props.case].option
  let option = join(filter([self.props.case, option], '!empty(v:val)'), ': ')
  let result += [['Comment', ' (' . option  . ')']]

  return result
endfu

fu! s:CaseEntry.keypress(event) abort dict
  if s:List.has(self.props.keys, a:event.key) || a:event.key ==# "\<enter>"
    call self.props.dispatch({'type': 'NEXT_CASE'})
    let stop_propagation = 1
    return stop_propagation
  endif
endfu

let s:map_state_to_props = esearch#util#slice_factory(['case', '_adapter'])

fu! esearch#ui#menu#case_entry#import() abort
  return esearch#ui#connect(s:CaseEntry, s:map_state_to_props)
endfu
