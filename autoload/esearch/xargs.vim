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

let s:hold_revision = '1{h;d;}; /^$/{n;h;d;};'
let s:prefix_filenames_with_revision = '/./{G;s/\(.*\)\n\(.*\)/\2:\1/g;};'
let s:q = "'\\''" " single quote to pass into sed
let s:shell_quote = 's/'.s:q.'/'.s:q.'\\'.s:q.s:q.'/g; s/.*/'.s:q.'&'.s:q.'/g;'
let s:prepend_filenames_with_revisions =
      \  "|sed -n '"
      \. s:hold_revision.' '
      \. s:prefix_filenames_with_revision.' '
      \. s:shell_quote
      \. " p;'"
let s:xargs_batched = '| xargs -n127' " bigger n means higher latency, but lower overhead

fu! s:git_log(options, adapter, esearch) abort
  let pipe = join([
        \ a:adapter.bin,
        \ 'log --oneline --pretty=format:%H --name-only --diff-filter=drc --ignore-submodules=all',
        \ a:esearch.regex ==# 'literal' ? '' : '--pickaxe-regex',
        \ a:esearch.case ==# 'ignore' ?  '--regexp-ignore-case' : '',
        \ a:options,
        \ join(map(copy(a:esearch.pattern._arg), '"-S". v:val[1]')),
        \ s:prepend_filenames_with_revisions,
        \ s:xargs_batched,
        \], ' ')
  return [pipe, '']
endfu

fu! s:git_stash(options, adapter, esearch) abort
  " -S is claimed to wark the same as in git-log, but it doesn't
  let pipe = join([
        \ a:adapter.bin,
        \ 'stash list --oneline --pretty=format:%gd --name-only --diff-filter=drc',
        \ a:options,
        \ s:prepend_filenames_with_revisions,
        \ s:xargs_batched,
        \], ' ')
  return [pipe, '']
endfu
