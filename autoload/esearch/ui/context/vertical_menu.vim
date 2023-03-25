let s:VerticalMenu = {}

fu! s:VerticalMenu.new(height) abort dict
  return extend(copy(self), {'height': a:height})
endfu

fu! s:VerticalMenu.__enter__() abort dict
  let self.original_winheight = winheight(0)
  let self.original_options = esearch#let#restorable({
        \ '&cmdheight': self.height,
        \ '&lazyredraw': 1,
        \ '&more': 0,
        \ '&t_ve': ''})
endfu

fu! s:VerticalMenu.__exit__() abort dict
  call self.original_options.restore()
  exe 'resize ' . self.original_winheight
endfu


fu! esearch#ui#context#vertical_menu#import() abort
  return s:VerticalMenu
endfu
