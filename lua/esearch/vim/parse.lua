local util = require'esearch/util'

local M = {}

-- parse lines in format filename[-:]line_number[-:]text
function M.lines(data)
  local parsed = vim.list()
  local separators_count = 0
  -- must be invalidated across calls to prevent using stale file presence information
  local cache = {}

  print(#data)
  print(data[0])
  print(data[1])

  for line in data() do
    print(line)
    if line:len() == 0 or line == '--' then
      separators_count = separators_count + 1
    else
      -- Heuristic to try the fastest matching with a fallback to the comprehensive algorithm
      local filename, lnum, text = line:match('(.-)[:%-](%d+)[:%-](.*)')
      if filename == nil or text == nil or not util.filereadable(filename, cache) then
        filename, lnum, text = util.parse_line(line, cache)
      end

      if filename ~= nil  then
        parsed:add(vim.dict({
          ['filename'] = filename,
          ['lnum']     = lnum,
          ['text']     = text:gsub("[\r\n]", '')
        }))
      end
    end
  end

  return parsed, separators_count
end

return M
