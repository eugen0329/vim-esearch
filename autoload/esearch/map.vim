let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
      \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()

let s:String  = vital#esearch#import('Data.String')
let s:Mapping = vital#esearch#import('Mapping')

fu! esearch#map#define(maparg, defaults) abort
  let maparg = extend(copy(a:defaults), a:maparg)

  for mode in split(maparg.mode, '\zs')
    let maparg.mode = mode
    exe esearch#map#maparg2define_command(maparg)
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
    call esearch#map#define(maparg, a:defaults)
  endfor

  return instance
endfu

fu! s:Guard.restore() abort dict
  for maparg in self.mapargs
    exe esearch#map#maparg2undefine_command(maparg)
  endfor

  for maparg in self.original_mapargs
    if !empty(maparg) | exe esearch#map#maparg2define_command(maparg) | endif
  endfor
endfu

fu! esearch#map#maparg2define_command(maparg) abort
  let cmd = get(a:maparg, 'noremap') ? 'noremap' : 'map'
  let cmd = a:maparg.mode ==# '!' ? cmd . '!' : a:maparg.mode . cmd

  let lhs = substitute(a:maparg.lhs, '\V|', '<Bar>', 'g')
  let rhs = substitute(a:maparg.rhs, '\V|', '<Bar>', 'g')

  return join([cmd, s:Mapping.options_dict2raw(a:maparg), lhs, rhs])
endfu

fu! esearch#map#maparg2undefine_command(maparg) abort
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

" from arpeggio.vim
fu! s:split_to_keys(lhs) abort
  " Assumption: Special keys such as <C-u> are escaped with < and >, i.e.,
  "             a:lhs doesn't directly contain any escape sequences.
  return split(a:lhs, '\(<[^<>]\+>\|.\)\zs')
endfu

fu! esearch#map#escape_kind(char) abort
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

  return s:null
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
