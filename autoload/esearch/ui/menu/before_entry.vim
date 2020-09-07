let s:UnsignedIntEntry  = esearch#ui#menu#unsigned_int_entry#import()
let s:BeforeEntry  = esearch#ui#component()

fu! s:BeforeEntry.new(props) abort dict
  let instance = extend(copy(self), {'props': a:props})
  let instance.entry = s:UnsignedIntEntry.new()
  let instance.entry.props['+'] = 'b'
  let instance.entry.props['-'] = 'B'
  let instance.entry.props.name = 'before'
  let instance.entry.props.option = a:props._adapter.before.opt
  let instance.entry.props.hint = a:props._adapter.before.hint
  let instance.entry.props.value = a:props.before
  let instance.entry.props.i = a:props.i
  let up = g:esearch#has#unicode ? g:esearch#unicode#up : 'v'
  let instance.entry.props.icon = '['.up.' ]'

  return instance
endfu

fu! s:BeforeEntry.render() abort dict
  return self.entry.render()
endfu

fu! s:BeforeEntry.keypress(event) abort dict
  return self.entry.keypress(a:event)
endfu

let s:map_state_to_props = esearch#util#slice_factory(['before', '_adapter'])

fu! esearch#ui#menu#before_entry#import() abort
  return esearch#ui#connect(s:BeforeEntry, s:map_state_to_props)
endfu
