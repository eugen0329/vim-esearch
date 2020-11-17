local M

if vim.api then
  M = require('esearch/nvim/util')
else
  M = require('esearch/vim/util')
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

function M.is_true(val)
  return val == 1 or val == true
end

return M
