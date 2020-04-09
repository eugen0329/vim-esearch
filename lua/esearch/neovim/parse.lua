local util = require'esearch/util'

local function parse_lines(data)
  local parsed = {}
  local separators_count = 0
  -- must be invalidated across calls to prevent using stale file presence information
  local cache = {}

  for i = 1, #data do
    local line = data[i]

    if line:len() == 0 or line == '--' then
      separators_count = separators_count + 1
    else
      -- Heuristic to try the fastest matching with a fallback to the comprehensive algorithm
      local filename, lnum, text = line:match('(.-)[:%-](%d+)[:%-](.*)')
      if filename == nil or text == nil or not util.filereadable(filename, cache) then
        filename, lnum, text = util.parse_line(line, cache)
      end

      if filename ~= nil then
        parsed[#parsed + 1] = {
          ['filename'] = filename,
          ['lnum']     = lnum,
          ['text']     = text:gsub("[\r\n]", '')
        }
      end
    end
  end

  return parsed, separators_count
end

local parse = {
  lines = parse_lines,
}

return parse
