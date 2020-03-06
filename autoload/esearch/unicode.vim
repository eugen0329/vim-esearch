let g:esearch#unicode#ellipsis = '⦚'
if exists('g:WebDevIconsUnicodeDecorateFolderNodesDefaultSymbol')
  let g:esearch#unicode#dir_icon = g:WebDevIconsUnicodeDecorateFolderNodesDefaultSymbol
else
  let g:esearch#unicode#dir_icon = '🗀 '
endif
let g:esearch#unicode#spinner = [' ◜ ', '  ◝', '  ◞', ' ◟ ']
