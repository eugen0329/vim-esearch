local parse = require'esearch/vim/parse'
local util  = require'esearch/util'

local M = {}

function M.render(data, esearch, parser)
  local parsed, lines_delta, errors = parse.lines(data, parser)
  local contexts     = esearch.contexts
  local wlnum2lnum   = esearch.wlnum2lnum
  local wlnum2ctx_id = esearch.wlnum2ctx_id
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

  for i = 0, #parsed - 1 do
    local entry = parsed[i]
    local filename, text, rev = entry.filename, entry.text, entry.rev

    -- IF new filename encountered
    if filename ~= contexts[#contexts - 1].filename then
      contexts[#contexts - 1]['end'] = line

      if util.is_true(esearch.slow_hl_enabled) and #contexts > win_contexts_syntax_clear_on_files_count then
        esearch.slow_hl_enabled = false
        vim.eval('esearch#out#win#stop_highlights("too many lines")')
      end

      -- add SEPARATOR
      b:insert('')
      wlnum2ctx_id:add(tostring(contexts[#contexts - 1].id))
      wlnum2lnum:add(false)
      line = line + 1

      -- add FILENAME
      b:insert(util.fnameescape(filename))
      contexts:add(vim.dict({
        ['id']            = tostring(tonumber(contexts[#contexts - 1].id) + 1),
        ['begin']         = tostring(line),
        ['end']           = false,
        ['filename']      = filename,
        ['filetype']      = false,
        ['loaded_syntax'] = false,
        ['lines']         = vim.dict(),
        ['rev']           = rev,
        }))
      ctx_by_name[filename] = contexts[#contexts - 1]
      wlnum2ctx_id:add(contexts[#contexts - 1].id)
      wlnum2lnum:add(false)
      files_count = files_count + 1
      line = line + 1
    end

    if text:len() > win_context_syntax_max_line_len then
      if text:len() > win_contexts_syntax_clear_on_line_len and util.is_true(esearch.slow_hl_enabled) then
        esearch.slow_hl_enabled = false
        vim.eval('esearch#out#win#stop_highlights("too long line encountered")')
      else
        contexts[#contexts - 1]['loaded_syntax'] = true
      end
    end

    -- add LINE
    b:insert(string.format(' %3d %s', entry.lnum, text))
    wlnum2ctx_id:add(contexts[#contexts - 1].id)
    wlnum2lnum:add(entry.lnum)
    contexts[#contexts - 1].lines[entry.lnum] = text
    line = line + 1
  end

  return tostring(files_count), tostring(lines_delta), errors
end

return M
