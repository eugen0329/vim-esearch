let s:Highlight = vital#esearch#import('Vim.Highlight')
let g:esearch#highlight#float_lighter = 0.025
let g:esearch#highlight#float_darker  = -0.05
let g:esearch#highlight#match_lighter = 0.15
let g:esearch#highlight#match_darker  = -0.10

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

  let s:is_dark = s:detect_dark_background()
  call s:define_matches_highlight()
  if g:esearch#has#nvim | call s:define_float_highlighs() | endif

  " TODO DEPRECATE
  if hlexists('esearchLnum')
    call s:copyhl('esearchLnum', 'esearchLineNr', {'force': 1})
  endif
  if hlexists('esearchFName')
    call s:copyhl('esearchFName', 'esearchFilename', {'force': 1})
  endif
endfu

" Try to emphasize enough without overruling foregrounds, that are used by
" context syntaxes
fu! s:define_matches_highlight() abort
  let cursorline = s:gethl('CursorLine')
  let normal = s:gethl('Normal')

  let esearch_match = {}

  if has_key(cursorline, 'ctermbg')
    let esearch_match.ctermbg = cursorline.ctermbg
    let esearch_match.cterm   = 'bold,underline'
  else " blue bg + white fg
    let esearch_match.ctermbg = 27
    let esearch_match.ctermfg = 15
  endif

  if s:is_hex(normal, 'guibg')
    let percent = s:is_dark ? g:esearch#highlight#match_lighter : g:esearch#highlight#match_darker
    let esearch_match.guibg = s:adjust_brightness(normal.guibg, percent)
    let esearch_match.gui = 'bold'
  else
    let esearch_match.guibg = get(cursorline, 'guibg', '#005FFF')
    let esearch_match.gui = 'bold,underline'
  endif

  call s:sethl('esearchMatch', esearch_match, {'default': 1})
endfu

" For the most of dark colorschemes NormalFloat -> Pmenu is too light. But for
" light colorschemes it's better to use Pmenu as it's usually not too gray.
fu! s:define_float_highlighs() abort
  let normal_float  = s:resolvehl('NormalFloat', 'Pmenu')
  let normal        = s:gethl('Normal')
  let cursor_linenr = s:gethl('CursorLineNr')
  let linenr        = s:gethl('LineNr')
  let sign_column   = s:gethl('SignColumn')
  let cursor_line   = s:gethl('CursorLine')

  if s:is_dark
    let percent = g:esearch#highlight#float_lighter
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
    let percent = g:esearch#highlight#float_darker
  endif

  if s:is_hex(normal, 'guibg')
    let normal.guibg = s:adjust_brightness(normal.guibg, percent)
  endif
  if has_key(normal_float, 'ctermbg')
    let normal.ctermbg = normal_float.ctermbg
  endif
  if has_key(normal_float, 'ctermfg')
    let normal.ctermfg = normal_float.ctermfg
  endif
  call s:sethl('esearchNormalFloat', normal, {'default': 1})

  if s:is_hex(cursor_line, 'guibg')
    let cursor_line.guibg = s:adjust_brightness(cursor_line.guibg, percent)
  endif
  call s:sethl('esearchCursorLineFloat', cursor_line, {'default': 1})

  if s:is_hex(cursor_linenr, 'guibg')
    let cursor_linenr.guibg = s:adjust_brightness(cursor_linenr.guibg, percent)
  endif
  call s:sethl('esearchCursorLineNrFloat', cursor_linenr, {'default': 1})

  if s:is_hex(linenr, 'guibg')
    let linenr.guibg = s:adjust_brightness(linenr.guibg, percent)
    let sign_column.guibg = linenr.guibg
  elseif has_key(normal, 'guibg')
    let sign_column.guibg = normal.guibg
  endif
  call s:sethl('esearchLineNrFloat', linenr, {'default': 1})

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

fu! s:is_hex(hl, attribute) abort
  return get(a:hl, a:attribute, '') =~# '^#\x\{6}$'
endfu

fu! s:hex2rgb(hex) abort
  let hex = tolower(a:hex)[1:]
  return [str2nr(printf('0x%s', hex[0:1]), 16),
        \ str2nr(printf('0x%s', hex[2:3]), 16),
        \ str2nr(printf('0x%s', hex[4:5]), 16)]
endfu

fu! s:adjust_brightness(hex, percent) abort
  return s:rgb2hex(map(s:hex2rgb(a:hex), 'esearch#util#clip(float2nr(v:val + 255 * a:percent), 0, 255)'))
endfu

fu! s:copyhl(from, to, options) abort
  let new_highlight = {'name': a:to, 'attrs': s:Highlight.get(a:from).attrs}

  call s:Highlight.set(new_highlight, a:options)
endfu

fu! s:sethl(name, attributes, options) abort
  " TODO investigate. When cleared - colors are inherited from normal, while
  " Normal can be cleared
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

fu! s:hsp(hex) abort " Highly Sensitive Poo
  let [r, g, b] = s:hex2rgb(a:hex)
  return sqrt(0.299 * (r * r) + 0.587 * (g * g) + 0.114 * (b * b))
endfu

" &background can become out of sync when a colorscheme is switched, so hsp usage
" is more reliable.
fu! s:detect_dark_background() abort
  let normal = s:gethl('Normal')
  if g:esearch#has#gui_colors && s:is_hex(normal, 'guibg')
    return s:hsp(normal.guibg) <= 127.5
  endif

  return &background ==# 'dark'
endfu
