let s:PersistentStatusline = {}

fu! s:PersistentStatusline.new(model) abort dict
  return extend(copy(self), {'model': a:model})
endfu

fu! s:PersistentStatusline.__enter__() abort dict
  let self.lstatusline = &l:statusline
  let self.gstatusline = &g:statusline
  let self.glaststatus = &g:laststatus
  let self.winid = win_getid()
  aug __esearch_persistent_statusline__
    au!
    au BufEnter * if g:esearch#ui#runtime#statusline isnot# 0 | let &statusline = g:esearch#ui#runtime#statusline | endif
  aug END
endfu

fu! s:PersistentStatusline.__exit__() abort dict
  au! __esearch_persistent_statusline__ *
  call esearch#win#let(self.winid, '&statusline', self.lstatusline)
  let &g:statusline = self.gstatusline
  let &g:laststatus = self.glaststatus
endfu

fu! esearch#ui#context#persistent_statusline#import() abort
  return s:PersistentStatusline
endfu
