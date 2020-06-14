let s:Highlight = vital#esearch#import('Vim.Highlight')
let g:esearch#highlight#float_lighter = 0.025
let g:esearch#highlight#float_darker  = -0.05
let g:esearch#highlight#match_lighter = 0.14
let g:esearch#highlight#match_darker  = -0.10

fu! esearch#highlight#init() abort
  aug esearch_highlight
    au!
    au ColorScheme * call esearch#highlight#define()
  aug END
  call esearch#highlight#define()
endfu

fu! esearch#highlight#define() abort
  hi def link esearchStatistics   Number
  hi def link esearchFilename     Directory
  hi def link esearchLineNr       LineNr
  hi def link esearchCursorLineNr CursorLineNr
  hi def esearchHeader cterm=bold gui=bold

  let s:is_dark = s:detect_dark_background()
  call s:define_matches_highlight()
  if g:esearch#has#nvim | call s:define_float_highlighs() | endif

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

fu! s:define_float_highlighs() abort
  let hl = {}
  let hl.normal_float  = s:resolvehl('NormalFloat', {'fallback': 'Pmenu'})
  let hl.normal        = s:gethl('Normal')
  let hl.conceal       = s:gethl('Conceal')
  let hl.cursor_linenr = s:gethl('CursorLineNr')
  let hl.linenr        = s:gethl('LineNr')
  let hl.sign_column   = s:gethl('SignColumn')
  let hl.cursor_line   = s:gethl('CursorLine')

  " For the most of dark colorschemes NormalFloat -> Pmenu is too light, so
  " Normal is adjusted to be slightly lighter
  if s:is_dark
    let percent = g:esearch#highlight#float_lighter
  else
    " For light colorschemes it's better to use Pmenu if available as adjusting
    " Normal to be darker cause it to be greyish.
    if has_key(hl.normal_float, 'guibg')
      let guibg = hl.normal_float.guibg
      let [hl.normal.guibg, hl.conceal.guibg, hl.linenr.guibg, hl.sign_column.guibg] =
            \ [guibg, guibg, guibg, guibg]
      call s:sethl('esearchNormalFloat',       hl.normal,        {'default': 1})
      call s:sethl('esearchConcealFloat',      hl.conceal,       {'default': 1})
      call s:sethl('esearchCursorLineNrFloat', hl.cursor_linenr, {'default': 1})
      call s:sethl('esearchCursorLineFloat',   hl.cursor_line,   {'default': 1})
      call s:sethl('esearchLineNrFloat',       hl.linenr,        {'default': 1})
      call s:sethl('esearchSignColumnFloat',   hl.sign_column,   {'default': 1})

      return
    endif

    let percent = g:esearch#highlight#float_darker
  endif

  call s:define_float_highlights_with_adjusted_brightness(hl, percent)
endfu

fu! s:define_float_highlights_with_adjusted_brightness(hl, percent) abort
  let [hl, percent] = [a:hl, a:percent]
  
  if s:is_hex(hl.normal, 'guibg')
    let hl.normal.guibg = s:adjust_brightness(hl.normal.guibg, percent)
  endif
  if has_key(hl.normal_float, 'ctermbg')
    let hl.normal.ctermbg = hl.normal_float.ctermbg
  endif
  if has_key(hl.normal_float, 'ctermfg')
    let hl.normal.ctermfg = hl.normal_float.ctermfg
  endif
  call s:sethl('esearchNormalFloat', hl.normal, {'default': 1})

  if s:is_hex(hl.conceal, 'guibg')
    let hl.conceal.guibg = s:adjust_brightness(hl.conceal.guibg, percent)
  endif
  call s:sethl('esearchConcealFloat', hl.conceal, {'default': 1})

  if s:is_hex(hl.cursor_line, 'guibg')
    let hl.cursor_line.guibg = s:adjust_brightness(hl.cursor_line.guibg, percent)
  endif
  call s:sethl('esearchCursorLineFloat', hl.cursor_line, {'default': 1})

  if s:is_hex(hl.cursor_linenr, 'guibg')
    let hl.cursor_linenr.guibg = s:adjust_brightness(hl.cursor_linenr.guibg, percent)
  endif
  call s:sethl('esearchCursorLineNrFloat', hl.cursor_linenr, {'default': 1})

  if s:is_hex(hl.linenr, 'guibg')
    let hl.linenr.guibg = s:adjust_brightness(hl.linenr.guibg, percent)
    let hl.sign_column.guibg = hl.linenr.guibg
  elseif has_key(hl.normal, 'guibg')
    let hl.sign_column.guibg = hl.normal.guibg
  endif
  call s:sethl('esearchLineNrFloat', hl.linenr, {'default': 1})

  if has_key(hl.linenr, 'ctermbg')
    let hl.sign_column.ctermbg = hl.linenr.ctermbg
  elseif has_key(hl.normal, 'ctermbg')
    let hl.sign_column.ctermbg = hl.normal.ctermbg
  endif
  call s:sethl('esearchSignColumnFloat', hl.sign_column, {'default': 1})
endfu

fu! s:resolvehl(name, kwargs) abort
  if hlexists(a:name)
    let hl = s:gethl(a:name)
    if has_key(hl, 'link') && hlexists(hl.link)
      let hl = s:gethl(hl.link)
    endif
  else
    let hl = s:gethl(a:kwargs.fallback)
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
