let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
     \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()

fu! esearch#preview#base_popup#import() abort
  return copy(s:PopupBase)
endfu

let s:PopupBase = {'guard': s:null, 'id': s:null, 'emphasis': s:null, 'variables': s:null}

fu! s:PopupBase.new(buffer, location, shape, close_on) abort dict
  let instance = copy(self)

  let instance.buffer   = a:buffer
  let instance.location = a:location
  let instance.shape    = a:shape
  let instance.close_on = a:close_on
  let instance.emphasis = []

  return instance
endfu

fu! s:PopupBase.let(variables) abort dict
  let self.variables = a:variables
  let self.guard = esearch#let#bufwin_restorable(self.buffer.id, self.id, a:variables)
endfu

fu! s:PopupBase.init_autoclose_events() abort dict
  let autocommands = join(self.close_on, ',')

  aug esearch_preview_autoclose
    au!
    exe 'au ' . autocommands . ' * ++once call esearch#preview#close()'
    exe 'au ' . g:esearch#preview#reset_on . ' * ++once call esearch#preview#reset()'
    au User esearch_open_pre ++once call esearch#preview#close()
    if exists('##TabNewEntered')
      " Prevent options inheritance
      au TabNewEntered * ++once call g:esearch#preview#last.win.guard.new(g:esearch#preview#last.buffer.id, win_getid()).restore()
    endif

    " We cannot close the preview when entering cmdwin, so the only option is to
    " reinitialize the events.
    au CmdwinLeave * ++once call g:esearch#preview#win.init_autoclose_events()
  aug END
endfu

fu! s:PopupBase.place_emphasis(emphasis) abort dict
  let self.emphasis = []

  for e in a:emphasis
    call add(self.emphasis, e.new(self.id, self.buffer.id, self.location.line).place())
  endfor
endfu

fu! s:PopupBase.unplace_emphasis() abort dict
  if !empty(self.emphasis)
    call map(self.emphasis, 'v:val.unplace()')
    let self.emphasis = s:null
  endif
endfu

