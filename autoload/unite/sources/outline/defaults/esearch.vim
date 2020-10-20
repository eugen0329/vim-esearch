fu! unite#sources#outline#defaults#esearch#outline_info() abort
  return extend(copy(s:outline_info), {'is_volatile': !b:esearch.request.finished})
endfu

let s:outline_info = {
      \ 'heading'  : g:esearch#out#win#filename_re . '\%>2l',
      \ 'highlight_rules': [
      \     { 'name'     : 'filename',
      \       'pattern'  : '/^.*/',
      \       'highlight': 'esearchFilename' },
      \ ],
      \}

if g:esearch#has#lua
  fu! s:outline_info.extract_headings(context) abort
    return luaeval('esearch.extract_headings(_A)', a:context.buffer.nr)
  endfu
else
  fu! s:outline_info.create_heading(_which, heading_line, _matched_line, _context) abort
    return {'word': a:heading_line, 'type': 'filename'}
  endfu
endif
