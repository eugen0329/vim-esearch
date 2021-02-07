let s:String     = vital#esearch#import('Data.String')
let s:List       = vital#esearch#import('Data.List')
let s:PathPrompt = esearch#ui#prompt#path#import()
let s:PathEntry  = esearch#ui#component()

fu! s:PathEntry.render() abort dict
  let icon = empty(self.props.paths) ? ['Comment', '[./]'] : ['Directory', '[./]']
  let result = [['None', s:String.pad_right(self.props.keys[0], 7, ' ')], icon, ['NONE', ' search only in paths']]

  if empty(self.props.paths)
    let result += [['Comment', ' (none)']]
  else
    let result += [['Comment', ' (']]
    let result += s:PathPrompt.new({'normal_hl': 'Comment'}).render()
    let result += [['Comment', ')']]
  endif

  return result
endfu

fu! s:PathEntry.keypress(event) abort dict
  if s:List.has(self.props.keys, a:event.key) || a:event.key ==# "\<enter>"
    call self.props.dispatch({'type': 'SET_LOCATION', 'location': 'path_input'})
    let stop_propagation = 1
    return stop_propagation
  end
endfu

fu! s:map_state_to_props(state) abort dict
  return {'paths': get(a:state, 'paths')}
endfu

fu! esearch#ui#menu#path_entry#import() abort
  return esearch#ui#connect(s:PathEntry, function('<SID>map_state_to_props'))
endfu
