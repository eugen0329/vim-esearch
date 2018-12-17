if !exists('esearch#substitute#swapchoice')
  let g:esearch#substitute#swapchoice = ''
endif

" :%s/exe/sleep 400m | redraw! |/

fu! esearch#substitute#do(args, from, to, out) abort
  let current_search_win_line = a:from
  let limit = a:from > a:to ? a:from + 1 : a:to + 1

  let besearch = get(b:, 'esearch', {})

  let bufnr = bufnr('%')
  let pushed_right = 0
  let search_win_tab = tabpagenr()
  let last_modified_tab = tabpagenr()
  let opened_files = {}
  let prev_filename = ''
  let noautocmd = 'noautocmd '

  augroup ESearchSubstituteSwap
    au!
  augroup END

  while current_search_win_line < limit
    exe noautocmd.'tabn '.search_win_tab
    exe current_search_win_line

    if !a:out.is_file_entry()
      let current_search_win_line += 1
      continue
    endif

    let filename = a:out.filename()
    let line_in_file = a:out.line_in_file()
    let already_opened = has_key(opened_files, filename)

    " Locate buffer with a line to substitute
    if already_opened
      exe noautocmd.'tabn'.opened_files[filename].'|'.line_in_file
    else  " open new window
      if !empty('g:esearch#substitute#swapchoice')
        exe 'au ESearchSubstituteSwap SwapExists *'.filename.' call s:make_swap_choise(escape(expand("<afile>"), " "), '.bufnr.')'
      endif
      call a:out.open('$tabnew')

      " NOTE besearch.unresolved_swapfiles initializes in s:make_swap_choise event, binded below
      "
      " If swap files exists ||
      " user has selected v:swapchoice ==# 'q' (window was closed manually) ||
      " if (O)pen Read-Only swap option ||
      " D(i)ff option was selected (enabled by Recover.vim)
      if (exists('besearch.unresolved_swapfiles') && index(besearch.unresolved_swapfiles, filename) >= 0) ||
            \ index(values(opened_files), tabpagenr()) >= 0 ||
            \ &readonly ||
            \ &diff
        let current_search_win_line += 1
        continue
      else
        let opened_files[filename] = tabpagenr()
      endif
    endif

    let no_matches_were_found = s:substitute(a:args)
    if !no_matches_were_found
      call s:init_highlights(line_in_file)
    endif

    if no_matches_were_found && !already_opened
      " close buffer without matches
      call remove(opened_files, filename)
      let useless_tab = tabpagenr()
      exe noautocmd.'tabn'.search_win_tab
      exe noautocmd.'tabclose'.useless_tab
    else " make search window rightmost
      let last_modified_tab = tabpagenr()

      " make search window rightmost
      if !pushed_right
        let pushed_right = 1
        " goto search win tab
        exe noautocmd.'tabn'.search_win_tab
        " Push current search tab to the right (penultimate position,
        " before the newly opened) for more convenience
        let search_win_tab = tabpagenr('$') - 1
        exe noautocmd.'tabm '.search_win_tab
      endif
    endif
    let current_search_win_line += 1
  endwhile

  call s:statistics(opened_files, get(besearch, 'unresolved_swapfiles', 0))

  call s:cleanup(besearch)
  exe 'tabn '.last_modified_tab
endfu

fu! s:substitute(args) abort
  try
    exe 's'a:args
  catch /E486:/
    " no matches were found
    return 1
  endtry
  return 0
endfu

" TODO Add multiline highligh
fu! s:init_highlights(line_in_file) abort
  if !exists('b:esearch')
    let b:esearch = { 'matchids': [] }
    augroup ESearchSubstituteHL
      au! * <buffer>
      au InsertEnter,BufWritePost,TextChanged <buffer> call s:clear_hightligh()
    augroup END
  endif
  call add(b:esearch.matchids, matchadd('DiffChange', '\%'.a:line_in_file.'l', -1))
endfu

fu! s:clear_hightligh() abort
  au! ESearchSubstituteHL * <buffer>
  for m in b:esearch.matchids
    call matchdelete(m)
  endfor
  unlet b:esearch
endfu

" Disables swap resolving and saves swap to b:esearch.unresolved_swapfiles list
fu! s:make_swap_choise(fname, esearch_buf) abort
  " call getchar()
  let esearch = getbufvar(a:esearch_buf, 'esearch')
  if !has_key(esearch, 'unresolved_swapfiles')
    let esearch.unresolved_swapfiles = []
  endif
  if index(esearch.unresolved_swapfiles, a:fname) < 0
    call add(esearch.unresolved_swapfiles, a:fname)
  endif
  " PP
  " 'o'   Open read-only
  " 'e'   Edit anyway
  " 'r'   Recover
  " 'd'   Delete swapfile
  " 'q'   Quit
  " 'a'   Abort
  let v:swapchoice = g:esearch#substitute#swapchoice
endfu

fu! s:cleanup(besearch) abort
  if has_key(a:besearch, 'unresolved_swapfiles')
    unlet a:besearch.unresolved_swapfiles
  endif
  augroup ESearchSubstituteSwap
    au!
  augroup END
endfu

fu! s:statistics(opened_files, unresolved_swapfiles) abort
  echo len(a:opened_files) . ' files changed'

  let unresolved_swapfiles = a:unresolved_swapfiles
  if !empty(a:unresolved_swapfiles)
    echo ''
    call esearch#util#hlecho([['Title', 'The following files has unresolved swapfiles'], ['Normal']])
    for name in unresolved_swapfiles
      echo "\t".name
    endfor
  endif
endfu

" From abolish.vim
fu! esearch#substitute#complete(A,L,P) abort
  if a:A =~# '^[/?]\k*$'
    let char = strpart(a:A,0,1)
    return join(map(esearch#util#buff_words(),'char . v:val'),"\n")
  elseif a:A =~# '^\k\+$'
    return join(esearch#util#buff_words(),"\n")
  endif
endfu
