if !exists('esearch#substitute#swapchoice')
  let g:esearch#substitute#swapchoice = ''
endif

fu! esearch#substitute#do(args, from, to, out) abort
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
    if a:out.is_file_entry()
      let not_found = 0

      let filename = a:out.filename()

      let target_line = a:out.line_number()
      let already_opened = has_key(opened_files, filename)

      " Goto already opened file or open new
      if already_opened
        exe noautocmd.'tabn'.opened_files[filename].'|'.target_line
      else
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

  call s:statistics(opened_files, get(besearch, 'unresolved_swapfiles', 0))

  call s:cleanup(besearch)
  exe 'tabn '.last_modified_tab
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
fu! esearch#substitute#complete(A,L,P)
  if a:A =~ '^[/?]\k*$'
    let char = strpart(a:A,0,1)
    return join(map(esearch#util#buff_words(),'char . v:val'),"\n")
  elseif a:A =~# '^\k\+$'
    return join(esearch#util#buff_words(),"\n")
  endif
endfu
