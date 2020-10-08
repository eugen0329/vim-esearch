fu! esearch#out#win#preview#floating#init(esearch) abort
  call extend(a:esearch, s:methods)
endfu

fu! s:preview_enter(count1, ...) abort dict
  if !self.is_current() || self.is_blank() | return | endif

  let opts = copy(get(a:, 2, {}))
  let ctx_filename = self.unescaped_filename()
  let view = {}

  if esearch#preview#is_open()
    let win = g:esearch#preview#win
    " Reuse the opened preview options
    let align = get(opts, 'align', '')
    let opts = extend(opts, g:esearch#preview#last.opts)
    if empty(align) || win.shape.align ==# 'cursor'
      let opts.width = max([120, win.shape.width])
      let opts.height = a:count1 * (win.shape.height ? win.shape.height : esearch#preview#default_height())
    else
      let opts.width = 0
      let opts.height = 0
    endif

    let filename = win.location.filename
    if ctx_filename ==# filename | let view = self.ctx_view() | endif
  else
    let filename = ctx_filename
    let view = self.ctx_view()
    if a:count1 > 1 | let opts.height = a:count1 * esearch#preview#default_height() | endif
  endif
  let opts.method = 'open_and_enter'

  let lazyredraw = esearch#let#restorable({'&lazyredraw': 1})
  try
    if !esearch#preview#open(filename, self.line_in_file(), opts)
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
  if !self.is_current() || self.is_blank() || esearch#util#is_visual(mode()) | return | endif
  return call(function('esearch#preview#open'),
        \ [self.unescaped_filename(), self.line_in_file()] + a:000)
endfu

fu! s:preview_zoom(count1, ...) abort dict
  if self.is_preview_open()
    let height = max([a:count1, 2]) * g:esearch#preview#last.win.shape.height
    let confirmation_prompt_height = 2 " prevent overlapping the text
    let height = esearch#util#clip(height, 0, &lines - confirmation_prompt_height)

    if g:esearch#preview#last.win.shape.height !=# height
      if g:esearch#preview#last.win.shape.width < 120 && index(['cursor', 'custom'], g:esearch#preview#last.win.shape.align) >= 0
        let g:esearch#preview#last.win.shape.width = 120
      endif

      let g:esearch#preview#last.win.shape.height = height
      call g:esearch#preview#last.win.reshape()
    endif
  else
    let opts = extend({'height': a:count1 * esearch#preview#default_height()}, get(a:, 1, {}))
    return self.preview_open(opts)
  endif
endfu

let s:methods = {
        \ 'preview_open':    function('<SID>preview_open'),
        \ 'preview_zoom':    function('<SID>preview_zoom'),
        \ 'preview_enter':   function('<SID>preview_enter'),
        \ 'preview_close':   function('esearch#preview#close'),
        \ 'is_preview_open': function('esearch#preview#is_open'),
        \ }
