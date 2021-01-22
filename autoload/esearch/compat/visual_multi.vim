let s:List    = vital#esearch#import('Data.List')
let s:Log = esearch#log#import()
let s:textobjects_whitelist = 'w()[]{}<>|''`"'

fu! esearch#compat#visual_multi#init() abort
  if exists('g:esearch_visual_multi_loaded') || !exists('g:esearch')
    return
  endif
  let g:esearch_visual_multi_loaded = 1

  let g:VM_plugins_compatibilty = extend(get(g:, 'VM_plugins_compatibilty', {}), {
            \ 'esearch': {
            \   'test': function('<SID>test'),
            \   'enable': 'call esearch#out#win#init_user_keymaps()',
            \   'disable': 'call esearch#out#win#uninit_user_keymaps()',
            \ },
            \})
  aug esearch_visual_multi
    au!
    au User visual_multi_start     call s:visual_multi_start()
    au User visual_multi_after_cmd call s:visual_multi_after_cmd()
  aug END
endfu

fu! s:test() abort
  return &filetype ==# 'esearch'
endfu

fu! s:visual_multi_after_cmd() abort
  if !exists('b:esearch') | return | endif
  let b:esearch.state = b:esearch.undotree.commit(b:esearch.state)
endfu

fu! s:visual_multi_start() abort
  if exists('b:esearch_visual_multi_loaded') || !exists('b:esearch')
    return
  endif
  let b:esearch_visual_multi_loaded = 1

  aug esearch_visual_multi
    au! * <buffer>
    au TextChangedP,TextChangedI <buffer> call s:remove_cursors_overlapping_ui(0)
  aug END

  call s:nremap('<plug>(VM-D)',                  '<SID>clear_regions_overlapping_ui(%s, 0)')
  call s:nremap('<plug>(VM-x)',                  '<SID>clear_regions_overlapping_ui(%s, 0)')
  call s:nremap('<plug>(VM-X)',                  '<SID>clear_regions_overlapping_ui(%s, 1)')
  call s:nremap('<plug>(VM-J)',                  '<SID>unsupported(%s, "Is not supported")')
  call s:nremap('<plug>(VM-~)',                  '<SID>clear_regions_overlapping_ui(%s, 0)')
  " What is it for?
  " <plug>(VM-&)
  call s:nremap('<plug>(VM-Del)',                '<SID>clear_regions_overlapping_ui(%s, 1)')
  call s:nremap('<plug>(VM-Dot)',                '<SID>unsupported(%s, "Is not supported")')
  call s:nremap('<plug>(VM-Increase)',           '<SID>clear_regions_overlapping_ui(%s, 0)')
  call s:nremap('<plug>(VM-Decrease)',           '<SID>clear_regions_overlapping_ui(%s, 0)')
  call s:nremap('<plug>(VM-Alpha-Increase)',     '<SID>clear_regions_overlapping_ui(%s, 0)')
  call s:nremap('<plug>(VM-Alpha-Decrease)',     '<SID>clear_regions_overlapping_ui(%s, 0)')
  call s:nremap('<plug>(VM-a)',                  '<SID>clear_regions_overlapping_ui(%s, -1)')
  call s:nremap('<plug>(VM-i)',                  '<SID>clear_regions_overlapping_ui(%s, 0)')
  call s:nremap('<plug>(VM-I)',                  '<SID>unsupported(%s, "Is not supported")')
  call s:nremap('<plug>(VM-o)',                  '<SID>unsupported(%s, "Inserting newlines is not supported")')
  call s:nremap('<plug>(VM-O)',                  '<SID>unsupported(%s, "Inserting newlines is not supported")')
  call s:nremap('<plug>(VM-c)',                  '<SID>c_operator(%s, 0, v:count1, v:register)')
  call s:nremap('<plug>(VM-gc)',                 '<SID>unsupported(%s, "Is not supported")')
  call s:nremap('<plug>(VM-C)',                  '<SID>unsupported(%s, "Is not supported")')
  call s:nremap('<plug>(VM-Delete)',             '<SID>d_operator(%s, 0, v:count1, v:register)')
  call s:nremap('<plug>(VM-Delete-Exit)',        '<SID>d_operator(%s, 0, v:count1, v:register)')
  call s:nremap('<plug>(VM-Replace-Characters)', '<SID>clear_regions_overlapping_ui(%s, -1)')
  call s:nremap('<plug>(VM-Replace)',            '<SID>unsupported(%s, "Is not supported")')
  " TODO can be implemented
  call s:nremap('<plug>(VM-Transform-Regions)',  '<SID>unsupported(%s, "Is not supported")')
  call s:nremap('<plug>(VM-p-Paste-Regions)',    '<SID>unsupported(%s, "Is not supported")')
  call s:nremap('<plug>(VM-P-Paste-Regions)',    '<SID>unsupported(%s, "Is not supported")')
  call s:nremap('<plug>(VM-p-Paste-Vimreg)',     '<SID>unsupported(%s, "Is not supported")')
  call s:nremap('<plug>(VM-P-Paste-Vimreg)',     '<SID>unsupported(%s, "Is not supported")')

  call s:iremap('<plug>(VM-I-Return)',      '<SID>unsupported(%s, "Inserting newlines is not supported")')
  call s:iremap('<plug>(VM-I-BS)',          '<SID>i_delete_char(%s, 1)')
  call s:iremap('<plug>(VM-I-Paste)',       '<SID>unsupported(%s, "Is not supported")')
  call s:iremap('<plug>(VM-I-CtrlW)',       '<SID>CtrlW(%s)')
  call s:iremap('<plug>(VM-I-CtrlU)',       '<SID>CtrlW(%s)')
  call s:iremap('<plug>(VM-I-CtrlD)',       '<SID>i_delete_char(%s, -2)')
  call s:iremap('<plug>(VM-I-Del)',         '<SID>i_delete_char(%s, -2)')
  call s:iremap('<plug>(VM-I-Replace)',     '<SID>unsupported(%s, "Is not supported")')
endfu

fu! s:nremap(lhs, rhs) abort
  let map = substitute(maparg(a:lhs, 'n'), '<', '<lt>', 'g')
  exe printf('nnoremap <silent><buffer> %s :<c-u>call ' . a:rhs . '<cr>', a:lhs, string(map))
endfu

fu! s:iremap(lhs, rhs) abort
  let map = substitute(maparg(a:lhs, 'i'), '<', '<lt>', 'g')
  exe printf('inoremap <silent><expr><buffer> %s ' . a:rhs, a:lhs, string(map))
endfu

fu! s:unsupported(orig, msg) abort
  call s:Log.echo('ErrorMsg', a:msg)
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
  let regions = s:regions_overlapping_ui(a:offset_from_linenr)
  if len(regions) == len(b:VM_Selection.Regions)
    return
  else
    for r in regions | call r.clear() | endfor
  endif
  if g:Vm.extend_mode
    return feedkeys(esearch#keymap#key2char(a:orig))
  endif

  let [motion, motion_count] = s:sanitized_motion(a:whitelist0, a:whitelist1, a:whitelist2)
  if empty(motion)
    return
  endif

  "" Counts are ignored for now as they can cause multiline changes
  " let multiplied_count = (a:count * motion_count)
  call feedkeys(esearch#keymap#key2char(a:orig) . motion, 't')
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
      call s:unsupported('', 'Textobject ' . textobj . ' is not supported')
      return ['', '']
    endif
    let motion .= textobj
  else
    call s:unsupported('', 'Motion ' . motion . ' is not supported')
    return ['', '']
  endif

  return [motion, motion_count]
endfu

" According to visual-multi source code, regions are roughly the same as
" cursors, but cursors are used only in INSERT mode
fu! s:remove_cursors_overlapping_ui(offset_from_linenr) abort
  if empty(b:VM_Selection)
    return
  endif

  let state = b:esearch.state
  let contexts = esearch#out#win#repo#ctx#new(b:esearch, state)
  let removable_indexes = []

  let i = 0
  for cursor in b:VM_Selection.Insert.cursors
    let ctx = contexts.by_line(cursor.l)
    if cursor.l == ctx._begin || (cursor.l == ctx._end && cursor.l != line('$'))
      call add(removable_indexes, i)
    else
      let linenr = matchstr(getline(cursor.l), g:esearch#out#win#column_re)
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

fu! s:regions_overlapping_ui(offset_from_linenr) abort
  let state = b:esearch.state
  let contexts = esearch#out#win#repo#ctx#new(b:esearch, state)
  let regions = []

  for region in b:VM_Selection.Regions
    if region.l == contexts.by_line(region.l)._begin
      call add(regions, region)
    else
      let linenr = matchstr(getline(region.l), g:esearch#out#win#column_re)
      if region.a <= strlen(linenr) + a:offset_from_linenr
        call add(regions, region)
      endif
    endif
  endfor

  return regions
endfu

fu! s:clear_regions_overlapping_ui(orig, offset_from_linenr) abort
  let regions = s:regions_overlapping_ui(a:offset_from_linenr)
  if len(regions) == len(b:VM_Selection.Regions)
    return
  else
    for r in regions | call r.clear() | endfor
  endif

  call feedkeys(esearch#keymap#key2char(a:orig), 'n')
endfu

fu! s:CtrlW(orig) abort
  let state = b:esearch.state
  for cursor in b:VM_Selection.Insert.cursors
    let wlnum = cursor.L
    let col = cursor._a
    let line = getline(wlnum)
    let linenr = matchstr(line, g:esearch#out#win#column_re)
    if col <= strlen(linenr) + 1 || line[strlen(linenr): col - 2] =~# '^\s\+$'
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
  let s:contexts = esearch#out#win#repo#ctx#new(b:esearch, b:esearch.state)
  let snr = matchstr(expand('<sfile>'), '<SNR>\d\+_')
  return substitute(eval(a:orig), 'vm#icmds#x', snr . 'vm_icmds_x', '')
endfu

" Reiplemented based on original vm#icmds#x() function
fu! s:vm_icmds_x(cmd) abort
  """""" modified block start
  let state = b:esearch.state
  """""" modified block end

  let size = s:F.size()
  let change = 0 | let s:v.eco = 1
  if empty(s:v.storepos) | let s:v.storepos = getpos('.')[1:2] | endif
  let active = s:R()[s:V.Insert.index]

  for r in s:R()

    """""" modified block start
    let linenr = matchstr(getline(r.l), g:esearch#out#win#column_re)
    if r.a <= strlen(linenr) + s:offset_from_linenr || r.l == s:contexts.by_line(r.l)._begin
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

    " we want to emulate the behavior that <del> and <bs> have in insert
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
