let s:ViewTracer = vital#esearch#import('Vim.ViewTracer')

let s:function_t = type(function('tr'))
let s:string_t   = type('')

fu! esearch#out#win#open#do(opener, ...) abort dict
  if !self.is_current() | return | endif
  let filename = self.filename()
  if empty(filename) | return | endif

  let opts        = get(a:000, 0, {})
  let stay        = get(opts, 'stay', 0)    " stay in the current window
  let once        = get(opts, 'once', 0)    " open only a single window
  let assignments = get(opts, 'let', {})    " assign vars/opts/regs
  let cmdarg      = get(opts, 'cmdarg', '') " EX: '++enc=utf8 ++ff=dos'
  let mods        = get(opts, 'mods', '')   " EX: botright
  let open_opts   = {'range': 'current', 'cmdarg': cmdarg, 'mods': mods}

  let let_ctx_manager = esearch#context_manager#let#new().enter(assignments)
  if stay
    let stay_ctx_manager = esearch#context_manager#stay#new().enter()
  endif

  let lnum = self.line_in_file()
  let topline = str2nr(lnum) - (line('.') - line('w0'))

  try
    let Open = once ? function('s:open_once') : function('s:open_new')
    call Open(self, a:opener, filename, open_opts)
    keepjumps call winrestview({'lnum': lnum, 'topline': topline })

  catch /E325:/ " swapexists exception, will be handled by a user
  catch
    unsilent echo v:exception . ' at ' . v:throwpoint
  finally
    call let_ctx_manager.exit()
    if stay | call stay_ctx_manager.exit() | endif
  endtry

  return 1
endfu

fu! s:open_new(esearch, opener, filename, opts) abort
  let a:opts.opener = s:to_callable(a:opener)
  call a:esearch.opened_manager.open(a:filename, a:opts)
endfu

fu! s:open_once(esearch, opener, filename, opts) abort
  let opener_id = s:opener_id(a:opener)
  let opened_window = get(a:esearch.windows_opened_once, opener_id, {})

  if s:ViewTracer.exists(opened_window)
    call s:ViewTracer.jump(opened_window)
    let a:opts.opener = s:to_callable('edit')
    unsilent call a:esearch.opened_once_manager.open(a:filename, a:opts)
  else
    let a:opts.opener = s:to_callable(a:opener)
    unsilent call a:esearch.opened_once_manager.open(a:filename, a:opts)
  endif

  let w:esearch = reltime() " to be able to trace the window
  let a:esearch.windows_opened_once[opener_id] =
        \ s:ViewTracer.trace_window()
endfu

fu! s:to_callable(opener) abort
  if type(a:opener) ==# s:function_t
    return a:opener
  endif

  return function('<SID>raw_opener', [a:opener])
endfu

fu! s:opener_id(opener) abort
  if type(a:opener) ==# s:string_t
    return a:opener
  elseif type(a:opener) ==# s:function_t
    let stringified = string(a:opener)
    " Same lambdas has different ids while they do the same. The code below
    " expands lambda source and removes lambda ids from it to allow user to
    " create anonymous functions without flooding vimrc.
    if stridx(stringified, "function('<lambda>") ==# 0
      let stringified = execute('function a:opener') " Expand lambda source
      let stringified = substitute(stringified, '<lambda>\(\d\+\)', '<number>', '')
    endif

    return stringified
  endif

  return string(a:opener)
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
