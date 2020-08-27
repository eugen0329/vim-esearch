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

  let bufnr = self.open(get(a:000, 0, 'vnew'), extend({
        \ 'stay':  1,
        \ 'reuse': 1,
        \ 'let!':  {'&l:foldenable': 0},
        \ }, get(a:000, 1, {})))
  let self.last_split_preview = {
        \ 'filename': filename,
        \ 'line_in_file': line_in_file,
        \ 'bufnr': bufnr,
        \}

  return 1
endfu
