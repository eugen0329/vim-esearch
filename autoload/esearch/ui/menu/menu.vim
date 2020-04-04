let s:List             = vital#esearch#import('Data.List')
let s:PathEntry        = esearch#ui#menu#path_entry#import()
let s:CaseEntry        = esearch#ui#menu#case_entry#import()
let s:RegexEntry       = esearch#ui#menu#regex_entry#import()
let s:TextobjEntry     = esearch#ui#menu#textobj_entry#import()
let s:UnsignedIntEntry = esearch#ui#menu#unsigned_int_entry#import()
let s:SearchPrompt     = esearch#ui#prompt#search#import()

let s:Menu = esearch#ui#component()

let s:case_keys          = ['s', "\<C-s>"]
let s:regex_keys         = ['r', "\<C-r>"]
let s:textobj_keys       = ['t', "\<C-t>"]
let s:path_keys          = ['p', "\<C-p>"]
let s:after_keys         = ['a', 'A']
let s:before_keys        = ['b', 'B']
let s:context_keys       = ['c', 'C']
let s:unsigned_int_keys = ["\<C-a>", "\<C-x>"]

let s:keys = s:case_keys + s:regex_keys + s:textobj_keys + s:path_keys
      \ + s:after_keys + s:before_keys + s:context_keys + ["\<Enter>", "\<Del>", "\<BS>", '+', '-'] + s:unsigned_int_keys
      \ + map(range(0, 9), 'string(v:val)')

fu! s:Menu.new(props) abort dict
  let instance = extend(copy(self), {'props': a:props})
  let instance.items = [
        \   s:CaseEntry.new({'i':    0, 'keys':  s:case_keys}),
        \   s:RegexEntry.new({'i':   1, 'keys': s:regex_keys}),
        \   s:TextobjEntry.new({'i': 2, 'keys':  s:textobj_keys}),
        \   s:PathEntry.new({'i':    3, 'keys':  s:path_keys}),
        \   s:UnsignedIntEntry.new({'i': 4, '-': 'A', '+': 'a', 'hint': 'lines after',  'option': '-A', 'name': 'after',   'value': a:props.after}),
        \   s:UnsignedIntEntry.new({'i': 5, '-': 'B', '+': 'b', 'hint': 'lines before', 'option': '-B', 'name': 'before',  'value': a:props.before}),
        \   s:UnsignedIntEntry.new({'i': 6, '-': 'C', '+': 'c', 'hint': 'lines around', 'option': '-C', 'name': 'context', 'value': a:props.context}),
        \ ]
  let instance.height = len(instance.items) + 1 " + height of the search input below
  let instance.prompt = s:SearchPrompt.new()

  return instance
endfu

fu! s:Menu.render() abort dict
  let result = []
  for i in range(0, len(self.items)-1)
    let result += self.props.cursor ==# i ? [['NONE', '> ']] : [['NONE', '  ']]
    let result += self.items[i].render()
    let result += [['NONE', "\n"]]
  endfor
  let result += self.prompt.render()
  let result += [['NONE', self.props.cmdline]]

  return result
endfu

fu! s:Menu.keypress(event) abort dict
  let stop_propagation = 0
  let key = a:event.key

  if !s:List.has(s:keys, key)
    " TODO show an error
    return stop_propagation
  endif

  if key ==# "\<Enter>"
    return self.items[self.props.cursor].keypress(a:event)
  end

  for item in self.items
    let stop_propagation = item.keypress(a:event)

    if stop_propagation
      call self.props.dispatch({'type': 'SET_CURSOR', 'cursor': item.props.i})
      break
    endif
  endfor

  return stop_propagation
endfu

let s:map_state_to_props = esearch#util#slice_factory(['cmdline', 'after', 'before', 'context'])

fu! esearch#ui#menu#menu#import() abort
  return esearch#ui#connect(s:Menu, s:map_state_to_props)
endfu
