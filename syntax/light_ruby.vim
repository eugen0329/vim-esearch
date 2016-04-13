if exists('b:current_syntax')
  finish
endif

syn match rubyControl	       "\<\%(and\|break\|in\|next\|not\|or\|redo\|rescue\|retry\|return\)\>[?!]\@!"
syn match rubyControl "\<def\>[?!]\@!"    nextgroup=rubyMethodDeclaration skipwhite skipnl
syn match rubyControl "\<class\>[?!]\@!"  nextgroup=rubyModuleDeclaration  skipwhite skipnl
syn match rubyControl "\<module\>[?!]\@!" nextgroup=rubyModuleDeclaration skipwhite skipnl
syn match rubyControl "\<\%(case\|begin\|do\|for\|if\|unless\|while\|until\|else\|elsif\|ensure\|then\|when\|end\)\>[?!]\@!"
syn match rubyKeyword "\<\%(alias\|undef\)\>[?!]\@!"
hi def link rubyControl Define



syn match  rubyMethodDeclaration   "[^[:space:];#(]\+"	 contained contains=rubyConstant,rubyBoolean,rubyPseudoVariable,rubyInstanceVariable,rubyClassVariable,rubyGlobalVariable
syn match  rubyModuleDeclaration   "[^[:space:];#<]\+"	 contained contains=rubyConstant,rubyOperator
hi def link rubyMethodDeclaration Function
hi def link rubyModuleDeclaration rubyMethodDeclaration


syn match   rubyPseudoVariable "\<\%(nil\|self\|__ENCODING__\|__dir__\|__FILE__\|__LINE__\|__callee__\|__method__\)\>[?!]\@!" " TODO: reorganise
hi def link rubyPseudoVariable		Constant



syntax region rubyString start=/\v"/ skip=/\v\\./ end=/\v"|$/
syntax region rubyString start=/\v'/ skip=/\v\\./ end=/\v'|$/
highlight link rubyString String


syn match  rubyMethodDeclaration   "[^[:space:];#(]\+"	 contained contains=rubyConstant,rubyBoolean,rubyPseudoVariable,rubyInstanceVariable,rubyClassVariable,rubyGlobalVariable

syn match   rubyComment   "#.*"
hi def link rubyComment			Comment
" syn match rubyKeyword "\<\%(alias\|undef\)\>[?!]\@!"





syn match  rubySymbol		"\%([{(,]\_s*\)\@<=\l\w*[!?]\=::\@!"he=e-1
syn match  rubySymbol "[]})\"':]\@<!:\%(\$\|@@\=\)\=\%(\h\|[^\x00-\x7F]\)\%(\w\|[^\x00-\x7F]\)*"
hi def link rubySymbol			Constant


let b:current_syntax = 'light_ruby'

