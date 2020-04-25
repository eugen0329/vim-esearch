let s:UnsignedIntEntry  = esearch#ui#menu#unsigned_int_entry#import()
let s:ContextEntry  = esearch#ui#component()

fu! s:ContextEntry.new(props) abort dict
  let instance = extend(copy(self), {'props': a:props})
  let instance.entry = s:UnsignedIntEntry.new()
  let instance.entry.props['+'] = 'c'
  let instance.entry.props['-'] = 'C'
  let instance.entry.props.option = '-C'
  let instance.entry.props.name = 'context'
  let instance.entry.props.hint = 'lines around'
  let instance.entry.props.value = a:props.context
  let instance.entry.props.i = a:props.i
  if g:esearch#has#unicode
    let updown = g:esearch#unicode#updown
  else
    let updown = '^'
  endif
  let instance.entry.props.icon = '['.updown.']'

  return instance
endfu

fu! s:ContextEntry.render() abort dict
  return self.entry.render()
endfu

fu! s:ContextEntry.keypress(event) abort dict
  return self.entry.keypress(a:event)
endfu

let s:map_state_to_props = esearch#util#slice_factory(['context'])

fu! esearch#ui#menu#context_entry#import() abort
  return esearch#ui#connect(s:ContextEntry, s:map_state_to_props)
endfu
