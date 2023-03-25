let g:esearch#ui#runtime#statusline = 0
let s:contexts = []
let s:msgs = []
let s:middleware_cache = esearch#cache#expiring#new({'max_age': 120, 'size': 1024})
let s:redraw = g:esearch#has#nvim ? "echo ''|redraw"  : 'redraw!'
let s:force_redraw = g:esearch#has#nvim ? "echo ''|mode"  : 'redraw!'

if !exists('g:esearch#ui#runtime#clear_selection_chars')
  let g:esearch#ui#runtime#clear_selection_chars = []
endif
let g:esearch#ui#runtime#clear_selection_chars += [
      \ "\<Del>",
      \ "\<Bs>",
      \ "\<C-w>",
      \ "\<C-h>",
      \ "\<C-u>",
      \ ]
if g:esearch#has#meta_key
  let g:esearch#ui#runtime#clear_selection_chars += [
        \ "\<M-d>",
        \ "\<M-BS>",
        \ "\<M-C-h>",
        \ ]
endif
if !exists('g:esearch#ui#runtime#start_search_chars')
  let g:esearch#ui#runtime#start_search_chars = [
        \ "\<Enter>",
        \ ]
endif
if !exists('g:esearch#ui#runtime#cancel_selection_and_retype_chars')
  let g:esearch#ui#runtime#cancel_selection_and_retype_chars = [
        \ "\<Left>",
        \ "\<Right>",
        \ "\<Up>",
        \ "\<Down>",
        \ ]
endif
if !exists('g:esearch#ui#runtime#cancel_selection_chars')
  let g:esearch#ui#runtime#cancel_selection_chars = [
        \ "\<Esc>",
        \ "\<C-c>",
        \ ]
endif
if !exists('g:esearch#ui#runtime#insert_register_content_chars')
  let g:esearch#ui#runtime#insert_register_content_chars = [
        \ "\<C-r>",
        \ ]
endif

fu! esearch#ui#runtime#loop(main, ...) abort
  let g:esearch#ui#runtime#statusline = 0
  let s:main = a:main
  let [s:model, cmd] = call(s:main.init, a:000)
  call s:handle(cmd)

  while 1
    try
      call s:handle(esearch#ui#runtime#view())

      while !empty(s:msgs)
        call esearch#ui#runtime#update(remove(s:msgs, 0))
      endw

    catch /^QuitRuntime\|Vim:Interrupt$/
      while !empty(s:contexts) | call remove(s:contexts, 0).__exit__() | endw
      return s:model
    catch //
      while !empty(s:contexts) | call remove(s:contexts, 0).__exit__() | endw
      echoerr v:exception . v:throwpoint
    endtry
  endwhile
endfu

fu! esearch#ui#runtime#view() abort
  let [tokens, cmd] = s:main.view(s:model)
  exe s:redraw
  call esearch#ui#render#echo(tokens)
  return cmd
endfu

fu! esearch#ui#runtime#onpress(msg) abort
  let s:cmdline = [getcmdline(), getcmdpos()]
  let s:pending_msg = a:msg
  return "\<cr>"
endfu

      " \ 'esearch#middleware#id#apply':           0,
let s:required_middleware = {
      \ 'esearch#middleware#deprecations#apply': 0,
      \ 'esearch#middleware#adapter#apply':      0,
      \ 'esearch#middleware#cwd#apply':          0,
      \ 'esearch#middleware#paths#apply':        0,
      \ 'esearch#middleware#globs#apply':        0,
      \ 'esearch#middleware#filemanager#apply':  0,
      \ 'esearch#middleware#prewarm#apply':      0,
      \ 'esearch#middleware#input#apply':        0,
      \ 'esearch#middleware#map#apply':          0,
      \ 'esearch#middleware#remember#apply':     0,
      \ 'esearch#middleware#warnings#apply':     0,
      \}

fu! esearch#ui#runtime#update(msg) abort
  let [s:model, cmd] = s:main.update(a:msg, s:model)
  call s:handle(cmd)
endfu

let s:timer = -1
fu! s:force_exec(esearch, timeout, ...) abort
  call timer_stop(s:timer)
  if a:timeout > 0
    let s:timer = timer_start(a:timeout, function('s:force_exec', [a:esearch, 0]))
    return
  endif

  let middleware = s:middleware_cache.get(a:esearch.id)
  if empty(middleware)
    let middleware = esearch#middleware_stack#new(
          \ filter(copy(a:esearch.middleware.list), 'get(s:required_middleware, get(v:val, "name"), 1)'))
    call s:middleware_cache.set(a:esearch.id, middleware)
  endif

  call esearch#ui#runtime#update(['LiveExecuted', esearch#init(extend(a:esearch, {
        \ 'early_finish_wait': min([50, a:esearch.early_finish_wait]),
        \ 'force_exec': 1,
        \ 'name': '[esearch]',
        \ 'middleware': middleware,
        \}))])
endfu

fu! s:handle(cmd) abort
  if a:cmd[0] ==# 'cmd.none'
  elseif a:cmd[0] ==# 'cmd.force_exec'
    call s:force_exec(a:cmd[1], get(a:cmd, 2))
  elseif a:cmd[0] ==# 'cmd.shellpreview'
    " TODO extract
    call esearch#preview#shell(a:cmd[1], {
    \  'relative': 'editor',
    \  'align':    'bottom',
    \  'height':    0.3,
    \  'cwd':       a:cmd[2].cwd,
    \  'let':      {'&number': 0, '&filetype': 'esearch_glob'},
    \  'on_finish':  {bufnr, request, _ ->
    \    appendbufline(bufnr, 0, len(request.data).' matched file'.(len(request.data) == 1 ? '' : 's'))
    \  }
    \})
  elseif a:cmd[0] ==# 'cmd.batch'
    for cmd in a:cmd[1]
      call s:handle(cmd)
    endfor
  elseif a:cmd[0] ==# 'cmd.place'
    call add(s:msgs, ['Place'] + a:cmd[1:])
  elseif a:cmd[0] ==# 'cmd.emit'
    call add(s:msgs, a:cmd[1])
  elseif a:cmd[0] ==# 'cmd.cursor'
    call add(s:msgs, a:cmd[1:])
  elseif a:cmd[0] ==# 'cmd.force_redraw'
    exe s:force_redraw
  elseif a:cmd[0] ==# 'cmd.quit'
    throw 'QuitRuntime'
  elseif a:cmd[0] ==# 'cmd.context'
    let s:contexts += [a:cmd[1]]
    call a:cmd[1].__enter__()
  elseif a:cmd[0] ==# 'cmd.route'
    while !empty(s:msgs) | call esearch#ui#runtime#update(remove(s:msgs, 0)) | endw
    while !empty(s:contexts) | call remove(s:contexts, 0).__exit__() | endw
    call add(s:msgs, ['Route', a:cmd[1]])
  elseif a:cmd[0] ==# 'cmd.getchar'
    call add(s:msgs, [a:cmd[1], esearch#util#getchar()])
  elseif a:cmd[0] ==# 'cmd.getline'
    call s:getline(a:cmd)
  elseif a:cmd[0] ==# 'cmd.statusline'
    let statusline_string = esearch#ui#render#statusline_string(a:cmd[1])
    let g:esearch#ui#runtime#statusline = statusline_string
    let &l:statusline = ''
    let &g:statusline = statusline_string
    redrawstatus!
  else
    throw 'unexpected command '.string(a:cmd)
  endif
endfu

fu! s:selection(prompt, text) abort
  let text =  a:text

  call esearch#ui#render#echo(a:prompt + [[substitute(text, '\n', ' ', 'g'), 'Visual']])

  let retype = ''
  let submitted = 0
  let key = esearch#util#getchar()

  if key ==# "\<c-r>"
    let key .= esearch#util#getchar()
    let retype = key

    " From :h c_CTRL-R
    if key =~# '^[0-9a-z"%#:\-=.]$'
      let text = ''
    endif
  elseif index(g:esearch#ui#runtime#clear_selection_chars, key) >= 0
    let text = ''
    let retype = key
  elseif index(g:esearch#ui#runtime#start_search_chars, key) >= 0
    let submitted = 1
  elseif index(g:esearch#ui#runtime#cancel_selection_and_retype_chars, key) >= 0
    let retype = key
  elseif index(g:esearch#ui#runtime#cancel_selection_chars, key) >= 0
    " no-op
  elseif !empty(esearch#keymap#escape_kind(key))
    let retype = key
  elseif mapcheck(key, 'c') !=# ''
    let retype = key
  else
    let text = key
  endif

  return [text, submitted, retype, key]
endfu

fu! esearch#ui#runtime#onpop(key) abort
  let s:cmdline = [getcmdline(), getcmdpos()]
  if !empty(s:cmdline[0]) | return a:key | endif
  let s:pending_pop = 1
  return "\<cr>"
endfu

fu! s:getline(cmd) abort
  let opts = extend({'multiple': 0, 'completion': 'file'}, a:cmd[1])

  if opts.preselect && !empty(opts.cmdline[0])
    let [opts.cmdline[0], submitted, retype, key] = s:selection(opts.prompt, opts.cmdline[0])
    exe s:redraw

    if submitted
      return add(s:msgs, [opts.onsubmit, opts.cmdline[0], -1])
    endif

    call add(s:msgs, [opts.onunselect, key])
  endif

  let keymaps = copy(opts.keymaps)
  if opts.multiple
    cnoremap <expr><plug>(esearch-bs)   esearch#ui#runtime#onpop("\<bs>")
    cnoremap <expr><plug>(esearch-c-w)  esearch#ui#runtime#onpop("\<c-w>")
    cnoremap <expr><plug>(esearch-c-h)  esearch#ui#runtime#onpop("\<c-h>")
    cnoremap <expr><plug>(esearch-c-u)  esearch#ui#runtime#onpop("\<c-u>")
    let keymaps += [
          \ ['c', '<bs>',  '<plug>(esearch-bs)',  {'nowait': 1}],
          \ ['c', '<c-w>', '<plug>(esearch-c-w)', {'nowait': 1}],
          \ ['c', '<c-h>', '<plug>(esearch-c-h)', {'nowait': 1}],
          \ ['c', '<c-u>', '<plug>(esearch-c-u)', {'nowait': 1}],
          \]
  endif
  let g:esearch#ui#runtime#prompt = esearch#ui#render#string(opts.prompt)

  let original_keymaps = esearch#keymap#restorable(keymaps)
  if !empty(get(l:, 'retype')) | call feedkeys(retype) | endif
  let [s:cmdline, s:pending_msg, s:pending_pop] = [['', -1], 0, 0]
  try
    let text = esearch#ui#util#with_cmdpos(opts.cmdline)
    let g:esearch#ui#runtime#input_prefilled = !empty(text)
    if g:esearch#has#input_highlight && has_key(opts, 'highlight')
      call esearch#ui#highlight#init(opts.highlight[1])
      let args = {
            \ 'prompt': g:esearch#ui#runtime#prompt,
            \ 'default': text,
            \ 'completion': opts.completion,
            \ 'highlight': opts.highlight[0],
            \}
      let text = input(args)
    else
      let text = input(g:esearch#ui#runtime#prompt, text, opts.completion)
    endif

    if !empty(s:pending_msg)
      call add(s:msgs, [opts.onset] + s:cmdline)
      return add(s:msgs, s:pending_msg)
    elseif !empty(s:pending_pop)
      call add(s:msgs, [opts.onset] + s:cmdline)
      return add(s:msgs, [opts.onpop] + s:cmdline)
    else
      return add(s:msgs, [opts.onsubmit, text, s:cmdline[1]])
    endif
  catch /^Vim:Interrupt$/
    call add(s:msgs, [opts.oninterrupt, '', -1])
  finally
    call original_keymaps.restore()
  endtry
endfu
