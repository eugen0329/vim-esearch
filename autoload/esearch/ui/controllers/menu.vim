let s:List = vital#esearch#import('Data.List')
let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
      \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()

let s:down_keys   = ["\<C-j>", 'j', "\<Down>"]
let s:up_keys     = ["\<C-k>", 'k', "\<Up>"]
let s:cancel_keys = ["\<Esc>", "\<C-c>", 'q']

let s:MenuController = esearch#ui#component()

fu! s:MenuController.new(props) abort dict
  let instance        = extend(copy(self), {'props': a:props})
  let instance.cursor = 0
  let instance.menu   = a:props.menu_class.new({'cursor': instance.cursor})
  return instance
endfu

fu! s:MenuController.render() abort dict
  call self.save_options()
  try
    call self.loop()
  finally
    call self.restore_options()
  endtry
endfu

fu! s:MenuController.force_update() abort dict
  let self.menu = self.props.menu_class.new({'cursor': self.cursor})
  call esearch#ui#render(self.menu)
endfu

" inspired by nerdree menu
fu! s:MenuController.loop() abort dict
  while s:true
    redraw!
    call self.force_update()

    let key = esearch#util#getchar()
    if s:List.has(s:down_keys, key)
      call self.cursor_down()
    elseif s:List.has(s:up_keys, key)
      call self.cursor_up()
    elseif s:List.has(s:cancel_keys, key)
      return self.props.dispatch({'type': 'route', 'route': 'search_input'})
    else
      if self.menu.keypress({'key': key})
        return
      endif
    endif
  endwhile
endfu

fu! s:MenuController.save_options() abort dict
  let self.saved_winheight = winheight(0)
  let self.saved_options = esearch#let#restorable({
        \ '&cmdheight': self.menu.height,
        \ '&lazyredraw': 0,
        \ '&t_ve': '',
        \ '&showtabline': 0})
endfu

fu! s:MenuController.restore_options() abort dict
  call self.saved_options.restore()
  exe 'resize ' . self.saved_winheight
endfu

fu! s:MenuController.cursor_down() abort dict
  if self.cursor < len(self.menu.items) - 1
    let self.cursor += 1
  else
    let self.cursor = 0
  endif
endfu

fu! s:MenuController.cursor_up() abort dict
  if self.cursor > 0
    let self.cursor -= 1
  else
    let self.cursor = len(self.menu.items) - 1
  endif
endfu

fu! esearch#ui#controllers#menu#import() abort
  return esearch#ui#connect(s:MenuController)
endfu
