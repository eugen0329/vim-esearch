if exists('b:current_syntax')
  finish
endif

syn keyword rubyControl        and break in next not or redo rescue retry return
syn keyword rubyControl        case begin do for if unless while until else elsif ensure then when end
syn keyword rubyBoolean        true false
syn keyword rubyDefine         alias def undef class module
syn keyword rubyKeyword        super yield
syn keyword rubyPseudoVariable nil self __ENCODING__ __dir__ __FILE__ __LINE__ __callee__ __method__

syntax region rubyString start=/\v"/ skip=/\v\\./ end=/\v"|$/
syntax region rubyString start=/\v'/ skip=/\v\\./ end=/\v'|$/

syn match   rubyComment   "#.*"

hi def link rubyControl        Statement
hi def link rubyBoolean        Boolean
hi def link rubyDefine         Define
hi def link rubyKeyword        Keyword
hi def link rubyPseudoVariable Constant
hi def link rubyString         String
hi def link rubyComment        Comment

let b:current_syntax = 'win_context_ruby'
