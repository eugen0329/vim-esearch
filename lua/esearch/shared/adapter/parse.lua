local util = require('esearch/shared/util')
local code = util.code
local decode = util.decode
local filereadable = util.filereadable
local json_decode = util.json_decode
local ifirst, ilast = util.ifirst, util.ilast
local NIL = util.NIL
local list, append = util.list, util.append

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

function M.parse_line_generic(line, cache)
  local name, lnum, text
  local rev = nil -- flag to determine whether it belong to a git repo

  -- try the fastest matching
  name, lnum, text = line:match('(.-)[:%-](%d+)[:%-](.*)')
  if name and text and filereadable(name, cache) then return name, lnum, text, rev end

  -- if the line starts with "
  if line:sub(1, 1) == '"' then
    name, lnum, text = parse_with_quoted_name(line)
    if name and filereadable(name, cache) then return name, lnum, text, rev end
  end

  name, lnum, text = parse_existing_name(line, cache)
  if not name then
    name, lnum, text = parse_name_with_revision_prefix(line, cache)
    if name then rev = true end
  end

  return name, lnum, text, rev
end

-- Parse lines in format (rev:)?filename[-:]line_number[-:]column_number[-:]text
function M.parse_line_with_column_number(line, cache)
  local name, lnum, text
  local rev = nil
  name, lnum, text = line:match('(.-)[:%-](%d+)[:%-]%d+[:%-](.*)')
  if name and text and filereadable(name, cache) then return name, lnum, text, rev end

  local name_end = 1
  while true do
    name_end = line:find('[:%-]%d+[:%-]%d+[:%-]', name_end + 1)
    if not name_end then return end

    name = line:sub(1, name_end - 1)
    if filereadable(name, cache) then
      lnum, text = line:match('[:%-](%d+)[:%-]%d+[:%-](.*)', name_end)
      return name, lnum, text, rev
    end
  end
end

-- Parse lines in JSON format from semgrep adapter
function M.parse_semgrep(lines, entry)
  local filename, lnum
  local entries = {}
  local errors = list({})

  for i = ifirst, ilast(lines)  do
    local line = lines[i]
    local json = json_decode(line)

    if errors and json.errors ~= {} then
      for j = ifirst, ilast(json.errors)  do
        append(errors, json.errors[j].long_msg)
      end
    end

    if json.results and json.results ~= {} then
      for j = ifirst, ilast(json.results)  do
        local result = json.results[j]
        filename = result.path

        local l = result.start.line
        for text in result.extra.lines:gmatch("([^\n]+)") do
          lnum = tostring(l)
          entries[#entries + 1] = entry({
            filename = filename,
            lnum = lnum,
            text  = text,
          })
          l = l + 1
        end

        if l - 1 ~= result['end'].line then
          print('semgrep: wrong lines parsing')
        end
      end
    end
  end

  local lines_delta = #lines - #entries
  return entries, lines_delta, errors
end

function M.parse(parser_function, lines, entry)
  local lines_delta = 0
  local filename, lnum, text, rev
  local cache = {}

  local entries = {}
  for i = ifirst, ilast(lines)  do
    local line = lines[i]

    if line:len() == 0 or line == '--' then
      lines_delta = lines_delta + 1
    else
      filename, lnum, text, rev = parser_function(line, cache)
      if filename then
        entries[#entries + 1] = entry({
          filename = filename,
          lnum     = lnum,
          text     = text:gsub("[\r\n]", ''),
          rev      = rev,
        })
      end
    end
  end

  local errors = NIL
  return entries, lines_delta, errors
end

M.PARSERS = {
  generic  = function(...) return M.parse(M.parse_line_generic, ...)            end,
  with_col = function(...) return M.parse(M.parse_line_with_column_number, ...) end,
  semgrep  = function(...) return M.parse_semgrep(...)                          end
}

return M
