aug esearch_git
  au!
  au BufReadCmd esearchgit://* cal esearch#git#read_cmd(expand('<amatch>'))
aug END

fu! esearch#git#url(dir, filename) abort
  return 'esearchgit://' . a:dir . '//' . a:filename
endfu

fu! esearch#git#dir(cwd) abort
  return fnamemodify(esearch#util#find_up(a:cwd, ['.git/HEAD']), ':h')
endfu

fu! esearch#git#read_cmd(path) abort
  setlocal noswapfile endofline bufhidden=delete
  call esearch#util#doautocmd('BufReadPre')
  let [dir, filename] = matchlist(a:path, 'esearchgit://\(.\{-}\)//\(\x\{40\}:.\+\)')[1:2]
  exe '0read ++edit !git -C' shellescape(dir, 1) 'cat-file -p' shellescape(filename, 1)
  keepjumps silent $delete_
  let g:asd = [v:shell_error, filename]
  setlocal nomodifiable nomodified readonly
  call esearch#util#doautocmd('BufReadPost')
endfu
