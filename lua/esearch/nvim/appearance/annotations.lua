local M = {
  ATTACHED_ANNOTATIONS = {},
  ANNOTATIONS_NS       = vim.api.nvim_create_namespace('esearch_annotations'),
}

local function on_lines(_event_name, bufnr, _changedtick, from, old_to, to, _old_byte_size)
  if to < old_to then -- if lines are removed
    vim.api.nvim_buf_clear_namespace(bufnr, M.ANNOTATIONS_NS, from, to + 1)
  end
end

local function on_detach(_, bufnr) -- ('detach', bufnr)
  M.ATTACHED_ANNOTATIONS[bufnr] = nil
end

function M.buf_attach_annotations()
  local bufnr = vim.api.nvim_get_current_buf()
  if not M.ATTACHED_ANNOTATIONS[bufnr] then
    M.ATTACHED_ANNOTATIONS[bufnr] = true
    vim.api.nvim_buf_attach(0, false, {on_lines=on_lines, on_detach=on_detach})
  end
end

function M.buf_clear_annotations()
  vim.api.nvim_buf_clear_namespace(0, M.ANNOTATIONS_NS, 0, -1)
end

function M.annotate(contexts)
  for _, ctx in pairs(contexts) do
    -- don't annotate the header or not finished contexts
    if ctx['id'] > 0 and ctx['end'] > 0 then
      M.set_context_len_annotation(ctx['begin'], ctx['end'] - ctx['begin'] - 1)
    end
  end
end

function M.set_context_len_annotation(line, size)
  local text = size == 1 and (size .. ' line') or (size .. ' lines')
  -- nvim_buf_set_virtual_text() replaced the text of the line, extmarks accumulate
  vim.api.nvim_buf_clear_namespace(0, M.ANNOTATIONS_NS, line - 1, line)
  pcall(vim.api.nvim_buf_set_extmark, 0, M.ANNOTATIONS_NS, line - 1, 0,
    {virt_text = {{text, 'Comment'}}, virt_text_pos = 'eol', strict = false})
end

return M
