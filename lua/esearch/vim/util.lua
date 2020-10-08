local M = {}

M.start = 0
function M.stop(tbl)
  return #tbl - 1
end
M.NIL = vim.list()

function M.list(tbl)
  return vim.list(tbl)
end

function M.dict(tbl)
  return vim.dict(tbl)
end

function M.append(tbl, val)
  tbl:add(val)
end

function M.json_decode(text)
  return vim.funcref('json_decode')(text)
end

function M.fnameescape(path)
  return vim.funcref('fnameescape')(path)
end

function M.filereadable(path, cache)
  if cache[path] then return true end
  local result = vim.funcref('filereadable')(path) == 1
  cache[path] = result
  return result
end

function M.buf_get_lines(bufnr)
  return vim.buffer(bufnr)
end

return M
