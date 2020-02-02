" Rewrited nerdtree menu

fu! esearch#ui#menu#new(menu_items, prompt) abort
  return s:MenuController.new(a:menu_items, a:prompt)
endfu

fu! esearch#ui#menu#item(options) abort
  return s:MenuItem.create(a:options)
endfu

let s:MenuController = {}

fu! s:MenuController.new(menu_items, prompt) abort
  let new_menu_controller =  copy(self)
  let new_menu_controller.prompt  =  a:prompt
  if a:menu_items[0].is_separator()
    let new_menu_controller.menu_items = a:menu_items[1:-1]
  else
    let new_menu_controller.menu_items = a:menu_items
  endif

  return new_menu_controller
endfu

fu! s:MenuController.is_collapsed() abort
  " TODO
  return 0
endfu

fu! s:MenuController.start() abort
  call self.save_options()

  try
    let self.selection = 0
    let l:done = 0

    while !l:done
      if has('nvim')
        mode
      else
        redraw!
      endif
      call self.render()

      let l:key = nr2char(getchar())
      let l:done = self.handle_keypress(l:key)
    endwhile
  finally
    call self.restore_options()

    " Redraw when Ctrl-C or Esc is received.
    if !l:done || self.selection ==# -1
      redraw!
    endif
  endtry

  call esearch#log#debug('after all'.g:escmdline, '/tmp/esearch_log.txt')

  if self.selection !=# -1
    call esearch#log#debug('-1 '.g:escmdline, '/tmp/esearch_log.txt')
    call esearch#log#debug('s4 '.g:escmdline, '/tmp/esearch_log.txt')
    let l:m = self.current_item()
    call esearch#log#debug('s5 '.g:escmdline, '/tmp/esearch_log.txt')
    call l:m.execute()
    call esearch#log#debug('s6 '.g:escmdline, '/tmp/esearch_log.txt')
  endif
  call esearch#log#debug('after after all'.g:escmdline, '/tmp/esearch_log.txt')
endfu

fu! s:MenuController.render() abort
  if self.is_collapsed()
    throw 'not implemented yet'
    " let selection = self.menu_items[self.selection].text
    " let keyword = matchstr(selection, '[^ ]*([^ ]*')

    " let shortcuts = map(copy(self.menu_items), "v:val['shortcut']")
    " let shortcuts[self.selection] = ' ' . keyword . ' '

    " echo 'Menu: [' . join(shortcuts, ',') . '] (' . navHelp . ' or shortcut): '
  else
    call esearch#util#echo(self.prompt)

    for i in range(0, len(self.menu_items)-1)
      if self.selection ==# i
        call esearch#util#echo('> ' . self.menu_items[i].text)
      else
        call esearch#util#echo('  ' . self.menu_items[i].text)
      endif
    endfor
  endif
endfu
fu! s:MenuController.current_item() abort
  return self.menu_items[self.selection]
endfu

fu! s:MenuController.handle_keypress(key)

  call esearch#log#debug('menu controller handle_keypress '.a:key .' '.g:escmdline, '/tmp/esearch_log.txt')
  if a:key ==# "\<C-j>" || a:key ==# 'j'
    call self.cursor_down()
  elseif a:key ==# "\<C-k>" || a:key ==# 'k'
    call self.cursor_up()
  elseif a:key ==# "\<Esc>" "escape
    call esearch#log#debug('escape pressed', '/tmp/esearch_log.txt')
    let self.selection = -1
    return 1
  elseif a:key ==# "\r" "enter and ctrl-j
    return 1
    " elseif a:key ==# "\r" || a:key ==# "\n" "enter and ctrl-j
    "     return 1
  else
    let index = self.next_index_for(a:key)
    if index !=# -1
      let self.selection = index
      if len(self.all_indexes_for(a:key)) ==# 1
        return 1
      endif
    endif
  endif

  return 0
endfu

fu! s:MenuController.all_indexes_for(shortcut) abort
  let to_return = []

  for i in range(0, len(self.menu_items)-1)
    if s:pressed(self.menu_items[i], a:shortcut)
      call add(to_return, i)
    endif
  endfor

  return to_return
endfu

fu! s:pressed(item, shortcut) abort
  if type(a:item.shortcut) ==# type([])
    for s in a:item.shortcut
      if s ==# a:shortcut
        return 1
      endif
    endfor
  else
    return a:item.shortcut ==# a:shortcut
  endif

  return 0
endfu

fu! s:MenuController.next_index_for(shortcut) abort
  for i in range(self.selection+1, len(self.menu_items)-1)
    if s:pressed(self.menu_items[i], a:shortcut)
      return i
    endif
  endfor

  for i in range(0, self.selection)
    if s:pressed(self.menu_items[i], a:shortcut)
      return i
    endif
  endfor

  return -1
endfu

fu! s:MenuController.set_cmdline_height() abort
  if self.is_collapsed()
    let &cmdheight = 1
  else
    let &cmdheight = len(self.menu_items) + 1
  endif
endfu

fu! s:MenuController.save_options() abort
  let self.old_lazy_redraw = &lazyredraw
  let self.old_cmd_height = &cmdheight
  let self.old_showtabline = &showtabline " to reduce blinks
  set nolazyredraw
  set showtabline=0
  call self.set_cmdline_height()
endfu

fu! s:MenuController.restore_options() abort
  let &cmdheight = self.old_cmd_height
  let &lazyredraw = self.old_lazy_redraw
  let &showtabline = self.old_showtabline
endfu

fu! s:MenuController.cursor_down() abort
  let done = 0
  while !done
    if self.selection < len(self.menu_items)-1
      let self.selection += 1
    else
      let self.selection = 0
    endif

    if !self.current_item().is_separator()
      let done = 1
    endif
  endwhile
endfu

fu! s:MenuController.cursor_up() abort
  let done = 0
  while !done
    if self.selection > 0
      let self.selection -= 1
    else
      let self.selection = len(self.menu_items)-1
    endif

    if !self.current_item().is_separator()
      let done = 1
    endif
  endwhile
endfu

let s:MenuItem = {}

fu! s:MenuItem.create(options) abort
  let new_menu_item = copy(self)

  let new_menu_item.text = a:options['text']
  let new_menu_item.shortcut = a:options['shortcut']
  let new_menu_item.children = []

  let new_menu_item.is_active_callback = -1
  if has_key(a:options, 'is_active_callback')
    let new_menu_item.is_active_callback = a:options['is_active_callback']
  endif

  let new_menu_item.callback = -1
  if has_key(a:options, 'callback')
    let new_menu_item.callback = a:options['callback']
  endif

  return new_menu_item
endfu

fu! s:MenuItem.create_separator(options) abort
  let standard_options = { 'text': '--------------------',
        \ 'shortcut': -1,
        \ 'callback': -1 }
  let options = extend(a:options, standard_options, 'force')

  return s:MenuItem.create(options)
endfu

fu! s:MenuItem.create_submenu(options) abort
  let standard_options = { 'callback': -1 }
  let options = extend(a:options, standard_options, 'force')

  return s:MenuItem.create(options)
endfu

fu! s:MenuItem.is_enabled() abort
  if self.is_active_callback != -1
    return type(self.is_active_callback) == type(function('tr')) ? self.is_active_callback() : {self.is_active_callback}()
  endif
  return 1
endfu

fu! s:MenuItem.execute() abort
  if len(self.children)
    call esearch#log#debug('s7 '.g:escmdline, '/tmp/esearch_log.txt')
    let mc = esearch#ui#menu#new(self.children, '')
    call mc.start()
  else
    call esearch#log#debug('s8 '.g:escmdline, '/tmp/esearch_log.txt')
    if self.callback != -1
      call esearch#log#debug('s9 '.g:escmdline, '/tmp/esearch_log.txt')
      if type(self.callback) == type(function('tr'))
        call self.callback()
      else
        call {self.callback}()
      endif
      call esearch#log#debug('s10 '.g:escmdline, '/tmp/esearch_log.txt')
    endif
  endif
endfu

fu! s:MenuItem.is_separator() abort
  return self.callback == -1 && self.children == []
endfu

fu! s:MenuItem.is_submenu() abort
  return self.callback == -1 && !empty(self.children)
endfu
