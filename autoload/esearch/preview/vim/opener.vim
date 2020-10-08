let s:Log = esearch#log#import()
let s:Buf = esearch#preview#buf#import()
let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
     \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()

fu! esearch#preview#vim#opener#import() abort
  return copy(s:VimOpener)
endfu

let s:VimOpener = esearch#preview#opener_base#import()
let s:VimOpener.popup = esearch#preview#vim#popup#import()

fu! s:VimOpener.open() abort dict
  let self.buf = s:Buf.new(self.location.filename)

  try
    call esearch#preview#close()
    let g:esearch#preview#win = self.popup
          \.new(self.buf, self.location, self.shape, self.close_on)
          \.open()
    let self.win = g:esearch#preview#win
    call self.win.let(self.vars)
    call self.win.place_emphasis(self.emphasis)
    call self.win.reshape()
    call self.win.init_autoclose_events()
  catch
    call esearch#preview#close()
    call s:Log.error(v:exception . (g:esearch#env is 0 ? '' : v:throwpoint))
    return s:false
  endtry

  return s:true
endfu

fu! s:VimOpener.open_and_enter() abort dict
  let current_win = esearch#win#stay()
  let self.buf = s:Buf.new(self.location.filename)

  if esearch#preview#is_open()
    let g:esearch#preview#win.guard = {}
  endif
  call esearch#preview#close()
  call b:esearch.reusable_buffers_manager.open(self.location.filename)

  return s:true
endfu
