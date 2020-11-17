local matches       = require('esearch/nvim/appearance/matches')
local annotations   = require('esearch/nvim/appearance/annotations')
local ui            = require('esearch/nvim/appearance/ui')
local cursor_linenr = require('esearch/nvim/appearance/cursor_linenr')

return {
  ANNOTATIONS_NS              = annotations.ANNOTATIONS_NS,
  ATTACHED_ANNOTATIONS        = annotations.ATTACHED_ANNOTATIONS,
  set_context_len_annotation  = annotations.set_context_len_annotation,
  annotate                    = annotations.annotate,
  buf_clear_annotations       = annotations.buf_clear_annotations,
  buf_attach_annotations      = annotations.buf_attach_annotations,

  MATCHES_NS                  = matches.MATCHES_NS,
  ATTACHED_MATCHES            = matches.ATTACHED_MATCHES,
  deferred_highlight_viewport = matches.deferred_highlight_viewport,
  highlight_viewport          = matches.highlight_viewport,
  buf_attach_matches          = matches.buf_attach_matches,

  UI_NS                       = ui.UI_NS,
  ATTACHED_UI                 = ui.ATTACHED_UI,
  highlight_header            = ui.highlight_header,
  buf_attach_ui               = ui.buf_attach_ui,
  highlight_ui                = ui.highlight_ui,

  CURSOR_LINENR_NS            = cursor_linenr.CURSOR_LINENR_NS,
  highlight_cursor_linenr     = cursor_linenr.highlight_cursor_linenr,

  render                      = require('esearch/nvim/render').render,
  parse                       = require('esearch/nvim/parse').parse,
  util                        = require('esearch/shared/util'),
  extract_headings            = require('esearch/shared/outline').extract_headings,
}
