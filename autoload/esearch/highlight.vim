let s:Highlight = vital#esearch#import('Vim.Highlight')
let g:esearch#highlight#float_brighter = 1.15
let g:esearch#highlight#float_darker   = 0.88

fu! esearch#highlight#init() abort
  aug esearch_highlight
    au!
    au ColorScheme * call esearch#highlight#define()
  aug END
endfu

fu! esearch#highlight#define() abort
  hi def link esearchHeader       Title
  hi def link esearchStatistics   Number
  hi def link esearchFilename     Directory
  hi def link esearchLineNr       LineNr
  hi def link esearchCursorLineNr CursorLineNr

  let cursorline    = s:gethl('CursorLine')
  let esearch_match = extend(s:gethl('MoreMsg'), {
        \   'ctermbg': get(cursorline, 'ctermbg', 239),
        \   'guibg':   get(cursorline, 'guibg',   '#005FFF'),
        \   'cterm':  'bold,underline',
        \   'gui':    'bold,underline',
        \ })
  call s:sethl('esearchMatch', esearch_match, {'default': 1})

  if g:esearch#has#nvim
    call s:define_float_highlighs()
  endif
  " DEPRECATE legacy names support
  if hlexists('esearchLnum')
    call s:copy('esearchLineNr', 'esearchLnum', {'force': 1})
  endif
  if hlexists('esearchFName')
    call s:copy('esearchFilename', 'esearchFName', {'force': 1})
  endif
  if hlexists('ESearchMatch')
    call s:copy('ESearchMatch', 'esearchMatch', {'force': 1})
  endif
endfu

fu! s:copy(from, to, options) abort
  let new_highlight = {'name': a:from, 'attrs': s:Highlight.get(a:to).attrs}

  call s:Highlight.set(new_highlight, a:options)
endfu

fu! s:sethl(name, attributes, options) abort
  let attributes = filter(a:attributes, '!empty(v:val)')
  let new_highlight = {'name': a:name, 'attrs': attributes}

  call s:Highlight.set(new_highlight, a:options)
endfu

fu! s:gethl(hightlight_name) abort
  return s:Highlight.get(a:hightlight_name).attrs
endfu

" Fot the most of dark colorschemes NormalFloat -> Pmenu is too light. So 1.15
" brightness increase is used. On the other hand, when a light colorscheme is
" used, it's better to use Pmenu as it's not too dark.
fu! s:define_float_highlighs() abort
  let normal  = s:gethl('Normal')
  let cursor_linenr       = s:gethl('CursorLineNr')
  let linenr       = s:gethl('LineNr')
  let sign_column  = s:gethl('SignColumn')
  let cursor_line  = s:gethl('CursorLine')

  if &background ==# 'dark'
    let coeff = g:esearch#highlight#float_brighter
  else
    " NOTE no deep links resolving is performed
    if hlexists('NormalFloat')
      let normal_float = s:gethl('NormalFloat')
      if has_key(normal_float, 'link') && hlexists(normal_float.link)
        let normal_float = s:gethl(normal_float.link)
      endif
    else
      let normal_float = s:gethl('Pmenu')
    endif

    if has_key(normal_float, 'guibg')
      " CursorLine and CursorLineNr are untouched
      let [normal.guibg, linenr.guibg, sign_column.guibg] = 
            \ [normal_float.guibg, normal_float.guibg, normal_float.guibg]
      call s:sethl('esearchNormalFloat',       normal,        {'default': 1})
      call s:sethl('esearchCursorLineNrFloat', cursor_linenr, {'default': 1})
      call s:sethl('esearchCursorLineFloat',   cursor_line,   {'default': 1})
      call s:sethl('esearchLineNrFloat',       linenr,        {'default': 1})
      call s:sethl('esearchSignColumnFloat',   sign_column,   {'default': 1})

      return
    endif

    let coeff = g:esearch#highlight#float_darker
  endif

  if has_key(normal, 'guibg')
    let normal.guibg = s:adj_brightness(normal.guibg, coeff)
  endif
  call s:sethl('esearchNormalFloat', normal, {'default': 1})

  if has_key(cursor_linenr, 'guibg')
    let cursor_linenr.guibg = s:adj_brightness(cursor_linenr.guibg, coeff)
  endif
  call s:sethl('esearchCursorLineNrFloat', cursor_linenr, {'default': 1})

  if has_key(cursor_line, 'guibg')
    let cursor_line.guibg = s:adj_brightness(cursor_line.guibg, coeff)
  endif
  call s:sethl('esearchCursorLineFloat', cursor_line, {'default': 1})

  if has_key(linenr, 'guibg')
    let linenr.guibg = s:adj_brightness(linenr.guibg, coeff)
    let sign_column.guibg = linenr.guibg
  elseif has_key(normal, 'guibg')
    let sign_column.guibg = normal.guibg
  endif
  call s:sethl('esearchSignColumnFloat', sign_column, {'default': 1})
  call s:sethl('esearchLineNrFloat',     linenr,      {'default': 1})
endfu

fu! s:rgb2hex(rgb) abort
  return printf('#%02x%02x%02x', a:rgb[0], a:rgb[1], a:rgb[2])
endfu

fu! s:hex2rgb(hex) abort
  let hex = tolower(a:hex)[1:]
  return [str2nr(printf('0x%s', hex[0:1]), 16),
        \ str2nr(printf('0x%s', hex[2:3]), 16),
        \ str2nr(printf('0x%s', hex[4:5]), 16)]
endfu

fu! s:adj_brightness(hex, coeff) abort
  return s:rgb2hex(map(s:hex2rgb(a:hex), 'esearch#util#clip(float2nr(v:val * a:coeff), 0, 255)'))
endfu
