local util = require('esearch/util')
local code, decode, filereadable = util.code, util.decode, util.filereadable

local M = {}

local CONTROL_CHARS = {
  a      = '\a',
  b      = '\b',
  t      = '\t',
  n      = '\n',
  v      = '\v',
  f      = '\f',
  r      = '\r',
  z      = '\z',
  ['\\'] = '\\',
  ['\"'] = '\"',
  ['\033'] = string.char(27)
}

-- Parse lines in format "name"[-:]line_number[-:]text and unwrap the name
local function parse_with_quoted_name(line)
  local name, lnum, text = code(line):match('"(.-)"[:%-](%d+)[:%-](.*)')
  if not name then return end
  return (decode(name):gsub('\\(.)', CONTROL_CHARS)), decode(lnum), decode(text)
end

local function parse_from_pos(line, from)
  local lnum, text = line:match('(%d+)[:%-](.*)', from)
  if not lnum then return end
  return line:sub(1, from - 1), lnum, text
end

local function parse_existing_name(line, cache)
  local name_end = 1

  while true do
    name_end = line:find('[:%-]%d+[:%-]', name_end + 1)
    if not name_end then return end

    local name = line:sub(1, name_end - 1)
    if filereadable(name, cache) then
      return parse_from_pos(line, name_end)
    end
  end
end

-- Heuristic to captures existing quoted, existing unquoted or the smallest
-- name.
local function parse_name_with_revision_prefix(line, cache)
  local name_start = line:find('[:%-]')
  if not name_start then return end
  name_start = name_start + 1
  local name_end = name_start
  local name, lnum, text
  local min_name_end, quoted_name_end, quoted_entry

  -- try QUOTED
  if line:sub(name_start, name_start) == '"' then
    name, lnum, text = parse_with_quoted_name(line:sub(name_start))
    if name then
      quoted_entry = {line:sub(1, name_start - 1) .. name, lnum, text}
      if filereadable(name, cache) then return unpack(quoted_entry) end
      quoted_name_end = name_start + name:len() + 2
    end
  end

  -- try EXISTING
  while true do
    name_end = line:find('[:%-]%d+[:%-]', name_end + 1)
    if not name_end then break end
    if not min_name_end then min_name_end = name_end end

    name = line:sub(name_start, name_end - 1)
    if filereadable(name, cache) then
      return parse_from_pos(line, name_end)
    end
  end

  -- try the SMALLEST of min and quoted names
  if quoted_name_end and min_name_end then
    if quoted_name_end < min_name_end then
      return unpack(quoted_entry)
    end
    return parse_from_pos(line, min_name_end)
  elseif quoted_name_end then
    return unpack(quoted_entry)
  elseif min_name_end then
    return parse_from_pos(line, min_name_end)
  end
end

function M.parse_line(line, cache)
  local name, lnum, text
  local rev = nil -- flag to determine whether it belong to a git repo

  -- try the fastest matching
  name, lnum, text = line:match('(.-)[:%-](%d+)[:%-](.*)')
  if name and text and filereadable(name, cache) then return name, lnum, text, rev end

  -- if the line starts with "
  if line:sub(1, 1) == '"' then
    name, lnum, text = parse_with_quoted_name(line)
    print('asd', name, filereadable(name, cache))
    if name and filereadable(name, cache) then return name, lnum, text, rev end
  end

  name, lnum, text = parse_existing_name(line, cache)
  if not name then
    name, lnum, text = parse_name_with_revision_prefix(line, cache)
    if name then rev = true end
  end

  return name, lnum, text, rev
end

return M
