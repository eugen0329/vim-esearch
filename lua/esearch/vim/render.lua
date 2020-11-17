local parse = require('esearch/vim/parse').parse
local util  = require('esearch/shared/util')
local ifirst, ilast = util.ifirst, util.ilast

local M = {}

function M.render(data, esearch, parser)
  local entries, lines_delta, errors = parse(data, parser)
  local contexts     = esearch.contexts
  local state = esearch.state
  local files_count  = esearch.files_count
  local ctx_by_name  = esearch.ctx_by_name
  local win_contexts_syntax_clear_on_files_count =
    vim.eval('g:esearch.win_contexts_syntax_clear_on_files_count')
  local win_context_syntax_max_line_len =
    vim.eval('g:esearch.win_context_syntax_clear_on_line_len')
  local win_contexts_syntax_clear_on_line_len =
    vim.eval('g:esearch.win_contexts_syntax_clear_on_line_len')

  local b = vim.buffer()
  local line = vim.eval('line("$") + 1')

  for i = ifirst, ilast(entries) do
    local entry = entries[i]
    local filename, text, rev = entry.filename, entry.text, entry.rev

    -- IF new filename encountered
    if filename ~= contexts[ilast(contexts)].filename then
      contexts[ilast(contexts)]['end'] = line

      if util.is_true(esearch.slow_hl_enabled) and #contexts > win_contexts_syntax_clear_on_files_count then
        esearch.slow_hl_enabled = false
        vim.eval('esearch#out#win#stop_highlights("too many lines")')
      end

      -- add SEPARATOR
      b:insert('')
      state:add(tostring(contexts[ilast(contexts)].id))
      line = line + 1

      -- add FILENAME
      b:insert(util.fnameescape(filename))
      contexts:add(vim.dict({
        ['id']            = tostring(tonumber(contexts[ilast(contexts)].id) + 1),
        ['begin']         = tostring(line),
        ['end']           = false,
        ['filename']      = filename,
        ['filetype']      = false,
        ['loaded_syntax'] = false,
        ['lines']         = vim.dict(),
        ['rev']           = tostring(rev),
        }))
      ctx_by_name[filename] = contexts[ilast(contexts)]
      state:add(contexts[ilast(contexts)].id)
      files_count = files_count + 1
      line = line + 1
    end

    if text:len() > win_context_syntax_max_line_len then
      if text:len() > win_contexts_syntax_clear_on_line_len and util.is_true(esearch.slow_hl_enabled) then
        esearch.slow_hl_enabled = false
        vim.eval('esearch#out#win#stop_highlights("too long line encountered")')
      else
        contexts[ilast(contexts)]['loaded_syntax'] = true
      end
    end

    -- add LINE
    b:insert(string.format(' %3d %s', entry.lnum, text))
    state:add(contexts[ilast(contexts)].id)
    contexts[ilast(contexts)].lines[entry.lnum] = text
    line = line + 1
  end

  return tostring(files_count), tostring(lines_delta), errors
end

return M
