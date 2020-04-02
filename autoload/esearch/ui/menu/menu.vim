let s:List         = vital#esearch#import('Data.List')
let s:PathEntry    = esearch#ui#menu#path_entry#import()
let s:CaseEntry    = esearch#ui#menu#case_entry#import()
let s:RegexEntry   = esearch#ui#menu#regex_entry#import()
let s:BoundEntry   = esearch#ui#menu#bound_entry#import()
let s:SearchPrompt = esearch#ui#prompt#search#import()

let s:Menu = esearch#ui#component()

let s:case_keys  = ['s', "\<C-s>"]
let s:regex_keys = ['r', "\<C-r>"]
let s:bound_keys = ['b', "\<C-b>"]
let s:path_keys  = ['p', "\<C-p>"]
let s:keys = s:case_keys + s:regex_keys + s:bound_keys + s:path_keys + ["\<Enter>"]

fu! s:Menu.new(props) abort dict
  let instance = extend(copy(self), {'props': a:props})
  let instance.items = [
        \   s:CaseEntry.new({'keys':  s:case_keys}),
        \   s:RegexEntry.new({'keys': s:regex_keys}),
        \   s:BoundEntry.new({'keys':  s:bound_keys}),
        \   s:PathEntry.new({'keys':  s:path_keys}),
        \ ]
  let instance.height = len(instance.items)
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
  let is_handled = 0
  let key = a:event.key

  if !s:List.has(s:keys, key)
    " TODO show an error
    return is_handled
  endif

  if key ==# "\<Enter>"
    return self.items[self.props.cursor].keypress(a:event)
  end

  for item in self.items
    let is_handled = (item.keypress(a:event) ? 1 : is_handled)
  endfor

  return is_handled
endfu

let s:map_state_to_props = esearch#util#slice_factory(['cmdline'])

fu! esearch#ui#menu#menu#import() abort
  return esearch#ui#connect(s:Menu, s:map_state_to_props)
endfu
