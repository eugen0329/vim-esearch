local parse_line = require('esearch/shared/adapter/parse').parse_line

local M = {}

-- parse lines in format filename[-:]line_number[-:]text
function M.lines(data)
  local parsed = {}
  local separators_count = 0
  -- must be invalidated across calls to prevent using stale file presence information
  local cache = {}
  local filename, lnum, text, rev

  for i = 1, #data do
    local line = data[i]

    if line:len() == 0 or line == '--' then
      separators_count = separators_count + 1
    else
      filename, lnum, text, rev = parse_line(line, cache)

      if filename then
        parsed[#parsed + 1] = {
          ['filename'] = filename,
          ['lnum']     = lnum,
          ['text']     = text:gsub("[\r\n]", ''),
          ['rev']      = rev,
        }
      end
    end
  end

  return parsed, separators_count
end

return M
