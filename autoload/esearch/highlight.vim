let s:Highlight = vital#esearch#import('Vim.Highlight')
let g:esearch#highlight#float_lighter = 0.025
let g:esearch#highlight#float_darker  = -0.05
let g:esearch#highlight#match_lighter = 0.14
let g:esearch#highlight#match_darker  = -0.10

fu! esearch#highlight#init() abort
  aug esearch_highlight
    au!
    au ColorScheme * call esearch#highlight#set()
  aug END
  call esearch#highlight#set()
endfu

fu! esearch#highlight#set() abort
  hi def link esearchStatistics   Number
  hi def link esearchFilename     Directory
  hi def link esearchLineNr       LineNr
  hi def link esearchCursorLineNr CursorLineNr
  hi def      esearchHeader       cterm=bold gui=bold

  let esearchBasename = extend(s:resolvehl('esearchFilename', {'fallback': 'Directory'}),
        \ {'cterm': 'bold', 'gui': 'bold'})
  call s:sethl('esearchBasename', esearchBasename, {'default': 1})

  let s:is_dark = s:detect_dark_background()
  call s:set_matches_highlight()
  call s:set_virtual_sign_highlight()
  call s:set_float_win_highlights()

  if hlexists('esearchLnum')
    call s:copyhl('esearchLnum', 'esearchLineNr', {'force': 1})
  endif
  if hlexists('esearchFName')
    call s:copyhl('esearchFName', 'esearchFilename', {'force': 1})
  endif
endfu

fu! s:set_virtual_sign_highlight() abort
  let DiffAdd = s:gethl('DiffAdd')
  silent! unlet DiffAdd['ctermbg']
  silent! unlet DiffAdd['guibg']
  call s:sethl('esearchDiffAdd', DiffAdd, {'default': 1})
endfu

" Try to emphasize enough without overruling foregrounds, that are used by
" context syntaxes
fu! s:set_matches_highlight() abort
  let CursorLine = s:gethl('CursorLine')
  let Normal = s:gethl('Normal')
  let esearchMatch = {}

  if has_key(CursorLine, 'ctermbg')
    let esearchMatch.ctermbg = CursorLine.ctermbg
    let esearchMatch.cterm   = 'bold,underline'
  else " blue bg + white fg
    let esearchMatch.ctermbg = 27
    let esearchMatch.ctermfg = 15
  endif

  if s:is_hex(Normal, 'guibg')
    let percent = s:is_dark ? g:esearch#highlight#match_lighter : g:esearch#highlight#match_darker
    let esearchMatch.guibg = s:change_brightness(Normal.guibg, percent)
    let esearchMatch.gui = 'bold'
  else
    let esearchMatch.guibg = get(CursorLine, 'guibg', '#005FFF')
    let esearchMatch.gui = 'bold,underline'
  endif

  call s:sethl('esearchMatch', esearchMatch, {'default': 1})
endfu

fu! s:set_float_win_highlights() abort
  let hl = {}
  let hl.NormalFloat  = s:resolvehl('NormalFloat', {'fallback': 'Pmenu'})
  let hl.Normal       = s:gethl('Normal')
  let hl.Conceal      = s:gethl('Conceal')
  let hl.CursorLineNr = s:gethl('CursorLineNr')
  let hl.LineNr       = s:gethl('LineNr')
  let hl.SignColumn   = s:gethl('SignColumn')
  let hl.CursorLine   = s:gethl('CursorLine')

  " For the most of dark colorschemes NormalFloat -> Pmenu is too light, so
  " Normal is adjusted to be slightly lighter
  if s:is_dark
    let percent = g:esearch#highlight#float_lighter
  else
    " For light colorschemes it's better to use NormalFloat if available as
    " adjusting Normal to be darker cause it to be greyish.
    if has_key(hl.NormalFloat, 'guibg') || has_key(hl.NormalFloat, 'ctermbg')
      return s:set_float_win_highlights_with_normal_float_bg(hl)
    endif

    let percent = g:esearch#highlight#float_darker
  endif

  call s:set_float_win_highlights_with_adjusted_brightness(hl, percent)
endfu

fu! s:set_float_win_highlights_with_normal_float_bg(hl) abort
  let hl = a:hl

  if has_key(hl.NormalFloat, 'guibg')
    let guibg = hl.NormalFloat.guibg
    let [hl.Normal.guibg, hl.Conceal.guibg, hl.LineNr.guibg, hl.SignColumn.guibg] =
          \ [guibg, guibg, guibg, guibg]
  endif

  if has_key(hl.NormalFloat, 'ctermbg')
    let ctermbg = hl.NormalFloat.ctermbg
    let [hl.Normal.ctermbg, hl.Conceal.ctermbg, hl.LineNr.ctermbg, hl.SignColumn.ctermbg] =
          \ [ctermbg, ctermbg, ctermbg, ctermbg]
  endif

  call s:sethl_float_win(hl)
endfu

fu! s:set_float_win_highlights_with_adjusted_brightness(hl, percent) abort
  let [hl, percent] = [a:hl, a:percent]

  if s:is_hex(hl.Normal, 'guibg')
    let hl.Normal.guibg = s:change_brightness(hl.Normal.guibg, percent)
  endif
  if has_key(hl.NormalFloat, 'ctermbg')
    let hl.Normal.ctermbg = hl.NormalFloat.ctermbg
  endif
  if has_key(hl.NormalFloat, 'ctermfg')
    let hl.Normal.ctermfg = hl.NormalFloat.ctermfg
  endif

  if s:is_hex(hl.Conceal, 'guibg')
    let hl.Conceal.guibg = s:change_brightness(hl.Conceal.guibg, percent)
  endif

  if s:is_hex(hl.CursorLine, 'guibg')
    let hl.CursorLine.guibg = s:change_brightness(hl.CursorLine.guibg, percent)
  endif

  if s:is_hex(hl.CursorLineNr, 'guibg')
    let hl.CursorLineNr.guibg = s:change_brightness(hl.CursorLineNr.guibg, percent)
  endif

  if s:is_hex(hl.LineNr, 'guibg')
    let hl.LineNr.guibg = s:change_brightness(hl.LineNr.guibg, percent)
    let hl.SignColumn.guibg = hl.LineNr.guibg
  elseif has_key(hl.Normal, 'guibg')
    let hl.SignColumn.guibg = hl.Normal.guibg
  endif
  if has_key(hl.LineNr, 'ctermbg')
    let hl.SignColumn.ctermbg = hl.LineNr.ctermbg
  elseif has_key(hl.Normal, 'ctermbg')
    let hl.SignColumn.ctermbg = hl.Normal.ctermbg
  endif

  call s:sethl_float_win(hl)
endfu

fu! s:sethl_float_win(hl) abort
  call s:sethl('esearchNormalFloat',       a:hl.Normal,       {'default': 1})
  call s:sethl('esearchConcealFloat',      a:hl.Conceal,      {'default': 1})
  call s:sethl('esearchCursorLineNrFloat', a:hl.CursorLineNr, {'default': 1})
  call s:sethl('esearchCursorLineFloat',   a:hl.CursorLine,   {'default': 1})
  call s:sethl('esearchLineNrFloat',       a:hl.LineNr,       {'default': 1})
  call s:sethl('esearchSignColumnFloat',   a:hl.SignColumn,   {'default': 1})
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

fu! s:change_brightness(hex, percent) abort
  return s:rgb2hex(map(s:hex2rgb(a:hex),
        \ 'esearch#util#clip(float2nr(v:val + 255 * a:percent), 0, 255)'))
endfu

" TODO remove when deprecated highlights are dropped
fu! s:copyhl(from, to, options) abort
  let new_highlight = {'name': a:to, 'attrs': s:Highlight.get(a:from).attrs}

  call s:Highlight.set(new_highlight, a:options)
endfu

fu! s:sethl(name, attributes, options) abort
  if a:attributes ==# {'cleared': 1} || empty(a:attributes)
    let new_highlight = {'name': a:name, 'attrs': {'clear': 1}}
  else
    let new_highlight = {
          \ 'name': a:name,
          \ 'attrs': filter(a:attributes, '!empty(v:val) && v:key !=# "cleared"')
          \}
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
  let Normal = s:gethl('Normal')
  if g:esearch#has#gui_colors && s:is_hex(Normal, 'guibg')
    return s:hsp(Normal.guibg) <= 127.5
  endif

  return &background ==# 'dark'
endfu
