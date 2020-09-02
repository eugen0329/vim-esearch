fu! esearch#out#win#modifiable#init() abort
  let b:esearch.mode = 'edit'
  let v:errors = []
  setl modifiable
  setl undolevels=1000
  setl noautoindent nosmartindent " problems with insert
  setl formatoptions=
  setl noswapfile

  set buftype=acwrite
  aug ESearchWinModifiable
    au! * <buffer>
    au BufWriteCmd <buffer> call s:write()
  aug END

  let b:esearch.undotree = esearch#undotree#new({
        \ 'ctx_ids_map': b:esearch.ctx_ids_map,
        \ 'line_numbers_map': b:esearch.line_numbers_map,
        \ })
  call esearch#changes#listen_for_current_buffer(b:esearch.undotree)
  call esearch#changes#add_observer(function('<SID>handle'))

  call esearch#option#make_local_to_buffer('backspace', 'indent,start', 'InsertEnter')
  set nomodified

  call esearch#compat#visual_multi#init()
  call esearch#compat#multiple_cursors#init()
endfu

fu! esearch#out#win#modifiable#uninit(esearch) abort
  call esearch#option#reset()
  aug ESearchWinModifiable
    au! * <buffer>
  aug END
  call esearch#changes#unlisten_for_current_buffer()
endfu

fu! s:write() abort
  let parsed = esearch#out#win#parse#entire()
  if has_key(parsed, 'error')
    throw parsed.error
  endif

  let diff = esearch#out#win#diff#do(parsed.contexts, b:esearch.contexts[1:])

  if diff.statistics.files == 0
    echo 'Nothing to save'
    return
  endi

  let lines_stats = []
  let changes_count = 0
  if diff.statistics.modified > 0
    let changes_count += diff.statistics.modified
    let lines_stats += [diff.statistics.modified . ' modified']
  endif
  if diff.statistics.deleted > 0
    let changes_count += diff.statistics.deleted
    let lines_stats += [diff.statistics.deleted . ' deleted']
  endif
  let files_stats_text = printf(' %s %s %d %s',
        \ (len(lines_stats) > 1 ? 'lines' : esearch#util#pluralize('line', changes_count)),
        \ (diff.statistics.files > 1 ? 'across' : 'inside'),
        \ diff.statistics.files,
        \ esearch#util#pluralize('file', diff.statistics.files),
        \ )
  let message = 'Write changes? (' . join(lines_stats, ', ') . files_stats_text . ')'

  if esearch#ui#confirm#show(message, ['Yes', 'No']) == 1
    call esearch#writer#{b:esearch.writer}#write(diff, b:esearch)
  endif
endfu

fu! s:handle(event) abort
  if a:event.id =~# '^n-motion' || a:event.id =~# '^n-change'
        \  || a:event.id =~# '^v-delete' || a:event.id =~# '^V-line-delete'
        \  || a:event.id =~# '^V-line-change'
    call esearch#out#win#modifiable#delete_multiline#handle(a:event)
  elseif a:event.id =~# 'undo'
    call esearch#out#win#modifiable#undo#handle(a:event)
  elseif a:event.id =~# 'n-inline-paste' || a:event.id =~# 'n-inline-repeat-gn'
        \ || a:event.id =~# 'n-inline\d\+' || a:event.id =~# 'v-inline'
    let debug = esearch#out#win#modifiable#normal#inline#handle(a:event)
  elseif a:event.id =~# 'i-inline'
    let debug = esearch#out#win#modifiable#insert#inline#handle(a:event)
  elseif  a:event.id =~# 'i-delete-newline'
    let debug = esearch#out#win#modifiable#insert#delete_newlines#handle(a:event)
  elseif  a:event.id =~# 'blockwise-visual'
    call esearch#out#win#modifiable#blockwise_visual#handle(a:event)
  elseif  a:event.id =~# 'i-add-newline'
    call esearch#out#win#modifiable#insert#add_newlines#handle(a:event)
  elseif a:event.id =~# 'join'
    call esearch#out#win#modifiable#unsupported#handle(a:event)
  elseif a:event.id =~# 'cmdline'
    " no-op. will be removed as well as others
  else
    call esearch#out#win#modifiable#unsupported#handle(a:event)
  endif

  if g:esearch#env isnot 0
    call assert_equal(line('$') + 1, len(b:esearch.undotree.head.state.ctx_ids_map))
    call assert_equal(line('$') + 1, len(b:esearch.undotree.head.state.line_numbers_map))
    let a:event.errors = len(v:errors)
    " call esearch#debug#log(a:event,  len(v:errors))
  endif
endfu
