function! unite#sources#outline#defaults#esearch#outline_info() abort
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading'  : g:esearch#out#win#filename_re,
      \ 'highlight_rules': [
      \     { 'name'     : 'filename',
      \       'pattern'  : '/^.*/',
      \       'highlight': unite#sources#outline#get_highlight('esearchFilename') },
      \ ]
      \}

function! s:outline_info.create_heading(_which, heading_line, _matched_line, _context) abort
    return {'word' : a:heading_line, 'type' : 'filename'}
endfunction
