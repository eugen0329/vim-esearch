if exists('b:current_syntax')
  finish
endif

" based on vim builtin syntax

syn keyword es_rubyControl        and break in next not or redo rescue retry return
syn keyword es_rubyControl        case begin do for if unless while until else elsif ensure then when end
syn keyword es_rubyBoolean        true false
syn keyword es_rubyDefine         alias def undef  nextgroup=es_rubyFunction skipwhite
syn keyword es_rubyDefine         class module nextgroup=es_rubyConstant skipwhite
syn match   es_rubyFunction       "[a-b]*" contained
syn match   es_rubyConstant       "\<\u\w*"
syn keyword es_rubyKeyword        super yield
syn keyword es_rubyMacro          include extend prepend
syn keyword es_rubyPseudoVariable nil self __ENCODING__ __dir__ __FILE__ __LINE__ __callee__ __method__
syn region  es_rubyString         start=/\v"/ skip=/\v\\./ end=/\v"|^/
syn region  es_rubyString         start=/\v'/ skip=/\v\\./ end=/\v'|^/
syn match   es_rubyComment        "#.*"

hi def link es_rubyControl        Statement
hi def link es_rubyBoolean        Boolean
hi def link es_rubyDefine         Define
hi def link es_rubyFunction       Function
hi def link es_rubyConstant       Type
hi def link es_rubyKeyword        Keyword
hi def link es_rubyMacro          Macro
hi def link es_rubyPseudoVariable Constant
hi def link es_rubyString         String
hi def link es_rubyComment        Comment

let b:current_syntax = 'es_ctx_ruby'
