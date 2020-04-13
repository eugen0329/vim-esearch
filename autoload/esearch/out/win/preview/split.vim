let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
      \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()

fu! esearch#out#win#preview#split#import() abort
  return {
        \ 'split_preview':      function('<SID>split_preview'),
        \ 'last_split_preview': {},
        \ }
endfu

" A wrapper around regular open
fu! s:split_preview(...) abort dict
  if !self.is_current() | return | endif

  let last = self.last_split_preview
  let current = {
        \ 'filename':     self.filename(),
        \ 'line_in_file': self.line_in_file(),
        \ }
  let self.last_split_preview = current

  if last ==# current
    " Open once to prevent redundant jumps that could also cause reappearing swap
    " handling prompt
    return 0
  endif

  return self.open(get(a:000, 0, 'vnew'), extend({
        \ 'stay': 1,
        \ 'once': 1,
        \ 'let!': {'&l:foldenable': 0},
        \ }, get(a:000, 1, {})))
endfu

