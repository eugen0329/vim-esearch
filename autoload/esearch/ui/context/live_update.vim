let s:LiveUpdate = esearch#util#struct({}, 'model', 'onchange')

fu! s:LiveUpdate.__enter__() abort dict
  if !g:esearch#has#globs_preview || !self.model.esearch.live_update | return | endif

  let self.original_options = esearch#let#restorable({'&cmdheight': 1})
  let wait = max([
        \ self.model.esearch.win_update_throttle_wait,
        \ self.model.esearch.live_update_debounce_wait])
  let self.redraw_timer = timer_start(wait, function('s:redraw'), {'repeat': -1})

  aug __esearch_live_update__
    au!
    au CmdlineChanged @ call s:cmdline_changed.apply()
  aug END
  let s:cmdline_changed = esearch#async#debounce(
        \ function('s:cmdline_changed', [self]),
        \ self.model.esearch.live_update_debounce_wait)
endfu

fu! s:LiveUpdate.__exit__() abort dict
  if !self.model.esearch.live_update | return | endif
  silent! au! __esearch_live_update__ *
  silent! call timer_stop(self.redraw_timer)
  call self.original_options.restore()
  call s:cmdline_changed.cancel()
endfu

fu! s:cmdline_changed(self, ...) abort
  if g:esearch#ui#runtime#input_prefilled
    let g:esearch#ui#runtime#input_prefilled = 0
    return
  endif

  let cmdline = getcmdline()
  call timer_start(0, function('s:resize', [cmdline]))
  if len(cmdline) < a:self.model.esearch.live_update_min_len | return | endif

  call esearch#ui#runtime#update([a:self.onchange, cmdline])
endfu

fu! s:resize(cmdline, _) abort
  let &cmdheight = (strdisplaywidth(g:esearch#ui#runtime#prompt) + strdisplaywidth(a:cmdline)) / &columns + 1
endfu

fu! s:redraw(_) abort
  redraw
endfu

fu! esearch#ui#context#live_update#import() abort
  return s:LiveUpdate
endfu
