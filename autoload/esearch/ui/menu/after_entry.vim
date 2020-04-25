let s:UnsignedIntEntry  = esearch#ui#menu#unsigned_int_entry#import()
let s:AfterEntry  = esearch#ui#component()

fu! s:AfterEntry.new(props) abort dict
  let instance = extend(copy(self), {'props': a:props})
  let instance.entry = s:UnsignedIntEntry.new()
  let instance.entry.props['+'] = 'a'
  let instance.entry.props['-'] = 'A'
  let instance.entry.props.option = '-A'
  let instance.entry.props.name = 'after'
  let instance.entry.props.hint = 'lines after'
  let instance.entry.props.value = a:props.after
  let instance.entry.props.i = a:props.i
  if g:esearch#has#unicode
    let down = g:esearch#unicode#down
  else
    let down = '^'
  endif
  let instance.entry.props.icon = '['.down.']'

  return instance
endfu

fu! s:AfterEntry.render() abort dict
  return self.entry.render()
endfu

fu! s:AfterEntry.keypress(event) abort dict
  return self.entry.keypress(a:event)
endfu

let s:map_state_to_props = esearch#util#slice_factory(['after'])

fu! esearch#ui#menu#after_entry#import() abort
  return esearch#ui#connect(s:AfterEntry, s:map_state_to_props)
endfu

