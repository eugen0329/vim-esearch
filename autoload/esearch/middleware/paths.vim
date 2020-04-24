fu! esearch#middleware#paths#apply(esearch) abort
  if !has_key(a:esearch, 'paths')
    let a:esearch.paths = []
    return a:esearch
  endif

  if type(a:esearch.paths) ==# type('')
    let [paths, error] = esearch#shell#split(a:esearch.paths)

    if !empty(error)
      throw "Can't parse paths: " . error
    endif

    let a:esearch.paths = paths
  elseif type(a:esearch.paths) ==# type([])
    " TODO add a validation or smth
  else
    throw 'Unknown paths type: ' . string(a:esearch.paths) . ' (string expected)'
  endif

  return a:esearch
endfu
