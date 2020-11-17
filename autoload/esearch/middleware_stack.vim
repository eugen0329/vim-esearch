fu! esearch#middleware_stack#new(list) abort
  return s:MiddlewareStack.new(a:list)
endfu

let s:MiddlewareStack = {}

fu! s:MiddlewareStack.new(list) abort dict
  return extend(copy(self), {'list': a:list})
endfu

fu! s:MiddlewareStack.insert_before(existing_middleware, Callback) abort dict
  call insert(self.list, a:Callback, s:index(self.list, a:existing_middleware))
endfu

fu! s:MiddlewareStack.insert_after(existing_middleware, Callback) abort dict
  call insert(self.list, a:Callback, s:index(self.list, a:existing_middleware) + 1)
endfu

fu! s:index(list, existing_middleware) abort
  if type(a:existing_middleware) ==# type('')
    return index(a:list, function('esearch#middleware#'.a:existing_middleware.'#apply'))
  else
    return index(a:list, a:existing_middleware)
  endif
endfu
