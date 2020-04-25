fu! esearch#adapter#ag#new() abort
  return copy(s:Ag)
endfu

let s:Ag = esearch#adapter#base#import()
if exists('g:esearch#adapter#ag#bin')
  " TODO warn deprecated
  let s:Ag.bin = g:esearch#adapter#ag#bin
else
  let s:Ag.bin = 'ag'
endif
if exists('g:esearch#adapter#ag#options')
  " TODO warn deprecated
  let s:Ag.options = g:esearch#adapter#ag#options
else
  let s:Ag.options = '--follow'
endif
let s:Ag.mandatory_options = '--nogroup --nocolor --noheading --nobreak'
let s:Ag.spec = {
      \   'bool2regex': ['literal', 'pcre'],
      \   'regex': {
      \     'literal':   {'icon': '',  'option': '--fixed-strings'},
      \     'pcre':      {'icon': 'r', 'option': ''},
      \   },
      \   'bool2textobj': ['none', 'word'],
      \   'textobj': {
      \     'none':      {'icon': '',  'option': ''},
      \     'word':      {'icon': 'w', 'option': '--word-regexp'},
      \   },
      \   'bool2case': ['ignore', 'sensitive'],
      \   'case': {
      \     'ignore':    {'icon':  '', 'option': '--ignore-case'},
      \     'sensitive': {'icon': 's', 'option': '--case-sensitive'},
      \     'smart':     {'icon': 'S', 'option': '--smart-case'},
      \   }
      \ }

" ag --list-file-types
let s:Ag.spec.filetypes = split('actionscript ada asciidoc apl asm batch bitbake bro cc cfmx chpl clojure coffee coq cpp crystal csharp css cython delphi dlang dot dts ebuild elisp elixir elm erlang factor fortran fsharp gettext glsl go groovy haml handlebars haskell haxe hh html idris ini ipython isabelle j jade java jinja2 js json jsp julia kotlin less liquid lisp log lua m4 make mako markdown mason matlab mathematica md mercury naccess nim nix objc objcpp ocaml octave org parrot pdb perl php pike plist plone proto pug puppet python qml racket rake restructuredtext rs r rdoc ruby rust salt sass scala scheme shell smalltalk sml sql stata stylus swift tcl terraform tex thrift tla tt toml ts twig vala vb velocity verilog vhdl vim wix wsdl wadl xml yaml')

fu! s:Ag.is_success(request) abort
  " https://github.com/ggreer/the_silver_searcher/issues/1298
  return a:request.status == 0
        \ || (a:request.status == 1 && empty(a:request.errors) && empty(a:request.data))
endfu
