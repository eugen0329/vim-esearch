let s:LiveUpdateGetchar = {}
let s:last_finished = -1

fu! s:LiveUpdateGetchar.new(model) abort dict
  return extend(copy(self), {'model': a:model})
endfu

fu! s:LiveUpdateGetchar.__enter__() abort dict
  if !g:esearch#has#globs_preview || !self.model.esearch.live_update | return | endif
  let redraw_wait = self.model.esearch.live_update_menu_redraw_wait
  let self.redraw_timer = timer_start(redraw_wait, function('s:redraw'), {'repeat': -1})
endfu

fu! s:LiveUpdateGetchar.__exit__() abort dict
  if !self.model.esearch.live_update | return | endif
  silent! call timer_stop(self.redraw_timer)
endfu

fu! s:redraw(_) abort
  if exists('b:esearch') && s:last_finished != b:esearch.id
    if b:esearch.request.finished == 2
      let s:last_finished = b:esearch.id
    endif

    call esearch#ui#runtime#view()
  endif
endfu

fu! esearch#ui#context#live_update_getchar#import() abort
  return s:LiveUpdateGetchar
endfu
