fu! esearch#middleware#paths#apply(esearch) abort
  if !has_key(a:esearch, 'paths')
    let a:esearch.paths = esearch#shell#argv([])
    return a:esearch
  endif

  if g:esearch#has#posix_shell
    if type(a:esearch.paths) ==# type('')
      let [paths, error] = esearch#shell#split(a:esearch.paths)
      if !empty(error) | throw "Can't parse paths: " . error | endif
      let a:esearch.paths = paths
    elseif type(a:esearch.paths) ==# type([]) && !empty(filter(copy(a:esearch.paths), 'type(v:val) ==# type("")'))
      " a list of plain strings: each is a single path, no shell syntax inside
      let a:esearch.paths = esearch#shell#argv(a:esearch.paths)
    endif
  endif

  return a:esearch
endfu
