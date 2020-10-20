local PARSERS = require('esearch/shared/adapter/parse').PARSERS

local M = {}

function M.parse(data, parser)
  local entries, lines_delta, errors = PARSERS[parser](data, vim.dict)
  return vim.list(entries), lines_delta, errors
end

return M
