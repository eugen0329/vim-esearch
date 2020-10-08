local PARSERS = require('esearch/shared/adapter/parse').PARSERS

local M = {}

local function entry_constructor(tbl)
  return tbl
end

function M.parse(data, parser)
  return PARSERS[parser](data, entry_constructor)
end

return M
