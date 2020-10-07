let s:Buf = esearch#preview#buf#import()
let s:Log = esearch#log#import()
let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
     \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()

fu! esearch#preview#base_opener#import() abort
  return copy(s:BaseOpener)
endfu

let s:BaseOpener = {}

fu! s:BaseOpener.new(location, shape, emphasis, vars, opts, close_on) abort dict
  let instance = copy(self)
  let instance.location = a:location
  let instance.shape    = a:shape
  let instance.vars = a:vars
  let instance.opts     = a:opts
  let instance.close_on = a:close_on
  let instance.emphasis = a:emphasis
  return instance
endfu

fu! s:BaseOpener.shell() abort dict
  let current_win = esearch#win#stay()
  let self.buffer = s:Buf.fetch_or_create(
        \ self.location.filename, g:esearch#preview#buffers)

  try
    let g:esearch#preview#win = self.popup
          \.new(self.buffer, self.location, self.shape, self.close_on)
          \.open()
    let self.win = g:esearch#preview#win
    let self.win.upd_at = reltime()
    let self.win.cache_key = [self.opts, self.shape.align]
    call self.win.let(self.vars)
    call self.win.place_emphasis(self.emphasis)
    call self.win.reshape()
    call self.win.init_autoclose_events()
  catch
    call esearch#preview#close()
    call s:Log.error(v:exception . (g:esearch#env is 0 ? '' : v:throwpoint))
    return s:false
  finally
    noau keepj call current_win.restore()
  endtry

  return s:true
endfu
