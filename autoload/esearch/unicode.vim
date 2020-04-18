scriptencoding utf-8

let g:esearch#unicode#ellipsis = '⦚'
if exists('g:WebDevIconsUnicodeDecorateFolderNodesDefaultSymbol')
  let g:esearch#unicode#dir_icon = g:WebDevIconsUnicodeDecorateFolderNodesDefaultSymbol
elseif has('osx')
  let g:esearch#unicode#dir_icon = '📂 '
else
  let g:esearch#unicode#dir_icon = '🗀 '
endif
let g:esearch#unicode#spinner = [' ◜ ', '  ◝', '  ◞', ' ◟ ']
let g:esearch#unicode#less_or_equal = '≤'
let g:esearch#unicode#slash = '∕'
let g:esearch#unicode#quote_right = '›'
let g:esearch#unicode#quote_left = '‹'
