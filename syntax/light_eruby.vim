if exists('b:current_syntax')
  finish
endif

syn include @rubyTop syntax/light_ruby.vim

syn cluster erubyRegions contains=erubyOneLiner,erubyBlock,erubyExpression,erubyComment

let s:eruby_nest_level = 1

exe 'syn region  erubyOneLiner   matchgroup=erubyDelimiter start="^%\{1,'.s:eruby_nest_level.'\}%\@!"    end="$"     contains=@rubyTop	     containedin=ALLBUT,@erubyRegions keepend oneline'
exe 'syn region  erubyBlock      matchgroup=erubyDelimiter start="<%\{1,'.s:eruby_nest_level.'\}%\@!-\=" end="[=-]\=%\@<!%\{1,'.s:eruby_nest_level.'\}>" contains=@rubyTop  containedin=ALLBUT,@erubyRegions keepend'
exe 'syn region  erubyExpression matchgroup=erubyDelimiter start="<%\{1,'.s:eruby_nest_level.'\}=\{1,4}" end="[=-]\=%\@<!%\{1,'.s:eruby_nest_level.'\}>" contains=@rubyTop  containedin=ALLBUT,@erubyRegions keepend'
exe 'syn region  erubyComment    matchgroup=erubyDelimiter start="<%\{1,'.s:eruby_nest_level.'\}-\=#"    end="[=-]\=%\@<!%\{1,'.s:eruby_nest_level.'\}>" contains=rubyTodo,@Spell containedin=ALLBUT,@erubyRegions keepend'

" Define the default highlighting.

hi def link erubyDelimiter		PreProc
hi def link erubyComment		Comment


let b:current_syntax = 'light_eruby'
