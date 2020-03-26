let s:Vital         = vital#esearch#new()
let s:List          = s:Vital.import('Data.List')
let s:Message       = s:Vital.import('Vim.Message')
let s:linenr_format = ' %3d '
let s:textobjects_whitelist = 'w()[]{}<>|''`"'

let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
      \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()

fu! esearch#compat#visual_multi#init() abort
  if exists('g:esearch_visual_multi_loaded') || !exists('g:esearch')
    return
  endif
  let g:esearch_visual_multi_loaded = 1

  au User visual_multi_start     call s:on_start()
  au User visual_multi_after_cmd call s:on_after_cmd()
endfu

fu! s:on_after_cmd() abort
  if !exists('b:esearch')
    return
  endif
  call b:esearch.undotree.synchronize()
endfu

fu! s:on_start() abort
  if exists('b:esearch_visual_multi_loaded') || !exists('b:esearch')
    return
  endif
  let b:esearch_visual_multi_loaded = 1

  augroup ESearchVisualMulti
    au! * <buffer>
    au TextChangedP,TextChangedI <buffer> call s:remove_cursors_overlapping_interface(0)
  augroup END

  " NOTE that all the commented code lines below are left intentionally to
  " keep track on what is in TODO status and what is reviewed and is not
  " required to be wrapped or disabled with s:unsupported() method.

  call s:nremap('<Plug>(VM-D)',                  '<SID>without_regions_overlapping_interface(%s, 0)')
  " <Plug>(VM-Y)
  call s:nremap('<Plug>(VM-x)',                  '<SID>without_regions_overlapping_interface(%s, 0)')
  call s:nremap('<Plug>(VM-X)',                  '<SID>without_regions_overlapping_interface(%s, 1)')
  call s:nremap('<Plug>(VM-J)',                  '<SID>unsupported(%s, "Is not supported")')
  call s:nremap('<Plug>(VM-~)',                  '<SID>without_regions_overlapping_interface(%s, 0)')
  " What is it for?
  " <Plug>(VM-&)
  call s:nremap('<Plug>(VM-Del)',                '<SID>without_regions_overlapping_interface(%s, 1)')
  call s:nremap('<Plug>(VM-Dot)',                '<SID>unsupported(%s, "Is not supported")')
  call s:nremap('<Plug>(VM-Increase)',           '<SID>without_regions_overlapping_interface(%s, 0)')
  call s:nremap('<Plug>(VM-Decrease)',           '<SID>without_regions_overlapping_interface(%s, 0)')
  call s:nremap('<Plug>(VM-Alpha-Increase)',     '<SID>without_regions_overlapping_interface(%s, 0)')
  call s:nremap('<Plug>(VM-Alpha-Decrease)',     '<SID>without_regions_overlapping_interface(%s, 0)')
  call s:nremap('<Plug>(VM-a)',                  '<SID>without_regions_overlapping_interface(%s, -1)')
  " call s:nremap('<Plug>(VM-A)',                  '<SID>unsupported(%s, "Is not supported")')
  call s:nremap('<Plug>(VM-i)',                  '<SID>without_regions_overlapping_interface(%s, 0)')
  call s:nremap('<Plug>(VM-I)',                  '<SID>unsupported(%s, "Is not supported")')
  call s:nremap('<Plug>(VM-o)',                  '<SID>unsupported(%s, "Inserting newlines is not supported")')
  call s:nremap('<Plug>(VM-O)',                  '<SID>unsupported(%s, "Inserting newlines is not supported")')
  call s:nremap('<Plug>(VM-c)',                  '<SID>c_operator(%s, 0, v:count1, v:register)')
  call s:nremap('<Plug>(VM-gc)',                 '<SID>unsupported(%s, "Is not supported")')
  call s:nremap('<Plug>(VM-C)',                  '<SID>unsupported(%s, "Is not supported")')
  call s:nremap('<Plug>(VM-Delete)',             '<SID>d_operator(%s, 0, v:count1, v:register)')
  call s:nremap('<Plug>(VM-Delete-Exit)',        '<SID>d_operator(%s, 0, v:count1, v:register)')
  call s:nremap('<Plug>(VM-Replace-Characters)', '<SID>without_regions_overlapping_interface(%s, -1)')
  call s:nremap('<Plug>(VM-Replace)',            '<SID>unsupported(%s, "Is not supported")')
  " TODO can be implemented
  call s:nremap('<Plug>(VM-Transform-Regions)',  '<SID>unsupported(%s, "Is not supported")')
  call s:nremap('<Plug>(VM-p-Paste-Regions)',    '<SID>unsupported(%s, "Is not supported")')
  call s:nremap('<Plug>(VM-P-Paste-Regions)',    '<SID>unsupported(%s, "Is not supported")')
  call s:nremap('<Plug>(VM-p-Paste-Vimreg)',     '<SID>unsupported(%s, "Is not supported")')
  call s:nremap('<Plug>(VM-P-Paste-Vimreg)',     '<SID>unsupported(%s, "Is not supported")')
  " <Plug>(VM-Yank)

  "" Arrow movements, just skip
  """""""""""""""""""""""""""""
  " <Plug>(VM-I-Arrow-w)
  " <Plug>(VM-I-Arrow-b)
  " <Plug>(VM-I-Arrow-W
  " <Plug>(VM-I-Arrow-B)
  " <Plug>(VM-I-Arrow-e)
  " <Plug>(VM-I-Arrow-ge)
  " <Plug>(VM-I-Arrow-E)
  " <Plug>(VM-I-Arrow-gE)
  " <Plug>(VM-I-Left-Arrow)
  " <Plug>(VM-I-Right-Arrow)
  " <Plug>(VM-I-Up-Arrow)
  " <Plug>(VM-I-Down-Arrow)
  call s:iremap('<Plug>(VM-I-Return)',      '<SID>unsupported(%s, "Inserting newlines is not supported")')
  call s:iremap('<Plug>(VM-I-BS)',          '<SID>i_delete_char(%s, 1)')
  call s:iremap('<Plug>(VM-I-Paste)',       '<SID>unsupported(%s, "Is not supported")')
  call s:iremap('<Plug>(VM-I-CtrlW)',       '<SID>CtrlW(%s)')
  call s:iremap('<Plug>(VM-I-CtrlU)',       '<SID>CtrlW(%s)')
  call s:iremap('<Plug>(VM-I-CtrlD)',       '<SID>i_delete_char(%s, -2)')
  call s:iremap('<Plug>(VM-I-Del)',         '<SID>i_delete_char(%s, -2)')
  "" Movements, just skip
  " <Plug>(VM-I-Arrow-ge)
  " <Plug>(VM-I-Arrow-E)
  " <Plug>(VM-I-Arrow-gE)
  " <Plug>(VM-I-Left-Arrow)
  " <Plug>(VM-I-Right-Arrow)
  " <Plug>(VM-I-Up-Arrow)
  " <Plug>(VM-I-Down-Arrow)
  " <Plug>(VM-I-Next)
  " <Plug>(VM-I-Prev)
  call s:iremap('<Plug>(VM-I-Replace)',     '<SID>unsupported(%s, "Is not supported")')

  "" Cursor managing stuff, should be safe..
  """""""""""""""""""""""""""""""""""""""""""
  " <Plug>(VM-Move-Right)
  " <Plug>(VM-Move-Left)
  " <Plug>(VM-Transpose)
  " <Plug>(VM-Rotate)
  " <Plug>(VM-Duplicate)

  "" Dangerous, but useful. Lets keep unhandled
  """""""""""""""""""""""""""""""""""""""""""""""
  " <Plug>(VM-Align)
  " <Plug>(VM-Align-Char)
  " <Plug>(VM-Align-Regex)
  " <Plug>(VM-Numbers)
  " <Plug>(VM-Numbers-Append)
  " <Plug>(VM-Zero-Numbers)
  " <Plug>(VM-Zero-Numbers-Append)
  " <Plug>(VM-Run-Dot)
  " <Plug>(VM-Surround)
  " <Plug>(VM-Run-Macro)
  " <Plug>(VM-Run-Ex)
  " <Plug>(VM-Run-Last-Ex)
  " <Plug>(VM-Run-Normal)
  " <Plug>(VM-Run-Last-Normal)
  " <Plug>(VM-Run-Visual)
  " <Plug>(VM-Run-Last-Visual)

  ""Cmdline. Seems too useful to disable
  " <expr> <Plug>(VM-:)
  " <expr> <Plug>(VM-/)
  " <expr> <Plug>(VM-?)
endfu

fu! s:nremap(lhs, rhs) abort
  let map = substitute(maparg(a:lhs, 'n'), '<', '<lt>', 'g')
  exe printf('nnoremap <silent><buffer> %s :<C-u>call ' . a:rhs . '<CR>', a:lhs, string(map))
endfu

fu! s:iremap(lhs, rhs) abort
  let map = substitute(maparg(a:lhs, 'i'), '<', '<lt>', 'g')
  exe printf('inoremap <silent><expr><buffer> %s ' . a:rhs, a:lhs, string(map))
endfu

fu! s:unsupported(orig, msg) abort
  call s:Message.echo('ErrorMsg', a:msg)
  return ''
endfu

" Input characters whitelists are used to prevent from running dangerous which
" could corrupt the UI.

fu! s:d_operator(orig, offset_from_linenr, count, register) abort
  let whitelist0 = 'we$' " no extra chars required
  let whitelist1 = 'fs' " f{char} and deleting surround require 1 extra char
  let whitelist2 = ''
  call s:safely_apply_operator(a:orig, a:offset_from_linenr,
        \ a:count, whitelist0, whitelist1, whitelist2)
endfu

fu! s:c_operator(orig, offset_from_linenr, count, register) abort
  let whitelist0 = 'we$' " no extra chars required
  let whitelist1 = 'f' " f{char}
  let whitelist2 = 's' " changing surround using at least 2 chars
  call s:safely_apply_operator(a:orig, a:offset_from_linenr,
        \ a:count, whitelist0, whitelist1, whitelist2)
endfu

fu! s:safely_apply_operator(orig, offset_from_linenr, count, whitelist0, whitelist1, whitelist2) abort
  let regions = s:regions_overlapping_interface(a:offset_from_linenr)
  if len(regions) == len(b:VM_Selection.Regions)
    return
  else
    for r in regions | call r.clear() | endfor
  endif
  if g:Vm.extend_mode
    return feedkeys(esearch#mappings#key2char(a:orig))
  endif

  let [motion, motion_count] = s:sanitized_motion(a:whitelist0, a:whitelist1, a:whitelist2)
  if motion is s:null
    return
  endif

  "" Counts are ignored for now as they can cause multiline changes
  " let multiplied_count = (a:count * motion_count)
  call feedkeys(esearch#mappings#key2char(a:orig) . motion, 't')
endfu

fu! s:sanitized_motion(whitelist0, whitelist1, whitelist2) abort
  let motion = ''
  let motion_count = ''

  while 1
    let char = esearch#util#getchar()
    if char =~# '\d'
      let motion_count .=  char
    else
      let motion = char
      break
    endif
  endwhile
  let motion_count = max([str2nr(motion_count), 1])

  if index(split(a:whitelist0, '\zs'), char) >= 0
    " noop
  elseif index(split(a:whitelist1, '\zs'), char) >= 0
    let motion .= esearch#util#getchar()
  elseif index(split(a:whitelist2, '\zs'), char) >= 0
    let motion .= esearch#util#getchar() . esearch#util#getchar()
  elseif index(split('ia', '\zs'), char) >= 0
    let textobj = esearch#util#getchar()
    if index(split(s:textobjects_whitelist, '\zs'), textobj) < 0
      call s:unsupported(s:null, 'Textobject ' . textobj . ' is not supported')
      return [s:null, s:null]
    endif
    let motion .= textobj
  else
    call s:unsupported(s:null, 'Motion ' . motion . ' is not supported')
    return [s:null, s:null]
  endif

  return [motion, motion_count]
endfu

" According to visual-multi source code, regions are roughly the same as
" cursors, but cursors are used only in INSERT mode
fu! s:remove_cursors_overlapping_interface(offset_from_linenr) abort
  if empty(b:VM_Selection)
    return
  endif

  let state = b:esearch.undotree.head.state
  let contexts = esearch#out#win#repo#ctx#new(b:esearch, state)
  let removable_indexes = []

  let i = 0
  for cursor in b:VM_Selection.Insert.cursors
    let ctx = contexts.by_line(cursor.l)
    if cursor.l == ctx.begin || (cursor.l == ctx.end && cursor.l != line('$'))
      call add(removable_indexes, i)
    else
      let linenr = printf(s:linenr_format, state.line_numbers_map[cursor.l])
      if cursor._a <= strlen(linenr) + a:offset_from_linenr
        call add(removable_indexes, i)
      endif
    endif

    let i += 1
  endfor

  if empty(removable_indexes)
    return
  endif

  for i in reverse(copy(removable_indexes))
    let region = b:VM_Selection.Regions[i]
    let cursor = b:VM_Selection.Insert.cursors[i]
    let line = b:VM_Selection.Insert.lines[region.l]
    call region.remove_highlight()
    call region.clear()
    call matchdelete(cursor.hl)
    call remove(b:VM_Selection.Insert.cursors, i)
    call filter(line.cursors, 'v:val.index != ' . cursor.index)
  endfor
endfu

fu! s:regions_overlapping_interface(offset_from_linenr) abort
  let state = b:esearch.undotree.head.state
  let contexts = esearch#out#win#repo#ctx#new(b:esearch, state)
  let regions = []

  for region in b:VM_Selection.Regions
    if region.l == contexts.by_line(region.l).begin
      call add(regions, region)
    else
      let linenr = printf(s:linenr_format, state.line_numbers_map[region.l])
      if region.a <= strlen(linenr) + a:offset_from_linenr
        call add(regions, region)
      endif
    endif
  endfor

  return regions
endfu

fu! s:without_regions_overlapping_interface(orig, offset_from_linenr) abort
  let regions = s:regions_overlapping_interface(a:offset_from_linenr)
  if len(regions) == len(b:VM_Selection.Regions)
    return
  else
    for r in regions | call r.clear() | endfor
  endif

  call feedkeys(esearch#mappings#key2char(a:orig), 'n')
endfu

fu! s:CtrlW(orig) abort
  let state = b:esearch.undotree.head.state
  for cursor in b:VM_Selection.Insert.cursors
    let line = cursor.L
    let col = cursor._a
    let text = getline(line)
    let linenr = printf(s:linenr_format, state.line_numbers_map[line])
    if col <= strlen(linenr) + 1 || text[strlen(linenr): col - 2] =~# '^\s\+$'
      return ''
    endif
  endfor

  return eval(a:orig)
endfu

fu! s:i_delete_char(orig, offset_from_linenr) abort
  let s:offset_from_linenr = a:offset_from_linenr
  let s:V = b:VM_Selection
  let s:v = s:V.Vars
  let s:G = s:V.Global
  let s:F = s:V.Funcs
  let s:R = { -> s:V.Regions }
  let s:X = { -> g:Vm.extend_mode }
  let s:contexts = esearch#out#win#repo#ctx#new(b:esearch, b:esearch.undotree.head.state)
  let snr = matchstr(expand('<sfile>'), '<SNR>\d\+_')
  return substitute(eval(a:orig), 'vm#icmds#x', snr . 'vm_icmds_x', '')
endfu

" Reiplemented based on original vm#icmds#x() function
fu! s:vm_icmds_x(cmd) abort
  """""" modified block start
  let state = b:esearch.undotree.head.state
  """""" modified block end

  let size = s:F.size()
  let change = 0 | let s:v.eco = 1
  if empty(s:v.storepos) | let s:v.storepos = getpos('.')[1:2] | endif
  let active = s:R()[s:V.Insert.index]

  for r in s:R()

    """""" modified block start
    let linenr = printf(s:linenr_format, state.line_numbers_map[r.l])
    if r.a <= strlen(linenr) + s:offset_from_linenr || r.l == s:contexts.by_line(r.l).begin
      continue
    endif
    """""" modified block end

    if s:v.single_region && r isnot active
      if r.l == active.l
        call r.shift(change, change)
      endif
      continue
    endif

    call r.shift(change, change)
    call s:F.Cursor(r.A)

    " we want to emulate the behaviour that <del> and <bs> have in insert
    " mode, but implemented as normal mode commands

    """""" modified block start
    if a:cmd ==# 'x'                "normal delete
      normal! x
    else                                "normal backspace
      normal! X
      call r.update_cursor_pos()
    endif
    """""" modified block end

    "update changed size
    let change = s:F.size() - size
  endfor

  call s:G.merge_regions()
endfu
