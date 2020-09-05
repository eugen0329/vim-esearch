local M = {}

if vim.fn then -- neovim >= 0.5
  function M.fnameescape(path)
    return vim.fn.fnameescape(path)
  end

  function M.filereadable(path, cache)
    if cache[path] then return true end
    local result = vim.fn.filereadable(path) == 1
    cache[path] = result
    return result
  end
elseif vim.api then -- neovim < 0.5
  function M.fnameescape(path)
    return vim.api.nvim_call_function('fnameescape', {path})
  end

  function M.filereadable(path, cache)
    if cache[path] then return true end
    local result = vim.api.nvim_call_function('filereadable', {path}) == 1
    cache[path] = result
    return result
  end
else -- vim
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
