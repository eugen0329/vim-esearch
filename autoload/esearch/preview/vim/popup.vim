let s:Log    = esearch#log#import()
let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
     \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()
let s:relative = 'win'

fu! esearch#preview#vim#popup#import() abort
  return s:VimPopup
endfu

let s:VimPopup = esearch#preview#base_popup#import()

fu! s:VimPopup.reshape() abort dict
  if !self.buffer.is_valid()
    call s:Log.error('Preview buffer was deleted')
    return esearch#preview#close()
  endif
  let height = self.shape.height
  let line   = self.location.line

  if &lines < height + self.shape.row
    let self.shape.row = &lines - height - 2
  endif
  call popup_setoptions(self.id, {
        \ 'firstline': max([1, line - height/2]),
        \ })
  call popup_move(self.id, {
        \ 'maxheight': height,
        \ 'minheight': height,
        \ 'line': self.shape.row,
        \ })
endfu

fu! s:VimPopup.open() abort dict
  noau let self.id = popup_create(self.buffer.id, {
      \ 'maxwidth':  self.shape.width,
      \ 'minwidth':  self.shape.width,
      \ 'maxheight': self.shape.height,
      \ 'minheight': self.shape.height,
      \ 'line':      self.shape.row,
      \ 'col':       self.shape.col,
      \ 'pos':       self.shape.anchor,
      \ 'highlight': 'esearchNormalFloat',
      \ 'scrollbar': 0,
      \})
  return self
endfu

fu! s:VimPopup.close() abort dict
  call self.unplace_emphasis()
  call popup_close(self.id)
endfu
