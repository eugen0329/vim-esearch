if exists('b:current_syntax')
  finish
endif

syn match  esearchTitle   '^\%1l.*'
syn match  esearchFName   '^\%>2l.*'
syn match  esearchContext '^\%>2l\s\+.*'
syn match  esearchLnum    '^\%>2l\s\+\d\+'

exe 'syn match esearchOmission "\%(^\%>3l\s\+\d\+\s\)\@<=\V'. g:esearch#util#trunc_omission.'"'
exe 'syn match esearchOmission "\V'. g:esearch#util#trunc_omission.'\$"'

" NOTE If there are already highlight settings for the {from-group}, the link is
" not made, unless the '!' is given
hi link esearchTitle Title
hi link esearchContext Normal
hi link esearchLnum LineNr

if !hlexists('esearchOmission')
  hi esearchOmission ctermfg=yellow
endif

if !hlexists('esearchFName')
  exe 'hi esearchFName cterm=bold gui=bold ' .
        \ 'ctermbg='.esearch#util#highlight_attr('Directory', 'bg', 'cterm', 0).' '.
        \ 'ctermfg='.esearch#util#highlight_attr('Directory', 'fg', 'cterm', 12).' '.
        \ 'guibg=' . esearch#util#highlight_attr('Directory', 'bg', 'gui',   '#005FFF').' '.
        \ 'guifg=' . esearch#util#highlight_attr('Directory', 'fg', 'gui',   '#FFFFFF').' '
endif

if !hlexists('ESearchMatch')
  exe 'hi ESearchMatch cterm=bold gui=bold ' .
        \ 'ctermbg='.esearch#util#highlight_attr('MoreMsg', 'bg', 'cterm', 239 ).' '.
        \ 'ctermfg='.esearch#util#highlight_attr('MoreMsg', 'fg', 'cterm', 15 ).' '.
        \ 'guibg=' . esearch#util#highlight_attr('MoreMsg', 'bg', 'gui',   '#005FFF').' '.
        \ 'guifg=' . esearch#util#highlight_attr('MoreMsg', 'fg', 'gui',   '#FFFFFF').' '
endif

let b:current_syntax = 'esearch'
