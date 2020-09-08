let s:Case           = esearch#ui#prompt#case#import()
let s:Regex          = esearch#ui#prompt#regex#import()
let s:Textobj        = esearch#ui#prompt#textobj#import()
let s:CurrentPattern = esearch#ui#prompt#current_pattern#import()

let s:SearchPrompt = esearch#ui#component()

fu! s:SearchPrompt.new(props) abort dict
  let instance = extend(copy(self), {'props': a:props})
  let instance.items = [
        \ s:CurrentPattern.new({'key': 'p'}),
        \ s:Case.new({'key': 's'}),
        \ s:Regex.new({'key': 'r'}),
        \ s:Textobj.new({'key': 'w'}),
        \ ]
  let instance.height = len(instance.items)

  return instance
endfu

fu! s:SearchPrompt.render() abort dict
  let result = [['NONE', self.props.adapter.' ']]
  for item in self.items
    let result += item.render()
  endfor
  let result += [['NONE', ' ']]

  return result
endfu

let s:map_state_to_props = esearch#util#slice_factory(['adapter'])

fu! esearch#ui#prompt#search#import() abort
  return esearch#ui#connect(s:SearchPrompt, s:map_state_to_props)
endfu
