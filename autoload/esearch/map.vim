let s:String  = vital#esearch#import('Data.String')
let s:Mapping = vital#esearch#import('Mapping')

fu! esearch#map#restorable(mode, maps, ...) abort
  return s:Guard.store(a:mode, a:maps, get(a:, 1, {}))
endfu

let s:Guard = {}

fu! s:Guard.store(mode, maps, dict) abort dict
  let instance = copy(self)
  let instance.mode = a:mode
  let instance.dict = a:dict
  let instance.maps = copy(a:maps)

  let [is_abbr, is_dict] = [0, 1]
  let instance.mapargs = map(keys(a:maps), 'maparg(v:val, a:mode, is_abbr, is_dict)')

  for [lhs, rhs] in items(a:maps)
    call s:Mapping.execute_map_command(a:mode, a:dict, lhs, rhs)
  endfor

  return instance
endfu

fu! s:mapargs(map, modes, is_abbr, is_dict)
  return map(split(a:modes, '\zs'), 'maparg(a:map, v:val, a:is_abbr, a:is_dict)')
endfu

fu! esearch#map#set(maparg, defaults) abort
  let maparg = extend(copy(a:defaults), a:maparg)

  for mode in split(maparg.mode, '\zs')
    let maparg.mode = mode
    exec s:maparg2command(maparg)
  endfor
endfu

fu! s:Guard.restore() abort dict
  for lhs in keys(self.maps)
    call s:Mapping.execute_unmap_command(self.mode, self.dict, lhs)
  endfor

  for maparg in self.mapargs
    if !empty(maparg) | exe s:maparg2command(maparg) | endif
  endfor
endfu

fu! s:maparg2command(maparg) abort
  let cmd = get(a:maparg, 'noremap') ? 'noremap' : 'map'
  let cmd = a:maparg.mode ==# '!' ? cmd . '!' : a:maparg.mode . cmd

  let lhs = substitute(a:maparg.lhs, '\V|', '<Bar>', 'g')
  let rhs = substitute(a:maparg.rhs, '\V|', '<Bar>', 'g')

  exe cmd s:Mapping.options_dict2raw(a:maparg) lhs rhs
endfu

" TODO deprecate
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
