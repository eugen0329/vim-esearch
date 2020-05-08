let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
      \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()

let s:String  = vital#esearch#import('Data.String')
let s:Mapping = vital#esearch#import('Mapping')

" nvim_set_keymap
fu! esearch#keymap#set(mode, lhs, rhs, opts) abort
  let maparg = extend({
        \ 'lhs': a:lhs,
        \ 'rhs': a:rhs,
        \}, a:opts)

  for mode in split(a:mode, '\zs')
    let maparg.mode = mode
    exe esearch#keymap#maparg2set_command(maparg)
  endfor
endfu

fu! esearch#keymap#del(mode, lhs, opts) abort
  return s:Mapping.get_unmap_command(a:mode, a:opts, a:lhs)
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
    call esearch#keymap#del(map[0], map[1], get(map, 3, {}))
  endfor

  for maparg in self.original_mapargs
    if !empty(maparg) | exe esearch#keymap#maparg2set_command(maparg) | endif
  endfor
endfu

fu! esearch#keymap#maparg2set_command(maparg) abort
  let cmd = get(a:maparg, 'noremap') ? 'noremap' : 'map'
  let cmd = a:maparg.mode ==# '!' ? cmd . '!' : a:maparg.mode . cmd

  let lhs = substitute(a:maparg.lhs, '\V|', '<Bar>', 'g')
  let rhs = substitute(a:maparg.rhs, '\V|', '<Bar>', 'g')

  return join([cmd, s:Mapping.options_dict2raw(a:maparg), lhs, rhs])
endfu

" DEPRECATED
fu! esearch#keymap#add(mappings, lhs, rhs) abort
  for mapping in a:mappings
    if mapping.rhs == a:rhs && mapping.default == 1
      call remove(a:mappings, index(a:mappings, mapping))
      break
    endif
  endfor

  call add(a:mappings, {'lhs': a:lhs, 'rhs': a:rhs, 'default': 0})
endfu

" from arpeggio.vim
fu! esearch#keymap#key2char(key) abort
  let keys = s:split_to_keys(a:key)
  call map(keys, 'v:val =~# "^<.*>$" ? eval(''"\'' . v:val . ''"'') : v:val')
  return join(keys, '')
endfu

" from arpeggio.vim
fu! s:split_to_keys(lhs) abort
  " Assumption: Special keys such as <C-u> are escaped with < and >, i.e.,
  "             a:lhs doesn't directly contain any escape sequences.
  return split(a:lhs, '\(<[^<>]\+>\|.\)\zs')
endfu

fu! esearch#keymap#escape_kind(char) abort
  call s:generate_escape_tables()

  let printable = strtrans(a:char)

   if printable =~# s:meta_prefix_re || s:is_keys_combination(s:metas, printable)
     return 'meta'
   elseif s:is_keys_combination(s:shifts, printable)
     return 'shift'
   elseif a:char =~# '^[[:cntrl:]]' || s:is_keys_combination(s:controls, printable)
     return 'control'
   elseif s:is_keys_combination(s:fs, printable)
      return 'f'
   endif

  return ''
endfu

fu! s:is_keys_combination(group, c) abort
  return index(a:group, a:c[:-2]) >= 0 || index(a:group, a:c) >= 0
endfu

fu! s:generate_escape_tables() abort
  if exists('s:escape_tables_loaded') | return | endif

  let s:super_prefix = strtrans("\<D-a>")[:-2]
  let s:meta_prefix = strtrans("\<M-a>")[:-2]
  let s:ameta_prefix = strtrans("\<A-a>")[:-2]

  let s:metas = [s:meta_prefix, s:ameta_prefix, s:super_prefix]
  let s:shifts = []
  let s:controls = []

   let chars = [
         \ 'Nul',
         \ 'BS',
         \ 'Tab',
         \ 'NL',
         \ 'FF',
         \ 'CR',
         \ 'Return',
         \ 'Enter',
         \ 'Esc',
         \ 'Space',
         \ 'lt',
         \ 'Bslash',
         \ 'Bar',
         \ 'Del',
         \ 'CSI',
         \ 'xCSI',
         \ 'Up',
         \ 'Down',
         \ 'Left',
         \ 'Right',
         \ 'Help',
         \ 'Undo',
         \ 'Insert',
         \ 'Home',
         \ 'End',
         \ 'PageUp',
         \ 'PageDown',
         \ 'kUp',
         \ 'kDown',
         \ 'kLeft',
         \ 'kRight',
         \ 'kHome',
         \ 'kEnd',
         \ 'kOrigin',
         \ 'kPageUp',
         \ 'kPageDown',
         \ 'kDel',
         \ 'kPlus',
         \ 'kMinus',
         \ 'kMultiply',
         \ 'kDivide',
         \ 'kPoint',
         \ 'kComma',
         \ 'kEqual',
         \ 'kEnter',
         \ ]

   for c in chars
     call add(s:metas, strtrans(eval('"\<M-'.c.'>"')))
     call add(s:metas, strtrans(eval('"\<A-'.c.'>"')))
     call add(s:metas, strtrans(eval('"\<D-'.c.'>"')))
     call add(s:shifts, strtrans(eval('"\<S-'.c.'>"')))
     call add(s:controls, strtrans(eval('"\<C-'.c.'>"')))
   endfor

   for i in range(0,9)
     call add(s:metas, strtrans(eval('"\<M-k'.i.'>"')))
     call add(s:metas, strtrans(eval('"\<A-k'.i.'>"')))
     call add(s:metas, strtrans(eval('"\<D-k'.i.'>"')))
     call add(s:shifts, strtrans(eval('"\<S-k'.i.'>"')))
     call add(s:controls, strtrans(eval('"\<C-k'.i.'>"')))
   endfor

   let s:fs = []
   for i in range(1,12)
     call add(s:fs, strtrans(eval('"\<F'.i.'>"')))
     call add(s:metas, strtrans(eval('"\<M-F'.i.'>"')))
     call add(s:metas, strtrans(eval('"\<A-F'.i.'>"')))
     call add(s:metas, strtrans(eval('"\<D-F'.i.'>"')))
     call add(s:shifts, strtrans(eval('"\<S-F'.i.'>"')))
     call add(s:controls, strtrans(eval('"\<C-F'.i.'>"')))
   endfor
   let s:meta_prefix_re = '^\%('
         \ . s:meta_prefix . '\|'
         \ . s:super_prefix . '\|'
         \ . s:ameta_prefix . '\)'

   let s:escape_tables_loaded = 1
endfu
