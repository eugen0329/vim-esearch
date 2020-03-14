if !exists('g:esearch#adapter#grep#options')
  let g:esearch#adapter#grep#options = ''
endif
if !exists('g:esearch#adapter#grep#bin')
  let g:esearch#adapter#grep#bin = 'grep'
endif

fu! esearch#adapter#grep#_options() abort
  if !exists('s:options')

    let available_options = esearch#util#parse_help_options(g:esearch#adapter#grep#bin.' -h')
    if v:shell_error != 0
      let available_options = esearch#util#parse_help_options(g:esearch#adapter#grep#bin.' --help')
    endif

    if has('macunix')
      let regex = '-E'
      let literal_match = '--fixed-strings'
      let show_line_numbers = '--line-number'
      let exclude_dirs = '--exclude-dir=.{git,svn,hg}'
    else
      if has_key(available_options, '--perl-regexp')
        let regex = '--perl-regexp'
      elseif has_key(available_options, '-E')
        let regex = '-E'
      else
        " use original value as it was earlier until properly tested
        let regex = '--perl-regexp'
      endif

      if has_key(available_options, '--fixed-strings')
        let literal_match = '--fixed-strings'
      elseif has_key(available_options, '-F')
        let literal_match = '-F'
      else
        " use original value as it was earlier until properly tested
        let literal_match = '--fixed-strings'
      endif

      if has_key(available_options, '--line-number')
        let show_line_numbers = '--line-number'
      elseif has_key(available_options, '-n')
        let show_line_numbers = '-n'
      else
        " use original value as it was earlier until properly tested
        let show_line_numbers = '--line-number'
      endif

      if has_key(available_options, '--exclude-dir')
        let exclude_dirs = '--exclude-dir=.{git,svn,hg}'
      else
        let exclude_dirs = ''
      endif
    endif

    let s:options = {
    \ 'regex': { 'p': [literal_match, regex], 's': ['>', 'r'] },
    \ 'case':  { 'p': ['-i',   ''             ], 's': ['>', 'c'] },
    \ 'word':  { 'p': ['',                '--word-regexp'], 's': ['>', 'w'] },
    \ 'show_line_numbers': show_line_numbers,
    \ 'exclude_dirs': exclude_dirs,
    \ 'stringify':   function('esearch#util#stringify'),
    \ 'parametrize': function('esearch#util#parametrize'),
    \}
  endif
  return s:options
endfu

fu! esearch#adapter#grep#cmd(esearch, pattern, escape) abort
  let options = esearch#adapter#grep#_options()
  let r = options.parametrize('regex')
  let c = options.parametrize('case')
  let w = options.parametrize('word')
  " -r: recursive, no follow symbolic links
  " -I: Process a binary file as if it did not contain matching data
  " -H: Print the file name for each match.  This is the default when there is more than one file to search.

  let joined_paths = esearch#adapter#ag_like#joined_paths(a:esearch)

  " return g:esearch#adapter#grep#bin.' '.r.' '.c.' '.w.' -r --line-number --exclude-dir=.{git,svn,hg} ' .
  return g:esearch#adapter#grep#bin.' '.r.' '.c.' '.w.' -H -I -r -n '.options.show_line_numbers.' '.options.exclude_dirs.' '.
        \ g:esearch#adapter#grep#options . ' -- ' .
        \ a:escape(a:pattern) . ' ' . joined_paths
endfu

fu! esearch#adapter#grep#requires_pty() abort
  return 0
endfu
