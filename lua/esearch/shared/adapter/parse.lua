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


local function parse_quoted_filename(line, cache)
  local filename, lnum, text = code(line):match('"(.-)"[:%-](%d+)[:%-](.*)')
  if not filename then return end
  filename, lnum, text = decode(filename), decode(lnum), decode(text)

  filename = filename:gsub('\\(.)', CONTROL_CHARS)
  if filereadable(filename, cache) then
    return filename, lnum, text
  end
end

local function parse_existing_filename(line, cache)
  local filename
  local filename_end = 1

  while true do
    filename_end = line:find('[:%-]%d+[:%-]', filename_end + 1)
    if not filename_end then return end

    filename = line:sub(1, filename_end - 1)
    if filereadable(filename, cache) then
      return filename, filename_end
    end
  end
end

-- Captures existing or the smallest filename. Will output a wrong filename if
-- it contains [:%-] or is removed.
local function parse_filename_with_commit_prefix(line, cache)
  local filename_start = line:find('[:%-]') + 1
  local filename_end = filename_start
  local filename, min_filename_end

  while true do
    filename_end = line:find('[:%-]%d+[:%-]', filename_end + 1)
    if not filename_end then break end

    if not min_filename_end then min_filename_end = filename_end end

    filename = line:sub(filename_start, filename_end - 1)
    if filereadable(filename, cache) then
      return line:sub(1, filename_end - 1), filename_end
    end
  end

  if min_filename_end then
    return line:sub(1, min_filename_end - 1), min_filename_end
  end
end

function M.parse_line(line, cache)
  local filename, filename_end, lnum, text
  local rev = nil -- flag to determine whether it belong to a git repo

  -- Heuristic to try the fastest matching
  filename, lnum, text = line:match('(.-)[:%-](%d+)[:%-](.*)')
  if filename and text and filereadable(filename, cache) then
    return filename, lnum, text, rev
  end

  -- if the line starts with "
  if line:sub(1, 1) == '"' then
    filename, lnum, text = parse_quoted_filename(line, cache)
    if filename then return filename, lnum, text, rev end
  end

  filename, filename_end = parse_existing_filename(line, cache)
  if not filename then
    filename, filename_end = parse_filename_with_commit_prefix(line, cache)
    if filename then rev = true end
  end

  lnum, text = line:match('(%d+)[:%-](.*)', filename_end)
  if not lnum or not text then return end

  return filename, lnum, text, rev
end

return M
