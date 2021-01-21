let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
      \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()

let s:String  = vital#esearch#import('Data.String')
let s:Mapping = vital#esearch#import('Mapping')

" nvim_set_keymap
fu! esearch#keymap#set(mode, lhs, rhs, opts) abort
  let maparg = extend({'lhs': a:lhs, 'rhs': a:rhs}, a:opts)

  for mode in split(a:mode, '\zs')
    let maparg.mode = mode
    exe esearch#keymap#maparg2set_command(maparg)
  endfor
endfu

fu! esearch#keymap#del(mode, lhs, opts) abort
  for mode in split(a:mode, '\zs')
    exe s:Mapping.get_unmap_command(mode, a:opts, a:lhs)
  endfor
endfu

fu! esearch#keymap#restorable(maps) abort
  return s:Guard.store(a:maps)
endfu

let s:Guard = {}

fu! s:Guard.store(maps) abort dict
  let instance = copy(self)
  let instance.maps = a:maps
  let [is_abbr, is_dict] = [0, 1]
  let instance.original_mapargs = map(copy(instance.maps),
        \ 'maparg(v:val[1], v:val[0], is_abbr, is_dict)')

  for map in a:maps
    call esearch#keymap#set(map[0], map[1], map[2], get(map, 3, {}))
  endfor

  return instance
endfu

fu! s:Guard.restore() abort dict
  for map in self.maps
    silent! call esearch#keymap#del(map[0], map[1], get(map, 3, {}))
  endfor

  for maparg in self.original_mapargs
    if !empty(maparg) | exe esearch#keymap#maparg2set_command(maparg) | endif
  endfor
endfu

fu! esearch#keymap#maparg2set_command(maparg) abort
  let maparg = a:maparg
  let cmd = get(maparg, 'noremap') ? 'noremap' : 'map'
  let cmd = maparg.mode ==# '!' ? cmd . '!' : maparg.mode . cmd

  let lhs = substitute(maparg.lhs, '\V|', '<Bar>', 'g')
  let rhs = substitute(maparg.rhs, '\V|', '<Bar>', 'g')
  if stridx(rhs, '<SID>') >= 0
    let rhs = substitute(rhs, '<SID>', '<SNR>'.maparg.sid.'_', 'g')
    let maparg.script = 1
  endif

  return join([cmd, s:Mapping.options_dict2raw(maparg), lhs, rhs])
endfu

" from arpeggio.vim
fu! esearch#keymap#key2char(key) abort
  let keys = s:split_to_keys(a:key)
  call map(keys, 'v:val =~# "^<.*>$" ? eval(''"\'' . v:val . ''"'') : v:val')
  return join(keys, '')
endfu

" from arpeggio.vim
fu! s:split_to_keys(lhs) abort
  " Assumption: Special keys such as <c-u> are escaped with < and >, i.e.,
  "             a:lhs doesn't directly contain any escape sequences.
  return split(a:lhs, '\(<[^<>]\+>\|.\)\zs')
endfu

fu! esearch#keymap#escape_kind(char) abort
  call s:generate_escape_tables()

  let char = strtrans(a:char)
  if (!empty(s:meta_prefix_re) && char =~# s:meta_prefix_re) || s:is_keys_combination(s:meta_keys, char)
    return 'meta'
  elseif s:is_keys_combination(s:shift_keys, char)
    return 'shift'
  elseif a:char =~# '^[[:cntrl:]]' || s:is_keys_combination(s:control_keys, char)
    return 'control'
  elseif s:is_keys_combination(s:function_keys, char)
    return 'f'
  endif

  return ''
endfu

fu! s:is_keys_combination(group, char) abort
  return index(a:group, a:char[:-2]) >= 0 || index(a:group, a:char) >= 0
endfu

fu! s:generate_escape_tables() abort
  if exists('s:loaded_escape_tables') | return | endif

  let super_prefix = strtrans("\<d-a>")[:-2]
  let meta_prefix = strtrans("\<m-a>")[:-2]
  let ameta_prefix = strtrans("\<a-a>")[:-2]
  let s:meta_keys = filter([meta_prefix, ameta_prefix, super_prefix], '!empty(v:val)')
  if empty(s:meta_keys)
    let s:meta_prefix_re = ''
  else
    let s:meta_prefix_re = '^\%(' . join(s:meta_keys, '\|') . '\)'
  endif
  let s:shift_keys = []
  let s:control_keys = []

   let keycode_names = [
         \ 'Nul', 'BS', 'Tab', 'NL', 'FF', 'CR', 'Return', 'Enter', 'Esc',
         \ 'Space', 'lt', 'Bslash', 'Bar', 'Del', 'CSI', 'xCSI', 'Up', 'Down',
         \ 'Left', 'Right', 'Help', 'Undo', 'Insert', 'Home', 'End', 'PageUp',
         \ 'PageDown', 'kUp', 'kDown', 'kLeft', 'kRight', 'kHome', 'kEnd',
         \ 'kOrigin', 'kPageUp', 'kPageDown', 'kDel', 'kPlus', 'kMinus',
         \ 'kMultiply', 'kDivide', 'kPoint', 'kComma', 'kEqual', 'kEnter']

   for c in keycode_names
     call add(s:meta_keys, strtrans(eval('"\<m-'.c.'>"')))
     call add(s:meta_keys, strtrans(eval('"\<a-'.c.'>"')))
     call add(s:meta_keys, strtrans(eval('"\<d-'.c.'>"')))
     call add(s:shift_keys, strtrans(eval('"\<s-'.c.'>"')))
     call add(s:control_keys, strtrans(eval('"\<c-'.c.'>"')))
   endfor

   for i in range(0,9)
     call add(s:meta_keys, strtrans(eval('"\<m-k'.i.'>"')))
     call add(s:meta_keys, strtrans(eval('"\<a-k'.i.'>"')))
     call add(s:meta_keys, strtrans(eval('"\<d-k'.i.'>"')))
     call add(s:shift_keys, strtrans(eval('"\<s-k'.i.'>"')))
     call add(s:control_keys, strtrans(eval('"\<c-k'.i.'>"')))
   endfor

   let s:function_keys = []
   for i in range(1,12)
     call add(s:function_keys, strtrans(eval('"\<F'.i.'>"')))
     call add(s:meta_keys, strtrans(eval('"\<m-F'.i.'>"')))
     call add(s:meta_keys, strtrans(eval('"\<a-F'.i.'>"')))
     call add(s:meta_keys, strtrans(eval('"\<d-F'.i.'>"')))
     call add(s:shift_keys, strtrans(eval('"\<s-F'.i.'>"')))
     call add(s:control_keys, strtrans(eval('"\<c-F'.i.'>"')))
   endfor

   let s:loaded_escape_tables = 1
endfu
