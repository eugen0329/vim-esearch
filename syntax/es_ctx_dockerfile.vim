if exists('b:current_syntax')
  finish
endif

" based on vim builtin syntax

syn match  es_dockerfileComment "#.*" display
syn region es_dockerfileString start=/\v"/ skip=/\v\\./ end=/\v"|^/ display
" To prevent matching with a commonly used docker-entrypoint.sh only uppercase
" are allowed
syntax keyword es_dockerfileKeyword ADD ARG CMD COPY ENTRYPOINT ENV EXPOSE HEALTHCHECK LABEL MAINTAINER ONBUILD RUN SHELL STOPSIGNAL USER VOLUME WORKDIR AS FROM

hi def link es_dockerfileComment Comment
hi def link es_dockerfileString  String
hi def link es_dockerfileKeyword Keyword

let b:current_syntax = 'es_ctx_dockerfile'
