fu! esearch#substitute#do(args, from, to, out)
  let line = a:from
  let limit = a:from > a:to ? a:from + 1 : a:to + 1

  let besearch = b:esearch

  let bufnr = bufnr('%')
  let pushed_right = 0
  let root = tabpagenr()
  let last_modified_tab = tabpagenr()
  let opened_files = {}
  let prev_filename = ''
  let noautocmd = 'noautocmd '

  augroup ESearchSubstituteSwap
    au!
  augroup END

  while line < limit
    exe noautocmd.'tabn '.root
    exe line
    if getline(line) =~# a:out.file_entry
      let not_found = 0

      let filename = a:out.filename()

      let target_line = a:out.line_number()
      let already_opened = has_key(opened_files, filename)

      if already_opened
        exe noautocmd.'tabn'.opened_files[filename].'|'.target_line
      else
        exe 'au ESearchSubstituteSwap SwapExists *'.filename.' call s:handle_swap(escape(expand("<afile>"), " "), '.bufnr.')'
        call a:out.open('$tabnew')
        " besearch.swapfiles initializes in s:handle_swap event, binded below
        if exists('besearch.swapfiles') && index(besearch.swapfiles, filename) >= 0
          let line += 1
          continue
        else
          let opened_files[filename] = tabpagenr()
        endif
      endif

      let not_found = s:substitute(a:args)
      if !not_found
        call s:init_highlights(target_line)
      endif

      if not_found && !already_opened
        call remove(opened_files, filename)
        let useless_tab = tabpagenr()
        exe noautocmd.'tabn'.root
        exe noautocmd.'tabclose'.useless_tab
      else
        let last_modified_tab = tabpagenr()
        if !pushed_right
          let pushed_right = 1
          exe noautocmd.'tabn'.root
          " Push current search tab to the right (penultimate position,
          " before the newly opened) for more convenience
          let root = tabpagenr('$') - 1
          exe noautocmd.'tabm '.(root - 1 )
        endif
      endif
    endif
    let line += 1
  endwhile

  call s:statistics(opened_files, get(besearch, 'swapfiles', 0))
  call s:cleanup(besearch)
  exe 'tabn'last_modified_tab
endfu

fu! s:substitute(args) abort
  try
    exe 's'a:args
  catch /E486:/
    return 1
  endtry
  return 0
endfu

" TODO Add multiline highligh
fu! s:init_highlights(target_line) abort
  if !exists('b:esearch')
    let b:esearch = { 'matchids': [] }
    augroup ESearchSubstituteHL
      au! * <buffer>
      au InsertEnter,BufWritePost,TextChanged <buffer> call s:clear_hightligh()
    augroup END
  endif
  call add(b:esearch.matchids, matchadd('DiffChange', '\%'.a:target_line.'l', -1))
endfu

fu! s:clear_hightligh()
  au! ESearchSubstituteHL * <buffer>
  for m in b:esearch.matchids
    call matchdelete(m)
  endfor
  unlet b:esearch
endfu

" Disables swap resolving and saves swap to b:esearch.swapfiles list
fu! s:handle_swap(fname, esearch_buf)
  let esearch = getbufvar(a:esearch_buf, 'esearch')
  if type(esearch) !=# type({})
    let g:ok = [a:fname, a:esearch_buf]
  endif
  if !has_key(esearch, 'swapfiles')
    let esearch.swapfiles = []
  endif
  if index(esearch.swapfiles, a:fname) < 0
    call add(esearch.swapfiles, a:fname)
  endif
  " 'o'   Open read-only
  " 'e'   Edit anyway
  " 'r'   Recover
  " 'd'   Delete swapfile
  " 'q'   Quit
  " 'a'   Abort
  let v:swapchoice = 'q'
endfu

fu! s:cleanup(besearch)
  if has_key(a:besearch, 'swapfiles')
    unlet a:besearch.swapfiles
  endif
endfu

fu! s:statistics(opened_files, swapfiles)
  echo len(a:opened_files) . ' files changed'
  if !empty(a:swapfiles)
    echo ''
    call esearch#util#highlight('Title', 'The following files has unresolved swapfiles', 1)
    for sf in a:swapfiles
      echo "\t".sf
    endfor
  endif
endfu

