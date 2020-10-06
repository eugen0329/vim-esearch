fu! esearch#xargs#git_log(...) abort
  let options = get(a:, 1, '')
  return {
        \ 'tag': '<git-log'.(a:0 ? ':'.options : '').'>',
        \ 'command': function('s:git_log', [options]),
        \ 'adapters': ['git'],
        \}
endfu

fu! esearch#xargs#git_stash(...) abort
  let options = get(a:, 1, '')
  return {
        \ 'tag': '<git-stash'.(a:0 ? ':'.options : '').'>',
        \ 'command': function('s:git_stash', [options]),
        \ 'adapters': ['git'],
        \}
endfu

let s:prepend_filenames_with_revisions = "| awk '/^$/{r=0} r{print r\":\"$0} !r{r=$0}'"

fu! s:git_log(options, adapter, esearch) abort
  let pipe = join([
        \ a:adapter.bin,
        \ 'log --oneline --pretty=format:%H --name-only --diff-filter=drc',
        \ a:esearch.regex ==# 'literal' ? '' : '--pickaxe-regex',
        \ a:esearch.case ==# 'ignore' ?  '--regexp-ignore-case' : '',
        \ a:options,
        \ join(map(copy(a:esearch.pattern._arg), '"-S". v:val[1]')),
        \ s:prepend_filenames_with_revisions,
        \ '| xargs -L1 -I@',
        \], ' ')
return [pipe, fnameescape('@')]
endfu

fu! s:git_stash(options, adapter, esearch) abort
  " -S is claimed to wark the same as in git-log, but it doesn't
  let pipe = join([
        \ a:adapter.bin,
        \ 'stash list --oneline --pretty=format:%gd --name-only --diff-filter=drc',
        \ a:options,
        \ s:prepend_filenames_with_revisions,
        \ '| xargs -L1 -I@',
        \], ' ')
  return [pipe, fnameescape('@')]
endfu
