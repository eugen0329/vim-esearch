let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
      \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()

fu! esearch#out#win#preview#floating#init(esearch) abort
  call extend(a:esearch, {
        \ 'preview_open':    function('<SID>preview_open'),
        \ 'preview_enter':   function('<SID>preview_enter'),
        \ 'preview_zoom':    function('<SID>preview_zoom'),
        \ 'preview_close':   function('esearch#preview#close'),
        \ 'is_preview_open': function('esearch#preview#is_open'),
        \ })
endfu

fu! s:preview_enter(...) abort dict
  if !self.is_current() || self.is_blank() | return | endif

  if esearch#preview#is_open()
    " Reuse the opened preview options
    let opts = empty(g:esearch#preview#last) ? {} : g:esearch#preview#last.opts
    " Overwrite height and width as it could be zoomed
    let opts.width = g:esearch#preview#win.shape.width
    let opts.height = g:esearch#preview#win.shape.height
  else
    let opts = {}
  endif
  let opts = extend(copy(opts), copy(get(a:000, 0, {})))
  let opts.enter = s:true
  let view = self.ctx_view()

  let lazyredraw = esearch#let#restorable({'&lazyredraw': 1})
  try
    if !esearch#preview#open(self.unescaped_filename(), self.line_in_file(), opts)
      return
    endif
  finally
    call lazyredraw.restore()
  endtry

 " Is used to jump to the corresponding line and column where user was within
 " the search window. View column will correspond to the column inside the file.
  call winrestview(view)
endfu

fu! s:preview_open(...) abort dict
  if !self.is_current() || esearch#util#is_visual(mode()) | return | endif
  return call(function('esearch#preview#open'),
        \ [self.unescaped_filename(), self.line_in_file()] + a:000)
endfu

fu! s:preview_zoom() abort dict
  if self.is_preview_open()
    let height = g:esearch#preview#last.win.shape.height * 2
    let confirmation_prompt_height = 2 " prevent overlapping the text
    let height = esearch#util#clip(height, 0, &lines - confirmation_prompt_height)

    if g:esearch#preview#last.win.shape.height !=# height
      let g:esearch#preview#last.win.shape.height = height
      call g:esearch#preview#last.win.reshape()
    endif
  else
    return self.preview_open()
  endif
endfu
