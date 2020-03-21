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
  let RawOpener = function('<SID>raw_opener', [a:opener])
  call a:esearch.opened_manager
        \.open(a:filename, {'opener': RawOpener, 'range': ''})
endfu

fu! s:open_once(esearch, opener, filename) abort
  let opened_window = get(a:esearch.windows_opened_once, a:opener, {})

  if s:ViewTracer.exists(opened_window)
    let RawOpener = function('<SID>raw_opener', ['edit'])
    call s:ViewTracer.jump(opened_window)
    unsilent call a:esearch.opened_once_manager
          \.open(a:filename, {'opener': RawOpener, 'range': ''})
  else
    let RawOpener = function('<SID>raw_opener', [a:opener])
    unsilent call a:esearch.opened_once_manager
          \.open(a:filename, {'opener': RawOpener, 'range': ''})
  endif
  let a:esearch.windows_opened_once[a:opener] =
        \ s:ViewTracer.trace_window()
endfu

" Notes, why opening of a filename escaped previously is required:
" - It'll be easier to switch to featching of escaped filename from the layout
"   in a case when immutable UI feature is disabled
" - Filenames are escaped to allow copypasting directly from a search window
"   without extra efforts
"
" Internally vital uses `=a:filename` that works only with unescaped strings
fu! s:raw_opener(opener, filename) abort dict
  exe self.mods a:opener self.cmdarg a:filename
endfu
