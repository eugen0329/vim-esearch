let s:Filepath = vital#esearch#import('System.Filepath')

fu! esearch#xargs#git_log(...) abort
  let options = get(a:, 1, '')
  return {
        \ 'repr': function('s:repr', ['git-log']),
        \ 'command': function('s:git_log'),
        \ 'options': get(a:, 1, ''),
        \ 'adapters': ['git'],
        \ 'pathspec': get(a:, 2, esearch#shell#argv([])),
        \}
endfu

fu! esearch#xargs#git_stash(...) abort
  return {
        \ 'repr': function('s:repr', ['git-stash']),
        \ 'command': function('s:git_stash'),
        \ 'options': get(a:, 1, ''),
        \ 'adapters': ['git'],
        \ 'pathspec': get(a:, 2, esearch#shell#argv([])),
        \}
endfu

fu! s:repr(name, ...) abort dict " python __repr__-like method
  return '<'
        \ . a:name
        \ . (empty(self.options) ? '' : ' ' . self.options)
        \ . (empty(self.pathspec) ? '' : ' ' . esearch#shell#join(self.pathspec))
        \ . '>'
endfu

let s:hold_revision = '1{h;d;}; /^$/{n;h;d;};'
let s:prefix_filenames_with_revision = '/./{G;s/(.*)\n(.*)/\2:\1/g;};'
let s:q = "'\\''" " single quote to pass into sed
let s:shell_quote = 's/'.s:q.'/'.s:q.'\\'.s:q.s:q.'/g; s/.*/'.s:q.'&'.s:q.'/g;'
let s:prepend_filenames_with_revisions_fmt =
      \  "|sed -nE '"
      \. s:hold_revision.' '
      \. s:prefix_filenames_with_revision.' '
      \. '%s '
      \. s:shell_quote
      \. " p;'"
let s:xargs_batched = '| xargs -n127' " bigger n means higher latency, but lower overhead
let s:prepend_filenames_with_revisions = printf(s:prepend_filenames_with_revisions_fmt, '')

fu! s:git_log(adapter, esearch) abort dict
  let pipe = join([
        \ a:adapter.bin,
        \ 'log --oneline --pretty=format:%H --name-only --diff-filter=drc --ignore-submodules=all',
        \ a:esearch.regex ==# 'literal' ? '' : '--pickaxe-regex',
        \ a:esearch.case ==# 'ignore' ?  '--regexp-ignore-case' : '',
        \ self.options,
        \ join(map(copy(a:esearch.pattern._arg), '"-S". v:val[1]')),
        \ '--',
        \ esearch#shell#join_pathspec(self.pathspec),
        \ s:prepend_filenames_with_revisions,
        \ s:xargs_batched,
        \], ' ')
  return [pipe, '']
endfu

fu! s:git_stash(adapter, esearch) abort dict
  if empty(self.pathspec) || !g:esearch#has#posix_shell
    let filter_paths = ''
  else
    let relative_paths = filter(copy(self.pathspec), 's:Filepath.is_relative(v:val.str)')
    if empty(relative_paths)
      let filter_paths = ''
    else
      " https://www.gnu.org/software/sed/manual/html_node/Regular-Expressions.html
      " https://www.gnu.org/software/sed/manual/html_node/BRE-vs-ERE.html
      let filter_paths = join(map(relative_paths, "escape(v:val.str, '/?+{}|()*.^[]$\')"), '|')
      let filter_paths = '/^stash@[{][[:digit:]]+[}]:(' . filter_paths . ')/!d;'
    endif
  endif

  " -S is claimed to work the same as in git-log, but it doesn't
  let pipe = join([
        \ a:adapter.bin,
        \ 'stash list --oneline --pretty=format:%gd --name-only --diff-filter=drc',
        \ self.options,
        \ printf(s:prepend_filenames_with_revisions_fmt, filter_paths),
        \ s:xargs_batched,
        \], ' ')
  return [pipe, '']
endfu
