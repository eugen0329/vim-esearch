let s:Highlight = vital#esearch#import('Vim.Highlight')
let g:esearch#highlight#float_brighter = 1.15
let g:esearch#highlight#float_darker   = 0.88

fu! esearch#highlight#init() abort
  aug esearch_highlight
    au!
    au ColorScheme * call esearch#highlight#define()
  aug END
  call esearch#highlight#define()
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
    call s:copy('esearchLnum', 'esearchLineNr', {'force': 1})
  endif
  if hlexists('esearchFName')
    call s:copy('esearchFName', 'esearchFilename', {'force': 1})
  endif
endfu

fu! s:copy(from, to, options) abort
  let new_highlight = {'name': a:to, 'attrs': s:Highlight.get(a:from).attrs}

  call s:Highlight.set(new_highlight, a:options)
endfu

fu! s:sethl(name, attributes, options) abort
  " TODO investigate. When cleared - colors are inherited from normal, but
  " Normal can be cleared as well.
  if a:attributes ==# {'cleared': 1}
    let new_highlight = {'name': a:name, 'attrs': {'clear': 1}}
  else
    let new_highlight = {'name': a:name, 'attrs': filter(a:attributes, '!empty(v:val) && v:key !=# "cleared"')}
  endif

  silent call s:Highlight.set(new_highlight, a:options)
endfu

fu! s:gethl(hightlight_name) abort
  return s:Highlight.get(a:hightlight_name).attrs
endfu

" Fot the most of dark colorschemes NormalFloat -> Pmenu is too light. So 1.15
" brightness increase is used. But for light colorschemes it's better to use
" Pmenu as it's usually not too gray.
fu! s:define_float_highlighs() abort
  let normal_float  = s:resolvehl('NormalFloat', 'Pmenu')
  let normal        = s:gethl('Normal')
  let cursor_linenr = s:gethl('CursorLineNr')
  let linenr        = s:gethl('LineNr')
  let sign_column   = s:gethl('SignColumn')
  let cursor_line   = s:gethl('CursorLine')

  if &background ==# 'dark'
    let coeff = g:esearch#highlight#float_brighter
  elseif has_key(normal_float, 'guibg')
    let [normal.guibg, linenr.guibg, sign_column.guibg] =
          \ [normal_float.guibg, normal_float.guibg, normal_float.guibg]
    call s:sethl('esearchNormalFloat',       normal,        {'default': 1})
    call s:sethl('esearchCursorLineNrFloat', cursor_linenr, {'default': 1})
    call s:sethl('esearchCursorLineFloat',   cursor_line,   {'default': 1})
    call s:sethl('esearchLineNrFloat',       linenr,        {'default': 1})
    call s:sethl('esearchSignColumnFloat',   sign_column,   {'default': 1})

    return
  else
    let coeff = g:esearch#highlight#float_darker
  endif

  if has_key(normal, 'guibg')
    let normal.guibg = s:adjust_brightness(normal.guibg, coeff)
  endif
  if has_key(normal_float, 'ctermbg')
    let normal.ctermbg = normal_float.ctermbg
  endif
  if has_key(normal_float, 'ctermfg')
    let normal.ctermfg = normal_float.ctermfg
  endif
  call s:sethl('esearchNormalFloat', normal, {'default': 1})

  if has_key(cursor_line, 'guibg')
    let cursor_line.guibg = s:adjust_brightness(cursor_line.guibg, coeff)
  endif
  call s:sethl('esearchCursorLineFloat', cursor_line, {'default': 1})

  if has_key(cursor_linenr, 'guibg')
    let cursor_linenr.guibg = s:adjust_brightness(cursor_linenr.guibg, coeff)
  endif
  call s:sethl('esearchCursorLineNrFloat', cursor_linenr, {'default': 1})

  if has_key(linenr, 'guibg')
    let linenr.guibg = s:adjust_brightness(linenr.guibg, coeff)
    let sign_column.guibg = linenr.guibg
  elseif has_key(normal, 'guibg')
    let sign_column.guibg = normal.guibg
  endif
  call s:sethl('esearchLineNrFloat',     linenr,      {'default': 1})

  if has_key(linenr, 'ctermbg')
    let sign_column.ctermbg = linenr.ctermbg
  elseif has_key(normal, 'ctermbg')
    let sign_column.ctermbg = normal.ctermbg
  endif
  call s:sethl('esearchSignColumnFloat', sign_column, {'default': 1})
endfu

fu! s:resolvehl(name, fallback) abort
  if hlexists(a:name)
    let hl = s:gethl(a:name)
    if has_key(hl, 'link') && hlexists(hl.link)
      let hl = s:gethl(hl.link)
    endif
  else
    let hl = s:gethl(a:fallback)
  endif

  return hl
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

fu! s:adjust_brightness(hex, coeff) abort
  return s:rgb2hex(map(s:hex2rgb(a:hex), 'esearch#util#clip(float2nr(v:val * a:coeff), 0, 255)'))
endfu
