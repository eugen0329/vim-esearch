let s:ViewTracer = vital#esearch#import('Vim.ViewTracer')
let s:null = 0

" Python-like approach to stay within a current window and a current tab

fu! esearch#context_manager#stay#new() abort
  return s:Stay.new()
endfu

let s:Stay = {'guard': s:null}

fu! s:Stay.new() abort
  return copy(self)
endfu

fu! s:Stay.enter() abort dict
  let self.view = winsaveview()
  let w:esearch = reltime() " to be able to trace the window
  let self.handle = s:ViewTracer.trace_window()
  return self
endfu

fu! s:Stay.exit() abort dict
  call s:ViewTracer.jump(self.handle)
  call winrestview(self.view)
endfu
