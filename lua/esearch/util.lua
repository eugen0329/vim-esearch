local M = {}

if vim.api then
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
else -- vim
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
end

function M.map(tbl, cb)
  local mapped = {}
  for k, v in pairs(tbl) do mapped[k] = cb(v) end
  return mapped
end

function M.is_true(val)
  return val == 1 or val == true
end

-- From https://www.lua.org/pil/20.4.html. Is used to perform unquoting
function M.code(s)
  return (string.gsub(s, "\\([\\\"])", function (x)
            return string.format("\\%03d", string.byte(x))
          end))
end

function M.decode(s)
  return (string.gsub(s, "\\(%d%d%d)", function (d)
            return "\\" .. string.char(d)
          end))
end

return M
