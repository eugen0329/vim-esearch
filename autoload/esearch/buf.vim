let s:Filepath = vital#esearch#import('System.Filepath')

fu! esearch#buf#find(filename) abort
  return bufnr(esearch#buf#pattern(a:filename))
endfu

" :h file-pattern
fu! esearch#buf#pattern(filename) abort
  let filename = a:filename
  " let filename = escape(a:filename, '%#')
  " fnamemodify changes /foor/./bar => /foo/bar in paths, but it's not working
  " when the filename is missing (edge case, but can be considered as TODO)
  let filename = resolve(fnamemodify(filename, ':p'))

  " From :h file-pattern
  " Note that for all systems the '/' character is used for path separator (even
  " Windows). This was done because the backslash is difficult to use in a pattern
  " and to make the autocommands portable across different systems.
  let filename = s:Filepath.to_slash(filename)

  " From :h file-pattern:
  "   *	matches any sequence of characters; Unusual: includes path separators
  "   ?	matches any single character
  "   \?	matches a '?'
  "   .	matches a '.'
  "   ~	matches a '~'
  "   ,	separates patterns
  "   \,	matches a ','
  "   { }	like \( \) in a |pattern|
  "   ,	inside { }: like \| in a |pattern|
  "   \}	literal }
  "   \{	literal {
  "   \\\{n,m\}  like \{n,m} in a |pattern|
  "   \	special meaning like in a |pattern|
  "   [ch]	matches 'c' or 'h'
  "   [^ch]   match any character but 'c' and 'h'

  " Special file-pattern characters must be escaped: [ escapes to [[], not \[.
  let filename = escape(filename, '?*[],\')
  " replacing with \{ and \} or [{] and [}] doesn't work
  let filename = substitute(filename, '[{}]', '?', 'g')
  return filename
endfu
