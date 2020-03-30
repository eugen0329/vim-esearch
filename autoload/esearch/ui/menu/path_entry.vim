let s:String    = vital#esearch#import('Data.String')
let s:List      = vital#esearch#import('Data.List')
let s:PathEntry = esearch#ui#component()

fu! s:PathEntry.render() abort dict
  let text = s:String.pad_right(self.props.keys[0], 8, ' ') . 'edit paths '
  let current_value = s:String
        \.truncate_skipping(self.props.paths, &columns / 2, 3, '...')

  return [['NONE', text]] + [['Comment', current_value]]
endfu

fu! s:PathEntry.keypress(event) abort dict
  if s:List.has(self.props.keys, a:event.key) || a:event.key ==# "\<Enter>"
    call self.props.dispatch({'type': 'route', 'route': 'path_input'})
    return 1
  end
endfu

fu! s:map_state_to_props(state) abort dict
  return {'paths': join(get(a:state, 'paths'), ' ')}
endfu

fu! esearch#ui#menu#path_entry#import() abort
  return esearch#ui#connect(s:PathEntry, function('<SID>map_state_to_props'))
endfu
