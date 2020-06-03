fu! esearch#middleware#paths#apply(esearch) abort
  if !has_key(a:esearch, 'paths')
    let a:esearch.paths = esearch#shell#argv([])
    return a:esearch
  endif

  if g:esearch#has#posix_shell
    if type(a:esearch.paths) ==# type('')
      let [paths, error] = esearch#shell#split(a:esearch.paths)
    
      if !empty(error)
        throw "Can't parse paths: " . error
      endif
    
      let a:esearch.paths = paths
    elseif type(a:esearch.paths) ==# type([])
      " TODO add a validation
    else
      throw 'Unknown paths type: ' . string(a:esearch.paths) . ' (string expected)'
    endif
  endif

  return a:esearch
endfu
