let s:ViewTracer = vital#esearch#import('Vim.ViewTracer')

fu! esearch#out#win#open#do(opener, ...) abort dict
  if !self.is_current() | return | endif
  let filename = self.filename()
  if empty(filename) | return | endif

  let opts        = get(a:000, 0, {})
  let stay        = get(opts, 'stay', 0) " stay in the current window
  let once        = get(opts, 'once', 0) " open only a single window
  let assignments = get(opts, 'let', {}) " assign vars/opts/regs

  let let_ctx_manager = esearch#context_manager#let#new().enter(assignments)
  if stay
    let stay_ctx_manager = esearch#context_manager#stay#new().enter()
  endif

  let lnum = self.line_in_file()
  let topline = str2nr(lnum) - (line('.') - line('w0'))

  try
    let Open = once ? function('s:open_once') : function('s:open_new')
    call Open(self, a:opener, filename)
    keepjumps call winrestview({'lnum': lnum, 'topline': topline })

  catch /E325:/ " swapexists exception, will be handled by a user
  catch
    unsilent echo v:exception . ' at ' . v:throwpoint
  finally
    call let_ctx_manager.exit()
    if stay | call stay_ctx_manager.exit() | endif
  endtry
endfu

fu! s:open_new(esearch, opener, filename) abort
  call a:esearch.opened_manager
        \.open(a:filename, {'opener': a:opener, 'range': ''})
endfu

fu! s:open_once(esearch, opener, filename) abort
  let opened_win = get(a:esearch.wins_opened_once, a:opener, {})

  if s:ViewTracer.exists(opened_win)
    call s:ViewTracer.jump(opened_win)
    unsilent call a:esearch.opened_once_manager
          \.open(a:filename, {'opener': 'edit', 'range': ''})
  else
    unsilent call a:esearch.opened_once_manager
          \.open(a:filename, {'opener': a:opener, 'range': ''})
  endif
  let a:esearch.wins_opened_once[a:opener] = s:ViewTracer.trace_window()
endfu
