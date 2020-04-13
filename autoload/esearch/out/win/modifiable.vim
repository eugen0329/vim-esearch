fu! esearch#out#win#modifiable#edit() abort
  let b:esearch.mode = 'edit'
  let v:errors = []
  setl modifiable
  setl undolevels=1000
  setl noautoindent nosmartindent " problems with insert
  setl formatoptions=
  setl noswapfile

  set buftype=acwrite
  aug esearch_win_modifiable
    au! * <buffer>
    au BufWriteCmd <buffer> call esearch#out#win#modifiable#write()
  aug END

  let b:esearch.undotree = esearch#undotree#new({
        \ 'ctx_ids_map': b:esearch.ctx_ids_map,
        \ 'line_numbers_map': b:esearch.line_numbers_map,
        \ })
  call esearch#changes#listen_for_current_buffer(b:esearch.undotree)
  call esearch#changes#add_observer(function('esearch#out#win#handle_changes'))

  call esearch#option#make_local_to_buffer('backspace', 'indent,start', 'InsertEnter')
  set nomodified

  call esearch#compat#visual_multi#init()
  call esearch#compat#multiple_cursors#init()
endfu

fu! esearch#out#win#modifiable#write() abort
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
    call esearch#writer#buffer#write(diff, b:esearch)
  endif
endfu
