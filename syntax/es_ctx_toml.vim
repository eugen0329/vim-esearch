if exists('b:current_syntax')
  finish
endif

" based on cespare/vim-toml

syn keyword es_tomlBoolean    true false
syn region  es_tomlString     start=/"/ skip=/\\\\\|\\"/   end=/"/        oneline
syn region  es_tomlString     start=/"""/                  end=/"""/
syn region  es_tomlString     start=/'/                    end=/'/        oneline
syn region  es_tomlString     start=/'''/                  end=/'''/
syn region  es_tomlTable      start=/\[[^\[]/              end=/\]/       oneline
syn region  es_tomlTableArray start=/\s*\[\[/              end=/\]\]/     oneline
syn region  es_tomlKeyDq      start=/\v(|[{,])\s*\zs"/     end=/"\ze\s*=/ oneline
syn region  es_tomlKeySq      start=/\v(|[{,])\s*\zs'/     end=/'\ze\s*=/ oneline
syn match   es_tomlComment /#.*/
syn match   es_tomlKey     /\v(|[{,])\s*\zs[[:alnum:]._-]+\ze\s*\=/ display
syn match   es_tomlArray   /\v[{,=]\s*\zs[\[\]]/

hi def link es_tomlBoolean    Boolean
hi def link es_tomlString     String
hi def link es_tomlKeyDq      Identifier
hi def link es_tomlKeySq      Identifier
hi def link es_tomlTable      Title
hi def link es_tomlTableArray Title
hi def link es_tomlComment    Comment
hi def link es_tomlKey        Identifier

let b:current_syntax = 'es_ctx_toml'
