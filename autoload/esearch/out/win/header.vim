if g:esearch#has#unicode
  let s:less_or_equal = g:esearch#unicode#less_or_equal
  let s:spinner = g:esearch#unicode#spinner
else
  let s:less_or_equal = '<='
  let s:spinner = ['.', '..', '...']
endif
let s:spinner_fram_len = len(s:spinner)
let s:spinner_slowdown = 2
let s:spinner_max_frame_len = max(map(copy(s:spinner), 'strchars(v:val)'))
let s:finished_header = 'Matches in %d %s, %d %s. Finished.'

fu! esearch#out#win#header#init(esearch) abort
  let a:esearch.header_text = function('esearch#out#win#header#in_progress')

  " If context heights are given - consumed lines count is imprecise as they
  " contain separators ('--' or '')
  if a:esearch.current_adapter.outputs_separators(a:esearch)
    let a:esearch.precision_hint = s:less_or_equal
  else
    let a:esearch.precision_hint = ''
  endif

  let a:esearch.header_format =
        \  'Matches in ' . a:esearch.precision_hint
        \. '%d%-' . s:spinner_max_frame_len . 's line(s), '
        \. '%d%-' . s:spinner_max_frame_len . 's file(s)'
endfu

" Render order:
"   #in_progress() - Consuming results from a backend and rendering them
"   #finished_backend() - All lines are consumed, but not rendered yet.
"   The approximate result lines count is rendered.
"   #finished_render()  - All lines are consumed and rendered. Exact lines and
"   files counts are rendered.

fu! esearch#out#win#header#in_progress() abort dict
  " A side effect to decide automatically when to change the header format
  " to hint users that consuming from the backend is finished and only rendering
  " remains.
  if self.request.finished
    let self.header_text = function('esearch#out#win#header#finished_backend')
    let self.header_format =
          \  'Matches in '.self.precision_hint.'%3d ' . s:lines_word(self) . ', '
          \. '%3d%-'.s:spinner_max_frame_len.'s file(s)'
    return self.header_text()
  endif

  let spinner = s:spinner[len(self.request.data) / s:spinner_slowdown % s:spinner_fram_len]
  return printf(self.header_format,
        \ len(self.request.data)  - self.separators_count,
        \ spinner,
        \ self.files_count,
        \ spinner
        \ )
endfu

fu! esearch#out#win#header#finished_backend() abort dict
  let spinner = s:spinner[len(self.request.data) / s:spinner_slowdown % s:spinner_fram_len]
  return printf(self.header_format,
        \ len(self.request.data) - self.separators_count,
        \ self.files_count,
        \ spinner
        \ )
endfu

fu! esearch#out#win#header#finished_render() abort dict
  return printf(s:finished_header,
        \ len(self.request.data) - self.separators_count,
        \ esearch#util#pluralize('line', len(self.request.data) - self.separators_count),
        \ self.files_count,
        \ esearch#util#pluralize('file', self.files_count),
        \ )
endfu

fu! s:lines_word(esearch) abort
  if !empty(a:esearch.precision_hint)
    return 'line(s)'
  endif

  return esearch#util#pluralize('line', len(a:esearch.request.data) - a:esearch.separators_count)
endfu
