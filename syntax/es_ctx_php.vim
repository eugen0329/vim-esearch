if exists('b:current_syntax')
  finish
endif

" based on vim builtin syntax

syn keyword es_phpConditional  declare else enddeclare endswitch elseif endif if switch
syn keyword es_phpRepeat       as do endfor endforeach endwhile for foreach while
syn keyword es_phpLabel        case default switch
syn keyword es_phpStatement    return break continue exit goto yield
syn keyword es_phpKeyword      var const
syn keyword es_phpStructure    namespace extends implements instanceof parent self
syn keyword es_phpConstant     __LINE__ __FILE__ __FUNCTION__ __METHOD__ __CLASS__ __DIR__ __NAMESPACE__ __TRAIT__
syn match   es_phpIdentifier   "$\h\w*"
syn region  es_phpComment      start="/\*" end="\*/\|^"
syn match   es_phpComment      "#.\{-}\(?>\|$\)\@="
syn match   es_phpComment      "//.\{-}\(?>\|$\)\@="
syn region  es_phpStringDouble start=/\v"/ skip=/\v\\./ end=/\v"|^/
syn region  es_phpStringSingle start=/\v'/ skip=/\v\\./ end=/\v'|^/

hi def link es_phpConditional Conditional
hi def link es_phpRepeat Repeat
hi def link es_phpLabel Label
hi def link es_phpStatement Statement
hi def link es_phpKeyword Statement
hi def link es_phpStructure Structure
hi def link es_phpIdentifier Identifier
hi def link es_phpConstant Constant
hi def link es_phpComment Comment
hi def link es_phpStringSingle String
hi def link es_phpStringDouble String


let b:current_syntax = 'es_ctx_php'
