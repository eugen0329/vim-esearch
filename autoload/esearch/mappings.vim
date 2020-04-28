let s:String  = vital#esearch#import('Data.String')
let s:Mapping = vital#esearch#import('Mapping')

" taken from arpeggio.vim
fu! esearch#mappings#key2char(key) abort
  let keys = s:split_to_keys(a:key)
  call map(keys, 'v:val =~# "^<.*>$" ? eval(''"\'' . v:val . ''"'') : v:val')
  return join(keys, '')
endfu

fu! s:split_to_keys(lhs) abort
  " Assumption: Special keys such as <C-u> are escaped with < and >, i.e.,
  "             a:lhs doesn't directly contain any escape sequences.
  return split(a:lhs, '\(<[^<>]\+>\|.\)\zs')
endfu

fu! esearch#mappings#restorable(mode, maps, ...) abort
  return s:Guard.store(a:mode, a:maps, get(a:000, 0, {}))
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

" VITAL + eskk
fu! s:Guard.restore() abort dict
  for lhs in keys(self.maps)
    call s:Mapping.execute_unmap_command(self.mode, self.dict, lhs)
  endfor

  for maparg in self.mapargs
    if empty(maparg) | continue | endif

    let cmd = get(maparg, 'noremap') ? 'noremap' : 'map'
    let cmd = maparg.mode ==# '!' ? cmd . '!' : maparg.mode . cmd

    let modifiers =
          \  (get(maparg, 'expr')   ? '<expr>'   : '')
          \. (get(maparg, 'buffer') ? '<buffer>' : '')
          \. (get(maparg, 'silent') ? '<silent>' : '')
          \. (get(maparg, 'script') ? '<script>' : '')
          \. (get(maparg, 'unique') ? '<unique>' : '')
          \. (get(maparg, 'nowait') ? '<nowait>' : '')

    exe cmd modifiers  maparg.lhs  maparg.rhs
  endfor
endfu

" TODO deprecate
fu! esearch#mappings#add(mappings, lhs, rhs) abort
  for mapping in a:mappings
    if mapping.rhs == a:rhs && mapping.default == 1
      call remove(a:mappings, index(a:mappings, mapping))
      break
    endif
  endfor

  call add(a:mappings, {'lhs': a:lhs, 'rhs': a:rhs, 'default': 0})
endfu
