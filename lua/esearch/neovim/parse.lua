local PARSERS = require('esearch/shared/adapter/parse').PARSERS

local M = {}

local function entry_constructor(tbl)
  return tbl
end

function M.lines(data, parser)
  return PARSERS[parser](data, entry_constructor, 1)
end

return M
