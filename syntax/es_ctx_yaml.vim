if exists('b:current_syntax')
  finish
endif

" based on vim builtin syntax

syn keyword es_yamlNull null
syn keyword es_yamlBool true false

syn match es_yamlBlockMappingKey              /\zs[^ :]\+\ze\s*:/ nextgroup=es_yamlKeyValueDelimiter
syn match es_yamlMappingMerge                 /<<\ze\s*:/         nextgroup=es_yamlKeyValueDelimiter
syn match es_yamlKeyValueDelimiter            /\s*:/
syn match es_yamlFlowIndicator                /[{}\[\]]/
syn match es_yamlAnchorOrAnchor               /[&*][^ ]\+/
syn match es_yamlBlockCollectionItemStart     /-/

syn region es_yamlFlowString start=/"/ skip=/\\"/ end=/"\|^/
syn region es_yamlFlowString start=/'/ skip=/\\'/ end=/'\|^/
syn region es_yamlComment    start='\%\(^\|\s\)#' end='$' oneline 

hi def link es_yamlBlockMappingKey          Identifier
hi def link es_yamlKeyValueDelimiter        Special
hi def link es_yamlBool                     Boolean
hi def link es_yamlNull                     Constant
hi def link es_yamlAnchorOrAnchor           Type
hi def link es_yamlMappingMerge             Special
hi def link es_yamlFlowString               String
hi def link es_yamlFlowIndicator            Special
hi def link es_yamlComment                  Comment
hi def link es_yamlBlockCollectionItemStart Label

let b:current_syntax = 'es_ctx_json'
