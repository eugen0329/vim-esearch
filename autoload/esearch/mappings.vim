let s:String  = vital#esearch#import('Data.String')
let s:Mapping = vital#esearch#import('Mapping')

" taken from eskk.vim and arpeggio.vim
fu! esearch#mappings#key2char(key) abort
  if stridx(a:key, '<') ==# -1    " optimization
    return a:key
  endif
  return join(
        \   map(
        \       s:split_to_keys(a:key),
        \       'v:val =~# "^<.*>$" ? eval(''"\'' . v:val . ''"'') : v:val'
        \   ),
        \   ''
        \)
endfu

fu! s:split_to_keys(lhs) abort "{{{2
  " Assumption: Special keys such as <C-u> are escaped with < and >, i.e.,
  "             a:lhs doesn't directly contain any escape sequences.
  return split(a:lhs, '\(<[^<>]\+>\|.\)\zs')
endfu

fu esearch#mappings#restorable(mode, pairs, ...) abort
  return s:Guard.store(a:mode, a:pairs, get(a:000, 0, {}))
endfu

let s:Guard = {}

fu! s:Guard.store(mode, pairs, dict) abort dict
  let instance = copy(self)
  let instance.mode = a:mode
  let instance.dict = a:dict
  let instance.pairs = copy(a:pairs)

  let [is_abbr, is_dict] = [0, 1]
  let instance.mapargs = map(keys(a:pairs), 'maparg(v:val, a:mode, is_abbr, is_dict)')

  for [lhs, rhs] in items(a:pairs)
    call s:Mapping.execute_map_command(a:mode, a:dict, lhs, rhs)
  endfor

  return instance
endfu

" VITAL + eskk
fu! s:Guard.restore() abort dict
  for lhs in keys(self.pairs)
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
