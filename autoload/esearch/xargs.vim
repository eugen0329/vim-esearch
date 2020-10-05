fu! esearch#xargs#git_log(...) abort
  let user_options = get(a:, 1, '')
  return {'tag': '<git-log'.(a:0 ? ':'.user_options : '').'>', 'command': function('s:git_log', [user_options])}
endfu

fu! s:git_log(user_options, adapter, esearch) abort
  let pipe = join([
        \ a:adapter.bin,
        \ 'log --oneline --format="%H"',
        \ a:adapter.textobj[a:esearch.textobj].option,
        \ a:adapter.regex[a:esearch.regex].option,
        \ (a:esearch.case ==# 'ignore' ?  '--regexp-ignore-case' : ''),
        \ a:user_options,
        \ join(map(copy(a:esearch.pattern._arg), '"-G". v:val[1]')),
        \ '| xargs'
        \], ' ')
  return [pipe, '']
endfu
