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


-- Parse lines in format "filename"[-:]line_number[-:]text and unwrap the filename
local function parse_with_quoted_filename(line)
  local filename, lnum, text = code(line):match('"(.-)"[:%-](%d+)[:%-](.*)')
  if not filename then return end
  filename, lnum, text = decode(filename), decode(lnum), decode(text)
  filename = filename:gsub('\\(.)', CONTROL_CHARS)
  return filename, lnum, text
end

local function parse_existing_filename(line, cache)
  local filename, lnum, text
  local filename_end = 1

  while true do
    filename_end = line:find('[:%-]%d+[:%-]', filename_end + 1)
    if not filename_end then return end

    filename = line:sub(1, filename_end - 1)
    if filereadable(filename, cache) then
      lnum, text = line:match('(%d+)[:%-](.*)', filename_end)
      if not lnum then return end
      return filename, lnum, text
    end
  end
end

-- Captures existing or the smallest filename. Will output a wrong filename if
-- it contains [:%-] or is removed.
local function parse_filename_with_commit_prefix(line, cache)
  local filename_start = line:find('[:%-]')
  if not filename_start then return end
  filename_start = filename_start + 1
  local filename_end = filename_start
  local filename, min_filename_end, lnum, text

  if line:sub(filename_start, filename_start) == '"' then
    filename, lnum, text = parse_with_quoted_filename(line:sub(filename_start))
    if not filename or not lnum or not text then return end
    return line:sub(1, filename_start - 1) .. filename, lnum, text
  end

  while true do
    filename_end = line:find('[:%-]%d+[:%-]', filename_end + 1)
    if not filename_end then break end

    if not min_filename_end then min_filename_end = filename_end end

    filename = line:sub(filename_start, filename_end - 1)
    if filereadable(filename, cache) then
      lnum, text = line:match('(%d+)[:%-](.*)', filename_end)
      if not lnum then return end
      return line:sub(1, filename_end - 1), lnum, text
    end
  end

  if min_filename_end then
    lnum, text = line:match('(%d+)[:%-](.*)', min_filename_end)
    if not lnum then return end
    return line:sub(1, min_filename_end - 1), lnum, text
  end
end

function M.parse_line(line, cache)
  local filename, lnum, text
  local rev = nil -- flag to determine whether it belong to a git repo

  -- Heuristic to try the fastest matching
  filename, lnum, text = line:match('(.-)[:%-](%d+)[:%-](.*)')
  if filename and text and filereadable(filename, cache) then
    return filename, lnum, text, rev
  end

  -- if the line starts with "
  if line:sub(1, 1) == '"' then
    filename, lnum, text = parse_with_quoted_filename(line)
    if filename then return filename, lnum, text, rev end
  end

  filename, lnum, text = parse_existing_filename(line, cache)
  if not filename then
    filename, lnum, text = parse_filename_with_commit_prefix(line, cache)
    if filename then rev = true end
  end

  return filename, lnum, text, rev
end

return M
