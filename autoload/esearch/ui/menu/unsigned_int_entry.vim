let s:String           = vital#esearch#import('Data.String')
let s:List             = vital#esearch#import('Data.List')
let s:UnsignedIntEntry = esearch#ui#component()

fu! s:UnsignedIntEntry.render() abort dict
  let hint = s:String.pad_right(self.props['+'] . '/' . self.props['-'], 7, ' ')
  let hint .= 'more/less ' . self.props.hint
  let result = [['NONE', hint]]
  if self.props.value ==# 0
    let result += [['Comment', ' (none)']]
  else
    let result += [['Comment', ' (' . self.props.option . ' ' . self.props.value  . ')']]
  endif

  return result
endfu

fu! s:UnsignedIntEntry.keypress(event) abort dict
  let stop_propagation = 1

  if self.props['-'] ==# a:event.key
    call self.decrement()
  elseif self.props['+'] ==# a:event.key
    call self.increment()
  elseif a:event.target == self
    if s:List.has(["\<C-x>", '-'], a:event.key)
      call self.decrement()
    elseif s:List.has(["\<C-a>", '+'], a:event.key)
      call self.increment()
    elseif s:List.has(["\<BS>"], a:event.key)
      call self.remove_rightmost_char()
    elseif s:List.has(["\<Del>"], a:event.key)
      call self.props.dispatch({'type': 'SET_VALUE', 'name': self.props.name, 'value': 0})
    elseif a:event.key =~# '^\d$'
      call self.append_char(a:event.key)
    else
      let stop_propagation = 0
    endif
  else
    let stop_propagation = 0
  endif

  return stop_propagation
endfu

fu! s:UnsignedIntEntry.decrement() abort dict
  let value = max([0, self.props.value - 1])
  call self.props.dispatch({'type': 'SET_VALUE', 'name': self.props.name, 'value': value})
endfu

fu! s:UnsignedIntEntry.increment() abort dict
  let value = self.props.value + 1
  call self.props.dispatch({'type': 'SET_VALUE', 'name': self.props.name, 'value': value})
endfu

" Decimal shift right
fu! s:UnsignedIntEntry.remove_rightmost_char() abort dict
  let value = self.props.value / 10
  call self.props.dispatch({'type': 'SET_VALUE', 'name': self.props.name, 'value': value})
endfu

fu! s:UnsignedIntEntry.append_char(char) abort dict
  let value = abs(self.props.value * 10 + str2nr(a:char))
  call self.props.dispatch({'type': 'SET_VALUE', 'name': self.props.name, 'value': value})
endfu

let s:map_state_to_props = esearch#util#slice_factory([])

fu! esearch#ui#menu#unsigned_int_entry#import() abort
  return esearch#ui#connect(s:UnsignedIntEntry, s:map_state_to_props)
endfu
