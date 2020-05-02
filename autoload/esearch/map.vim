let s:String  = vital#esearch#import('Data.String')
let s:Mapping = vital#esearch#import('Mapping')

fu! esearch#map#set(maparg, defaults) abort
  let maparg = extend(copy(a:defaults), a:maparg)

  for mode in split(maparg.mode, '\zs')
    let maparg.mode = mode
    exe esearch#map#maparg2map(maparg)
  endfor
endfu

fu! esearch#map#restorable(maps, defaults) abort
  return s:Guard.store(a:maps, a:defaults)
endfu

let s:Guard = {}

fu! s:Guard.store(mapargs, defaults) abort dict
  let instance = copy(self)
  let instance.mapargs = map(copy(a:mapargs), 'extend(copy(a:defaults), v:val)')
  let [is_abbr, is_dict] = [0, 1]
  let instance.original_mapargs = map(copy(instance.mapargs),
        \ 'maparg(v:val.lhs, v:val.mode, is_abbr, is_dict)')

  for maparg in a:mapargs
    call esearch#map#set(maparg, a:defaults)
  endfor

  return instance
endfu

fu! s:Guard.restore() abort dict
  for maparg in self.mapargs
    exe esearch#map#maparg2unmap(maparg)
  endfor

  for maparg in self.original_mapargs
    if !empty(maparg) | exe esearch#map#maparg2map(maparg) | endif
  endfor
endfu

fu! esearch#map#maparg2map(maparg) abort
  let cmd = get(a:maparg, 'noremap') ? 'noremap' : 'map'
  let cmd = a:maparg.mode ==# '!' ? cmd . '!' : a:maparg.mode . cmd

  let lhs = substitute(a:maparg.lhs, '\V|', '<Bar>', 'g')
  let rhs = substitute(a:maparg.rhs, '\V|', '<Bar>', 'g')

  return join([cmd, s:Mapping.options_dict2raw(a:maparg), lhs, rhs])
endfu

fu! esearch#map#maparg2unmap(maparg) abort
  return s:Mapping.get_unmap_command(a:maparg.mode, a:maparg, a:maparg.lhs)
endfu

" DEPRECATED
fu! esearch#map#add(mappings, lhs, rhs) abort
  for mapping in a:mappings
    if mapping.rhs == a:rhs && mapping.default == 1
      call remove(a:mappings, index(a:mappings, mapping))
      break
    endif
  endfor

  call add(a:mappings, {'lhs': a:lhs, 'rhs': a:rhs, 'default': 0})
endfu

" from arpeggio.vim
fu! esearch#map#key2char(key) abort
  let keys = s:split_to_keys(a:key)
  call map(keys, 'v:val =~# "^<.*>$" ? eval(''"\'' . v:val . ''"'') : v:val')
  return join(keys, '')
endfu
fu! s:split_to_keys(lhs) abort
  " Assumption: Special keys such as <C-u> are escaped with < and >, i.e.,
  "             a:lhs doesn't directly contain any escape sequences.
  return split(a:lhs, '\(<[^<>]\+>\|.\)\zs')
endfu
