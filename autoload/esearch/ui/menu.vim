" Rewrited nerdtree menu

fu! esearch#ui#menu#new(menuItems, prompt)
  return s:MenuController.new(a:menuItems, a:prompt)
endfu

fu! esearch#ui#menu#item(options)
  return s:MenuItem.create(a:options)
endfu

let s:MenuController = {}

fu! s:MenuController.new(menuItems, prompt)
  let newMenuController =  copy(self)
  let newMenuController.prompt  =  a:prompt
  if a:menuItems[0].is_separator()
    let newMenuController.menuItems = a:menuItems[1:-1]
  else
    let newMenuController.menuItems = a:menuItems
  endif
  return newMenuController
endfu

fu! s:MenuController.is_collapsed()
  " TODO
  return 0
endfu

fu! s:MenuController.start()
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

  if self.selection !=# -1
    let l:m = self.current_item()
    call l:m.execute()
  endif
endfu

fu! s:MenuController.render()
  if self.is_collapsed()
    throw 'not implemented yet'
    " let selection = self.menuItems[self.selection].text
    " let keyword = matchstr(selection, '[^ ]*([^ ]*')

    " let shortcuts = map(copy(self.menuItems), "v:val['shortcut']")
    " let shortcuts[self.selection] = ' ' . keyword . ' '

    " echo 'Menu: [' . join(shortcuts, ',') . '] (' . navHelp . ' or shortcut): '
  else
    echo self.prompt

    for i in range(0, len(self.menuItems)-1)
      if self.selection ==# i
        echo '> ' . self.menuItems[i].text
      else
        echo '  ' . self.menuItems[i].text
      endif
    endfor
  endif
endfu
fu! s:MenuController.current_item()
  return self.menuItems[self.selection]
endfu

fu! s:MenuController.handle_keypress(key)
  if a:key ==# "\<C-j>" || a:key ==# "j"
    call self.cursor_down()
  elseif a:key ==# "\<C-k>" || a:key ==# "k"
    call self.cursor_up()
  elseif a:key ==# nr2char(27) "escape
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

fu! s:MenuController.all_indexes_for(shortcut)
  let toReturn = []

  for i in range(0, len(self.menuItems)-1)
    if s:pressed(self.menuItems[i], a:shortcut)
      call add(toReturn, i)
    endif
  endfor

  return toReturn
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

fu! s:MenuController.next_index_for(shortcut)
  for i in range(self.selection+1, len(self.menuItems)-1)
    if s:pressed(self.menuItems[i], a:shortcut)
      return i
    endif
  endfor

  for i in range(0, self.selection)
    if s:pressed(self.menuItems[i], a:shortcut)
      return i
    endif
  endfor

  return -1
endfu

fu! s:MenuController.set_cmdline_height()
  if self.is_collapsed()
    let &cmdheight = 1
  else
    let &cmdheight = len(self.menuItems) + 1
  endif
endfu

fu! s:MenuController.save_options()
  let self._oldLazyredraw = &lazyredraw
  let self._oldCmdheight = &cmdheight
  set nolazyredraw
  call self.set_cmdline_height()
endfu

fu! s:MenuController.restore_options()
  let &cmdheight = self._oldCmdheight
  let &lazyredraw = self._oldLazyredraw
endfu

fu! s:MenuController.cursor_down()
  let done = 0
  while !done
    if self.selection < len(self.menuItems)-1
      let self.selection += 1
    else
      let self.selection = 0
    endif

    if !self.current_item().is_separator()
      let done = 1
    endif
  endwhile
endfu

fu! s:MenuController.cursor_up()
  let done = 0
  while !done
    if self.selection > 0
      let self.selection -= 1
    else
      let self.selection = len(self.menuItems)-1
    endif

    if !self.current_item().is_separator()
      let done = 1
    endif
  endwhile
endfu

let s:MenuItem = {}

fu! s:MenuItem.create(options)
  let newMenuItem = copy(self)

  let newMenuItem.text = a:options['text']
  let newMenuItem.shortcut = a:options['shortcut']
  let newMenuItem.children = []

  let newMenuItem.isActiveCallback = -1
  if has_key(a:options, 'isActiveCallback')
    let newMenuItem.isActiveCallback = a:options['isActiveCallback']
  endif

  let newMenuItem.callback = -1
  if has_key(a:options, 'callback')
    let newMenuItem.callback = a:options['callback']
  endif

  return newMenuItem
endfu

fu! s:MenuItem.create_separator(options)
  let standard_options = { 'text': '--------------------',
        \ 'shortcut': -1,
        \ 'callback': -1 }
  let options = extend(a:options, standard_options, 'force')

  return s:MenuItem.create(options)
endfu

fu! s:MenuItem.create_submenu(options)
  let standard_options = { 'callback': -1 }
  let options = extend(a:options, standard_options, 'force')

  return s:MenuItem.create(options)
endfu

fu! s:MenuItem.is_enabled()
  if self.isActiveCallback != -1
    return type(self.isActiveCallback) == type(function('tr')) ? self.isActiveCallback() : {self.isActiveCallback}()
  endif
  return 1
endfu

fu! s:MenuItem.execute()
  if len(self.children)
    let mc = esearch#ui#menu#new(self.children, '')
    call mc.start()
  else
    if self.callback != -1
      if type(self.callback) == type(function('tr'))
        call self.callback()
      else
        call {self.callback}()
      endif
    endif
  endif
endfu

fu! s:MenuItem.is_separator()
  return self.callback == -1 && self.children == []
endfu

fu! s:MenuItem.is_submenu()
  return self.callback == -1 && !empty(self.children)
endfu
