let s:List             = vital#esearch#import('Data.List')
let s:PathEntry        = esearch#ui#menu#path_entry#import()
let s:CaseEntry        = esearch#ui#menu#case_entry#import()
let s:RegexEntry       = esearch#ui#menu#regex_entry#import()
let s:TextobjEntry     = esearch#ui#menu#textobj_entry#import()
let s:UnsignedIntEntry = esearch#ui#menu#unsigned_int_entry#import()
let s:SearchPrompt     = esearch#ui#prompt#search#import()
let s:ContextEntry     = esearch#ui#menu#context_entry#import()
let s:BeforeEntry      = esearch#ui#menu#before_entry#import()
let s:AfterEntry       = esearch#ui#menu#after_entry#import()
let s:FiletypeEntry    = esearch#ui#menu#filetype_entry#import()

let s:Menu = esearch#ui#component()

" TODO sharing
let s:case_keys          = ['s', "\<C-s>"]
let s:regex_keys         = ['r', "\<C-r>"]
let s:textobj_keys       = ['t', "\<C-t>"]
let s:path_keys          = ['p', "\<C-p>"]
let s:filetype_keys      = ['f', "\<C-f>"]
let s:after_keys         = ['a', 'A']
let s:before_keys        = ['b', 'B']
let s:context_keys       = ['c', 'C']
let s:unsigned_int_keys = ["\<C-a>", "\<C-x>", "\<Enter>", "\<Left>", "\<Right>", "\<C-h>"]

let s:keys = s:case_keys + s:regex_keys + s:textobj_keys + s:path_keys + s:filetype_keys
      \ + s:after_keys + s:before_keys + s:context_keys + ["\<Enter>", "\<Del>", "\<BS>", '+', '-'] + s:unsigned_int_keys
      \ + map(range(0, 9), 'string(v:val)')

fu! s:Menu.new(props) abort dict
  let instance = extend(copy(self), {'props': a:props})

  let i = esearch#itertools#count()
  let instance.items = [
        \   s:CaseEntry.new({'i':     i.next(), 'keys':  s:case_keys}),
        \   s:RegexEntry.new({'i':    i.next(), 'keys': s:regex_keys}),
        \   s:TextobjEntry.new({'i':  i.next(), 'keys':  s:textobj_keys}),
        \ ]
  if !empty(a:props.current_adapter.filetypes)
    let instance.items += [
          \   s:FiletypeEntry.new({'i': i.next(), 'keys': s:filetype_keys}),
          \ ]
  endif
  let instance.items += [
        \   s:PathEntry.new({'i':     i.next(), 'keys': s:path_keys}),
        \   s:BeforeEntry.new({'i':   i.next()}),
        \   s:AfterEntry.new({'i':    i.next()}),
        \   s:ContextEntry.new({'i':  i.next()}),
        \ ]

  let instance.prompt = s:SearchPrompt.new()
  let text_height = esearch#ui#height(instance.prompt.render() + [['', a:props.cmdline]])
  let instance.height = len(instance.items) + text_height

  return instance
endfu

fu! s:Menu.render() abort dict
  let result = []
  for i in range(0, len(self.items)-1)
    let result += (self.props.cursor ==# i ? [['Function', '> ']] : [['NONE', '  ']])
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

let s:map_state_to_props = esearch#util#slice_factory(['cmdline', 'after', 'before', 'context', 'current_adapter'])

fu! esearch#ui#menu#menu#import() abort
  return esearch#ui#connect(s:Menu, s:map_state_to_props)
endfu
