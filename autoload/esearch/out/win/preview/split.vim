let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
      \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()

fu! esearch#out#win#preview#split#init(esearch) abort
  call extend(a:esearch, {
        \ 'split_preview_open': function('<SID>split_preview_open'),
        \ 'last_split_preview': {'filename': '', 'line_in_file': -1, 'bufnr': -1},
        \ })
endfu

" A wrapper around regular open
fu! s:split_preview_open(...) abort dict
  if !self.is_current() | return | endif

  let last = self.last_split_preview
  let current = {
        \ 'filename':     self.filename(),
        \ 'line_in_file': self.line_in_file(),
        \ }
  if last ==# current && bufwinnr(last.bufnr) >= 0
    return 0
  endif
  let self.last_split_preview = current

  let current.bufnr = self.open(get(a:000, 0, 'vnew'), extend({
        \ 'stay':  1,
        \ 'reuse': 1,
        \ 'let!':  {'&l:foldenable': 0},
        \ }, get(a:000, 1, {})))
  return s:true
endfu
