let s:default_opts = {
        \ 'stay':  1,
        \ 'reuse': 1,
        \ 'let':   {'&eventignore': g:esearch#preview#silent_open_eventignore, '&shortmess': &shortmess . 'F'},
        \ 'let!':  {'&l:foldenable': 0},
        \}

fu! esearch#out#win#preview#split#init(esearch) abort
  call extend(a:esearch, {
        \ 'split_preview_open': function('<SID>split_preview_open'),
        \ 'last_split_preview': {'filename': '', 'line_in_file': -1, 'bufnr': -1},
        \ })
endfu

" Wrapper around regular open
fu! s:split_preview_open(...) abort dict
  if !self.is_current() || esearch#util#is_visual(mode()) | return | endif

  let last = self.last_split_preview
  let filename     = self.filename()
  let line_in_file = self.line_in_file()
  if last.line_in_file ==# line_in_file && last.filename ==# filename && bufwinnr(last.bufnr) >= 0
    return 0
  endif
  let opts = get(a:000, 1, {})
  let emphasis = get(opts, 'emphasis', g:esearch#emphasis#default)

  let bufnr = self.open(get(a:000, 0, 'vnew'), extend(copy(s:default_opts), opts))
  let self.last_split_preview = {'filename': filename, 'line_in_file': line_in_file, 'bufnr': bufnr}
  if !empty(emphasis)
    call s:place_emphasis(emphasis, bufnr, line_in_file)
  endif

  return 1
endfu

fu! s:place_emphasis(emphasis, bufnr, line_in_file) abort
  call s:unplace_emphasis()
  let winid = bufwinid(a:bufnr)
  if winid == -1 | return | endif
  aug esearch_split_preview
    au! * <buffer>
    au BufLeave,BufWinLeave,WinLeave <buffer> call s:unplace_emphasis()
  aug END
  let b:esearch_emphasis = []
  for e in a:emphasis
    call add(b:esearch_emphasis, e.new(winid, a:bufnr, a:line_in_file).place())
  endfor
endfu

fu! s:unplace_emphasis() abort
  if exists('b:esearch_emphasis')
    call map(b:esearch_emphasis, 'v:val.unplace()')
    aug esearch_split_preview
      au! * <buffer>
    aug END
    unlet b:esearch_emphasis
  endif
endfu
