let s:String             = vital#esearch#import('Data.String')
let s:List               = vital#esearch#import('Data.List')
let s:IncrementableEntry = esearch#ui#component()

fu! s:IncrementableEntry.render() abort dict
  let hint = s:String.pad_right(self.props['-'] . self.props['+'], 7, ' ')
  let hint .= self.props.name
  let result = [['NONE', hint]]
  if self.props.value ==# 0
    let result += [['Comment', ' (none)']]
  else
    let result += [['Comment', ' (' . self.props.option . ' ' . self.props.value  . ')']]
  endif

  return result
endfu

fu! s:IncrementableEntry.keypress(event) abort dict
  let stop_propagation = 0

  if self.props['-'] ==# a:event.key || a:event.target == self && a:event.key ==# '-'
    call self.props.dispatch({'type': 'DECREMENT', 'name': self.props.name})
    let stop_propagation = 1
  elseif self.props['+'] ==# a:event.key || a:event.target == self && a:event.key ==# '+'
    call self.props.dispatch({'type': 'INCREMENT', 'name': self.props.name})
    let stop_propagation = 1
  endif

  return stop_propagation
endfu

let s:map_state_to_props = esearch#util#slice_factory([])

fu! esearch#ui#menu#incrementable_entry#import() abort
  return esearch#ui#connect(s:IncrementableEntry, s:map_state_to_props)
endfu
