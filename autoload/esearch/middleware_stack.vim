fu! esearch#middleware_stack#new(list) abort
  return s:MiddlewareStack.new(a:list)
endfu

let s:MiddlewareStack = {}

fu! s:MiddlewareStack.new(list) abort dict
  return extend(copy(self), {'list': a:list})
endfu

fu! s:MiddlewareStack.insert_before(existing_name, Callback) abort dict
  call insert(self.list, a:Callback, index(self.list, function('esearch#middleware#'.a:existing_name.'#apply')))
endfu

fu! s:MiddlewareStack.insert_after(existing_name, Callback) abort dict
  call insert(self.list, a:Callback, index(self.list, function('esearch#middleware#'.a:existing_name.'#apply'))+1)
endfu
