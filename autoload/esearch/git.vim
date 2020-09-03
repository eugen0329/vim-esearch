 " FugitiveFind
fu! esearch#git#url(git_dir, filename) abort
  return 'fugitive://' . a:git_dir . '//' . substitute(a:filename, ':', '/', '')
endfu

fu! esearch#git#dir(cwd) abort
  if exists('*FugitiveExtractGitDir')
    return FugitiveExtractGitDir(a:cwd)
  else
    return fnamemodify(esearch#util#find_up(a:cwd, ['.git/HEAD']), ':h')
  endif
endfu
