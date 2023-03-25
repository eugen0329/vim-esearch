let s:Lualine = esearch#util#struct({}, 'model')

" Notes:
" Check if loaded: package.loaded['lualine']
fu! s:Lualine.__enter__() abort dict
  lua require('lualine').hide({place = {'statusline'}})
endfu

fu! s:Lualine.__exit__() abort dict
  lua require('lualine').hide({unhide = true, place = {'statusline'}})
endfu

fu! esearch#ui#context#lualine#import() abort
  return s:Lualine
endfu
