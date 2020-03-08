if exists('b:current_syntax')
  finish
endif

syn match  es_dockerfileComment "#.*" display
syn region es_dockerfileString start=/\v"/ skip=/\v\\./ end=/\v"|^/ display
syntax case ignore
syntax keyword es_dockerfileKeyword ADD ARG CMD COPY ENTRYPOINT ENV EXPOSE HEALTHCHECK LABEL MAINTAINER ONBUILD RUN SHELL STOPSIGNAL USER VOLUME WORKDIR AS

hi def link es_dockerfileComment Comment
hi def link es_dockerfileString  String
hi def link es_dockerfileKeyword Keyword

let b:current_syntax = 'es_ctx_dockerfile'
