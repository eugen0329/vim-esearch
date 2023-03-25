let s:Previewable = esearch#util#struct({})
" let s:Previewable = {}

" fu! s:Previewable.new() abort
"   return copy(self)
" endfu

fu! s:Previewable.__enter__() abort dict
endfu

fu! s:Previewable.__exit__() abort dict
  call esearch#preview#wipeout()
endfu

fu! esearch#ui#context#previewable#import() abort
  return s:Previewable
endfu
