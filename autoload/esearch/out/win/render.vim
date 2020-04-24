let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
      \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()

fu! esearch#out#win#render#init(esearch) abort
  call extend(a:esearch, {
        \ 'contexts':         [],
        \ 'files_count':      0,
        \ 'separators_count': 0,
        \ 'line_numbers_map': [],
        \ 'ctx_by_name':      {},
        \ 'ctx_ids_map':      [],
        \})

  if a:esearch.win_render_strategy ==# 'lua'
    let a:esearch.render = function('esearch#out#win#render#lua#do')
  else
    let a:esearch.render = function('esearch#out#win#render#viml#do')
  endif

  setl undolevels=-1 noswapfile nonumber norelativenumber nospell nowrap synmaxcol=400
  setl nolist nomodeline foldcolumn=0 buftype=nofile bufhidden=hide foldmethod=marker
  call esearch#let#generic(a:esearch.win_let)

  " setup blank context for header
  call esearch#out#win#render#add_context(a:esearch.contexts, '', 1)
  let header_context = a:esearch.contexts[0]
  let header_context.end = 2
  let a:esearch.ctx_ids_map += [header_context.id, header_context.id]
  let a:esearch.line_numbers_map += [0, 0]
  setl modifiable
  silent 1,$delete_
  call esearch#util#setline(bufnr('%'), 1, b:esearch.header_text())
  setl nomodifiable
endfu

fu! esearch#out#win#render#add_context(contexts, filename, begin) abort
  call add(a:contexts, {
        \ 'id': len(a:contexts),
        \ 'begin': a:begin,
        \ 'end': 0,
        \ 'filename': a:filename,
        \ 'filetype': s:null,
        \ 'syntax_loaded': 0,
        \ 'lines': {},
        \ })
endfu
