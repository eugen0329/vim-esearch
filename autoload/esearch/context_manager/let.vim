let s:Guard = vital#esearch#import('Vim.Guard')
let s:null = 0

" Python-like approach to assign variables per context

fu! esearch#context_manager#let#new() abort
  return s:Let.new()
endfu

let s:Let = {'guard': s:null}

fu! s:Let.new() abort
  return copy(self)
endfu

fu! s:Let.enter(variables) abort dict
  if empty(a:variables) | return self | endif

  let self.guard = s:Guard.store(keys(a:variables))
  call esearch#let#do(a:variables)

  return self
endfu

fu! s:Let.exit() abort dict
  if empty(self.guard) | return self | endif
  call self.guard.restore()
endfu
