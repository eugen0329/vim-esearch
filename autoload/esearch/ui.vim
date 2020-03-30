let s:Message = esearch#message#import()

let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
      \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()

fu! esearch#ui#create_store(reducer, initial_state) abort
  let store = {
        \  'reducer': a:reducer,
        \  'state':   a:initial_state,
        \ }
  let store.dispatch = function('<SID>dispatch', [store])
  return store
endfu

fu! s:dispatch(self, action) abort dict
  let a:self.state = a:self.reducer(a:self.state, a:action)
endfu

fu! esearch#ui#component() abort
  return copy(s:Component)
endfu

let s:current_context = {}
let s:Component = {}

fu! s:Component.new(props) abort dict
  return extend(copy(self), {'props': a:props})
endfu

fu! s:Component.context() abort dict
  return s:current_context
endfu

fu! s:Component.keypress(event) abort dict
  return s:null
endfu

fu! esearch#ui#context() abort
  return s:Context
endfu

let s:Context = {}

fu! s:Context.new() abort dict
  return copy(self)
endfu

fu! s:Context.provide(props) abort dict
  let self.original_current_context = s:current_context
  let s:current_context = a:props
  return self
endfu

fu! s:Context.restore() abort dict
  let s:current_context = self.original_current_context
endfu

fu! esearch#ui#render(component) abort
  let list = type(a:component) ==# s:t_list
        \ ? a:component
        \ : a:component.render()

  for [color, text] in list
    call s:Message.echon(color, text)
  endfor
endfu

fu! esearch#ui#to_string(component) abort
  let result = ''
  for [color, text] in a:component.render()
    let result .= text
  endfor

  return result
endfu

fu! esearch#ui#connect(component, ...) abort
  let wrapped = copy(s:Component)
  call extend(wrapped, {
        \ 'component': a:component,
        \ 'map_state_to_props': get(a:000, 0 , {-> {} }),
        \ })

  fu! wrapped.new(props) abort
    let props = self.map_state_to_props(self.context().store.state)
    call extend(props, {'dispatch': self.context().store.dispatch})
    return self.component
          \.new(extend(props, a:props))
  endfu

  fu! wrapped.render() abort
  endfu

  return wrapped
endfu
