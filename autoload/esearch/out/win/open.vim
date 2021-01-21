let s:Log       = esearch#log#import()
let s:Filepath      = vital#esearch#import('System.Filepath')
let s:BufferManager = vital#esearch#import('Vim.BufferManager')
let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
      \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()

fu! esearch#out#win#open#init(esearch) abort
  call extend(a:esearch, {
        \ 'reusable_windows':         {},
        \ 'reusable_buffers_manager': s:BufferManager.new(),
        \ 'opened_buffers_manager':   s:BufferManager.new(),
        \ 'open':                     function('<SID>open'),
        \}, 'keep')
endfu

fu! s:open(opener, ...) abort dict
  if !self.is_current() || self.is_blank() | return | endif
  let filename = self.filename()
  if empty(filename) | return | endif

  let opts      = get(a:, 1, {})
  let stay      = get(opts, 'stay', 0)    " stay in the current window
  let reuse     = get(opts, 'reuse', 0)   " open only a single window
  let vars      = get(opts, 'let!', {})   " assign vars/opts/regs within an opened win
  let cmdarg    = get(opts, 'cmdarg', '') " EX: '++enc=utf8 ++ff=dos'
  let mods      = get(opts, 'mods', '')   " EX: botright
  let open_opts = {'range': 'current', 'cmdarg': cmdarg, 'mods': mods}
  " assign vars/opts/regs per function execution
  if stay
    let restorable_vars = get(opts, 'let', {'&ei': 'WinLeave,BufLeave,BufWinLeave,TabLeave'})
  else
    let restorable_vars = get(opts, 'let', {})
  endif

  let original_vars = esearch#let#restorable(restorable_vars)
  if stay | let current_win = esearch#win#stay() | endif

  let view = self.ctx_view()
  let view.topline = str2nr(view.lnum) - (line('.') - line('w0'))

  call esearch#util#doautocmd('User esearch_open_pre')
  try
    let l:Open = reuse ? function('s:open_reusable') : function('s:open_new')
    call Open(self, a:opener, filename, open_opts)
    let bufnr = bufnr('%')
    keepjumps call winrestview(view)
    call esearch#let#bulk(vars)
  catch /E325:/ " swapexists exception, will be handled by the user
  catch /Vim:Interrupt/ " Throwed on cancelling swap, can be safely suppressed
  catch
    call s:Log.error(v:exception . ' at ' . v:throwpoint)
    return
  finally
    call original_vars.restore()
    if stay | call current_win.restore() | endif
  endtry

  return bufnr
endfu

fu! s:open_new(esearch, opener, filename, opts) abort
  let a:opts.opener = s:to_callable(a:opener)
  call a:esearch.opened_buffers_manager.open(a:filename, a:opts)
endfu

fu! s:open_reusable(esearch, opener, filename, opts) abort
  let opener_id = string(a:opener)
  let opened_window = get(a:esearch.reusable_windows, opener_id, s:null)

  if !empty(opened_window) && esearch#win#exists(opened_window)
    call win_gotoid(opened_window)
    " Don't open if the file is already opened.
    " Prevents from asking about existing swap prompt multiple times
    if s:Filepath.abspath(bufname('%')) !=# a:filename
      let a:opts.opener = s:to_callable('edit')
      unsilent call a:esearch.reusable_buffers_manager.open(a:filename, a:opts)
    endif
  else
    let a:opts.opener = s:to_callable(a:opener)
    unsilent call a:esearch.reusable_buffers_manager.open(a:filename, a:opts)
  endif

  let a:esearch.reusable_windows[opener_id] = win_getid()
endfu

fu! s:to_callable(opener) abort
  if type(a:opener) ==# s:t_func
    return a:opener
  endif

  return function('<SID>raw_opener', [a:opener])
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
