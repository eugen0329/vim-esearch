local PARSERS = require('esearch/shared/adapter/parse').PARSERS

local M = {}

function M.lines(data, parser)
  local entries, separators_count, errors = PARSERS[parser](data, vim.dict, 0)
  return vim.list(entries), separators_count, errors
end

return M
