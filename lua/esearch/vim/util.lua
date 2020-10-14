local M = {}


if vim.funcref('has')('patch-8.2.1066') == 1 then
  M.ifirst = 1
  function M.ilast(tbl)
    return #tbl
  end
else
  M.ifirst = 0
  function M.ilast(tbl)
    return #tbl - 1
  end
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
