fu! esearch#preview#buf#import() abort
  return s:PreviewBuffer
endfu

let s:PreviewBuffer = {'kind': 'regular', 'swapname': ''}

fu! s:PreviewBuffer.new(filename, ...) abort dict
  let instance = copy(self)
  let instance.filename = a:filename

  let reuse_existing = get(a:, 1, 1)
  if reuse_existing && bufexists(a:filename)
    let instance.id = esearch#buf#find(a:filename)
  else
    let instance.id = bufadd(a:filename)
  endif

  return instance
endfu

fu! s:PreviewBuffer.fetch_or_create(filename, cache) abort dict
  if has_key(a:cache, a:filename)
    let instance = a:cache[a:filename]
    if instance.is_valid()
      return instance
    endif
    call remove(a:cache, a:filename)
  endif

  let instance = self.new(a:filename)
  let a:cache[a:filename] = instance

  return instance
endfu

fu! s:PreviewBuffer.edit_allowing_swap_prompt() abort dict
  if exists('#esearch_preview_autoclose')
    au! esearch_preview_autoclose
  endif

  try
    exe 'edit ' . fnameescape(self.filename)
  catch /E325:/ " swapexists exception, will be handled by a user
  catch /Vim:Interrupt/ " Throwed on cancelling swap
  endtry
  " When (Q)uit or (A)bort are pressed - vim unloads the current buffer as it
  " was with an existing swap
  if empty(bufname('%')) && !bufloaded('%')
    exe self.id . 'bwipeout'
    return 0
  endif

  let current_buffer_id = bufnr('%')
  if current_buffer_id != self.id && bufexists(self.id) && empty(bufname(self.id)) && !bufloaded(self.id)
    exe self.id . 'bwipeout'
  endif
  let self.id = current_buffer_id

  return 1
endfu

fu! s:PreviewBuffer.is_valid() abort dict
  return self.id >= 0 && bufexists(self.id)
endfu
