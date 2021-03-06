let s:Dict     = vital#esearch#import('Data.Dict')
let s:List     = vital#esearch#import('Data.List')
let s:Filepath = vital#esearch#import('System.Filepath')

let s:metachars = '()[]{}?*+@!$^|'
let s:is_metachar = s:Dict.make_index(split(s:metachars, '\zs'))
let g:esearch#shell#metachar_re = '['.escape(s:metachars, ']').']'
let s:matachar_re = g:esearch#shell#metachar_re
let s:eval_re = '`[^`]\{-}`'
let s:regular = '\%(\\.\|[^''" `\\'.escape(s:metachars, ']').']\)\+'
let s:sq_re = '''\%([^'']\+\|''''\)*'''
let s:dq_re = '"\%([^"\\]\+\|\\.\)*"'
let s:err_re = '[''"`]\|\\$'
let s:word_re = '\('.s:matachar_re.'\|'.s:eval_re.'\|'.s:regular.'\|'.s:sq_re.'\|'.s:dq_re.'\|'.s:err_re.'\)\(\s*\|\s*$\)'
let s:errors = {
      \ '\': 'trailing slash',
      \ '"': 'unterminated double quote',
      \ "'": 'unterminated single quote',
      \ '`': 'unterminated backtick',
      \ }

fu! esearch#shell#split(str) abort
  if !g:esearch#has#posix_shell | return [a:str, 0] | endif

  return s:split_posix(a:str)
endfu

" inspired by rb 3 shellwords implementation
fu! s:split_posix(str) abort
  let [args, tokens, byte_offset] = [[], [], matchend(a:str, '^\s*')]
  let [begin, end] = [byte_offset, byte_offset]
  let offset = byte_offset
  let meta = 0

  while 1
    let matches = matchlist(a:str, s:word_re, byte_offset)[0:2]
    if empty(matches) | break | endif
    let [match, token, sep] = matches

    let err = get(s:errors, token)
    if !empty(err) | return [args, err.' at col '.offset] | endif

    if has_key(s:is_metachar, token)
      call add(tokens, [1, token])
      let meta = 1
    elseif token[0] ==# '"'
      let subtokens = split(token[1:-2], '\(`[^`]*`\|[^`]*\)\zs')
      let meta = meta || len(subtokens) > 1 || token[0] ==# '`'
      let tokens += map(subtokens, 'v:val[0] ==# "`" ? [1, v:val] : [0, s:unescape(v:val)]')
    elseif token[0] ==# "'"
      call add(tokens, [0, substitute(token[1:-2], "''", '', 'g')])
    elseif token[0] ==# '`'
      call add(tokens, [1, token])
      let meta = 1
    else
      call add(tokens, [0, s:unescape(token)])
    endif

    if !empty(sep) || byte_offset + len(match) ==# len(a:str)
      call add(args, s:arg(join(map(copy(tokens), 'v:val[1]'), ''), begin, offset + strchars(token), tokens, meta))
      let begin = offset + strchars(match)
      let [tokens, meta] = [[], 0]
    endif

    let byte_offset += len(match)
    let offset += strchars(match)
  endwhile

  return [args, 0]
endfu

fu! s:unescape(str) abort
  return substitute(a:str, '\\\(.\)', '\1', 'g')
endfu

" If an element of <pathspec> starts with '-', it goes after '--' to prevent
" parsing it as an option. <tree> cannot be passed after '--', so partitioning
" is required.
fu! esearch#shell#join_pathspec(args) abort
  if !g:esearch#has#posix_shell
    " temporarty workaround for windows shell
    if match(a:args, ' [''"\\]\=-') >= 0 | return ' -- ' . a:args | endif

    return  a:args . ' -- '
  endif

  let [trees, pathspecs] = s:List.partition(function('s:not_option'), a:args)

  return esearch#shell#join(trees)
        \.(empty(pathspecs) ? '' : ' -- '.esearch#shell#join(pathspecs))
endfu

fu! esearch#shell#join(args) abort
  if !g:esearch#has#posix_shell | return a:args | endif
  return join(map(copy(a:args), 'esearch#shell#escape(v:val)'), ' ')
endfu

fu! esearch#shell#escape(path) abort
  if !a:path.meta | return fnameescape(a:path.str) | endif
  return join(map(copy(a:path.tokens), 'v:val[0] ? v:val[1] : fnameescape(v:val[1])'), '')
endfu

" Posix argv is represented as a list for better completion, highlights and
" validation. Windows argv is represented as a string.
fu! esearch#shell#argv(strs) abort
  if g:esearch#has#posix_shell | return map(copy(a:strs), 's:minimized_arg(v:val)') | endif

  return join(map(copy(a:strs), 'shellescape(v:val)'))
endfu

fu! s:minimized_arg(path) abort
  if s:Filepath.is_relative(a:path)
    return s:arg(a:path, 0, 0, [], 0)
  endif

  return s:arg(fnamemodify(a:path, ':.'), 0, 0, [], 0)
endfu

fu! s:arg(str, begin, end, tokens, meta) abort
  return {'str': a:str, 'begin': a:begin, 'end': a:end, 'tokens': a:tokens, 'meta': a:meta}
endfu

fu! s:not_option(p) abort
  return a:p.str[0] !=# '-'
endfu
let s:by_not_option = function('s:not_option')
