local PARSERS = require('esearch/shared/adapter/parse').PARSERS

local M = {}

-- parse lines in format filename[-:]line_number[-:]text
function M.lines(data, parser)
  local parsed = vim.list()
  local separators_count = 0
  -- must be invalidated across calls to prevent using stale file presence information
  local cache = {}
  local filename, lnum, text, rev
  local parse_line = PARSERS[parser]

  for line in data() do
    if line:len() == 0 or line == '--' then
      separators_count = separators_count + 1
    else
      filename, lnum, text, rev = parse_line(line, cache)
      if filename then
        parsed:add(vim.dict({
          filename = filename,
          lnum     = lnum,
          text     = text:gsub("[\r\n]", ''),
          rev      = rev,
        }))
      end
    end
  end

  return parsed, separators_count
end

return M
