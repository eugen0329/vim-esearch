let g:esearch#emphasis#default = []
let s:sign_name  = 'esearchEmphasisSign'
let s:sign_group = 'esearchEmphasisSigns'
let s:sign_id    = 502012117
" Prio should be big enought to overrule less important signs at the moment
" of previewing like linter signs etc.
let s:priority   = 1000

fu! esearch#emphasis#sign() abort
  return s:SignEmphasis
endfu

fu! esearch#emphasis#highlighted_line() abort
  return s:HighlightLineEmphasis
endfu

let s:Base = {}

fu! s:Base.new(win_handle, lnum) abort dict
  let instance            = copy(self)
  let instance.win_handle = a:win_handle
  let instance.lnum       = +a:lnum
  let instance.bufnr      = esearch#win#bufnr(a:win_handle)

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
        \ {'lnum': self.lnum, 'priority': s:priority})

  return self
endfu

fu! s:SignEmphasis.unplace() abort dict
  call sign_unplace(s:sign_group, {'id': s:sign_id})
  call self.signcolumn.restore()
endfu

let g:esearch#emphasis#default += [esearch#emphasis#sign()]

let s:HighlightLineEmphasis = copy(s:Base)

if g:esearch#has#nvim_add_highlight
  let s:line_ns = nvim_create_namespace('esearch_line_emphasis')
  fu! s:HighlightLineEmphasis.place() abort dict
    call nvim_buf_add_highlight(self.bufnr, s:line_ns, 'esearchMatch', self.lnum - 1, 0, -1)

    return self
  endfu

  fu! s:HighlightLineEmphasis.unplace() abort dict
    if !nvim_buf_is_loaded(self.bufnr) | return | endif
    call nvim_buf_clear_namespace(self.bufnr, s:line_ns, 0, -1)
  endfu

  let g:esearch#emphasis#default += [esearch#emphasis#highlighted_line()]
elseif g:esearch#has#matchadd_win
  fu! s:HighlightLineEmphasis.place() abort dict
    let self.winid = esearch#win#id(self.win_handle)
    let self.id = matchaddpos('esearchMatch', [self.lnum], 1, -1, {'window': self.winid})

    return self
  endfu

  fu! s:HighlightLineEmphasis.unplace() abort dict
    if winbufnr(self.winid) == -1 | return | endif
    call matchdelete(self.id, self.winid)
  endfu

  let g:esearch#emphasis#default += [esearch#emphasis#highlighted_line()]
endif
