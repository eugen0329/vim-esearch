let s:PathEntry    = esearch#ui#menu#path_entry#import()
let s:CaseEntry    = esearch#ui#menu#case_entry#import()
let s:RegexEntry   = esearch#ui#menu#regex_entry#import()
let s:WordEntry    = esearch#ui#menu#word_entry#import()
let s:SearchPrompt = esearch#ui#prompt#search#import()

let s:Menu = esearch#ui#component()

fu! s:Menu.new(props) abort dict
  let instance = extend(copy(self), {'props': a:props})
  let instance.items = [
        \   s:CaseEntry.new({'keys':  ['s', "\<C-s>"]}),
        \   s:RegexEntry.new({'keys': ['r', "\<C-r>"]}),
        \   s:WordEntry.new({'keys':  ['b', "\<C-b>"]}),
        \   s:PathEntry.new({'keys':  ['p', "\<C-p>"]}),
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
  let result += [['NONE', self.props.str]]

  return result
endfu

fu! s:Menu.keypress(event) abort dict
  if a:event.key ==# "\<Enter>"
    return self.items[self.props.cursor].keypress(a:event)
  end

  let is_handled = 0
  for item in self.items
    let is_handled = (item.keypress(a:event) ? 1 : is_handled)
  endfor

  return is_handled
endfu

let s:map_state_to_props = esearch#util#slice_factory(['str'])

fu! esearch#ui#menu#menu#import() abort
  return esearch#ui#connect(s:Menu, s:map_state_to_props)
endfu
