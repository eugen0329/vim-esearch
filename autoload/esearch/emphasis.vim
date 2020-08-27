let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
      \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()

let s:sign_name  = 'esearchEmphasisSign'
let s:sign_group = 'esearchEmphasisSigns'
let s:sign_id    = 502012117
" Prio should be big enought to overrule the less important signs at the moment
" of previewing like from linters etc.
let s:priority   = 1000
let s:line_ns = nvim_create_namespace('esearch_line_emphasis')

fu! esearch#emphasis#sign() abort
  return s:SignEmphasis
endfu

fu! esearch#emphasis#highlighted_line() abort
  return s:HighlightLineEmphasis
endfu

let s:Base = {}

fu! s:Base.new(win_handle, line) abort dict
  let instance            = copy(self)
  let instance.win_handle = a:win_handle
  let instance.line       = a:line + 0
  let instance.signcolumn = s:null
  let instance.bufnr = esearch#win#bufnr(a:win_handle)

  return instance
endfu

let s:SignEmphasis = copy(s:Base)

fu! s:SignEmphasis.place() abort dict
  if empty(sign_getdefined(s:sign_name))
    call sign_define(s:sign_name, {'text': g:esearch#unicode#arrow_right})
  endif

  let self.signcolumn = esearch#win#let_restorable(
        \ self.win_handle, {'&signcolumn': 'auto'})

  noau call sign_place(s:sign_id,
        \ s:sign_group,
        \ s:sign_name,
        \ self.bufnr,
        \ {'lnum': self.line, 'priority': s:priority})

  return self
endfu

fu! s:SignEmphasis.unplace() abort dict
  call sign_unplace(s:sign_group, {'id': s:sign_id})
  call self.signcolumn.restore()
endfu

let s:HighlightLineEmphasis = copy(s:Base)

fu! s:HighlightLineEmphasis.place() abort dict
  call nvim_buf_add_highlight(self.bufnr, s:line_ns, 'esearchMatch', self.line - 1, 0, -1)

  return self
endfu

fu! s:HighlightLineEmphasis.unplace() abort dict
  call nvim_buf_clear_namespace(self.bufnr, s:line_ns, 0, -1)
endfu
