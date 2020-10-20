local M = {}

M.ifirst = 1

function M.ilast(tbl)
  return #tbl
end

M.NIL = vim.NIL or {}

function M.list(tbl)
  return tbl
end

function M.dict(tbl)
  return tbl
end

function M.append(tbl, val)
  tbl[#tbl + 1] = val
end

function M.buf_get_lines(bufnr)
  return vim.api.nvim_buf_get_lines(bufnr or 0, 0, -1, true)
end

if vim.fn then -- neovim >= 0.5
  function M.json_decode(text)
    return vim.fn.json_decode(text)
  end

  function M.fnameescape(path)
    return vim.fn.fnameescape(path)
  end

  function M.filereadable(path, cache)
    if cache[path] then return true end
    local result = vim.fn.filereadable(path) == 1
    cache[path] = result
    return result
  end
else -- neovim < 0.5
  function M.json_decode(text)
    return vim.api.nvim_call_function('json_decode', {text})
  end

  function M.fnameescape(path)
    return vim.api.nvim_call_function('fnameescape', {path})
  end

  function M.filereadable(path, cache)
    if cache[path] then return true end
    local result = vim.api.nvim_call_function('filereadable', {path}) == 1
    cache[path] = result
    return result
  end
end

function M.debounce(callback, wait)
  local fn = {}

  setmetatable(fn, {__call = function(_, ...)
    if fn.timer then
      fn.timer:stop()
      if not fn.timer:is_closing() then
        fn.timer:close()
      end
    end
    fn.timer = M.set_timeout(callback, wait, ...)
  end})

  return fn
end

function M.set_timeout(callback, delay, ...)
  local timer = vim.loop.new_timer()
  local args = {...}
  timer:start(delay, 0, function()
    timer:stop()
    timer:close()
    callback(unpack(args))
  end)
  return timer
end

return M
