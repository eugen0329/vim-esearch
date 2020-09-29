local M = {
  ATTACHED_ANNOTATIONS = {},
  ANNOTATIONS_NS       = vim.api.nvim_create_namespace('esearch_annotations'),
}

local function on_lines(_event_name, bufnr, _changedtick, from, old_to, to, _old_byte_size)
  if to < old_to then -- if lines are removed
    vim.api.nvim_buf_clear_namespace(bufnr, M.ANNOTATIONS_NS, from, to + 1)
  end
end

local function on_detach(bufnr)
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
  if size == 1 then
    vim.api.nvim_buf_set_virtual_text(0, M.ANNOTATIONS_NS, line - 1, {{size .. ' line', 'Comment'}}, {})
  else
    vim.api.nvim_buf_set_virtual_text(0, M.ANNOTATIONS_NS, line - 1, {{size .. ' lines', 'Comment'}}, {})
  end
end

return M
