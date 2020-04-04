if !g:esearch#has#lua
  finish
endif

fu! esearch#adapter#parse#lua#funcref() abort
  return function('esearch#adapter#parse#lua#parse')
endfu

if g:esearch#has#nvim_lua
  fu! esearch#adapter#parse#lua#parse(data, from, to) abort dict
    return luaeval('parse_lines(_A[1])', [a:data[a:from : a:to]])
  endfu
else
  fu! esearch#adapter#parse#lua#parse(data, from, to) abort dict
    return luaeval('parse_lines(_A[0])', [a:data[a:from : a:to]])
  endfu
endif

lua << EOF
function parse_line(line)
  local filename = ''

  -- At the moment only git adapter outputs lines that wrapped in "" when special
  -- characters are encountered
  if line:sub(1, 1) == '"' then
    local filename, line, text = code(line):match('"(.-)"[:%-](%d+)[:%-](.*)')
    if filename == nil then
      return
    end
    filename, line, text = decode(filename), decode(line), decode(text)

    local controls = {
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
    filename = filename:gsub('\\(.)', controls)
    if filereadable(filename) then
      return filename, line, text
    end
  end

  -- try to find the first readable filename
  local filename_end = 1
  while true do
    filename_end, _ = line:find('[:%-]%d+[:%-]', filename_end + 1)

    if filename_end == nil then
      return
    end

    filename = line:sub(1, filename_end - 1)
    if filereadable(filename) then
      break
    end
  end

  local line, text = line:match('(%d+)[:%-](.*)', filename_end)
  if line == nil or text == nil then
    return
  end

  return filename, line, text
end

-- From https://www.lua.org/pil/20.4.html. Is used to perform unquoting
function code(s)
  return (string.gsub(s, "\\([\\\"])", function (x)
            return string.format("\\%03d", string.byte(x))
          end))
end

function decode(s)
  return (string.gsub(s, "\\(%d%d%d)", function (d)
            return "\\" .. string.char(d)
          end))
end
EOF

if g:esearch#has#nvim_lua
lua << EOF

filereadable_cache = {}

function filereadable(path)
  if filereadable_cache[path] then
    return true
  end
  local result = vim.api.nvim_call_function('filereadable', {path})

  if result == 1 then
    filereadable_cache[path] = true;
    return true
  else
    filereadable_cache[path] = false;
    return false
  end
end

function fnameescape(path)
  return vim.api.nvim_call_function('fnameescape', {path})
end

function parse_lines(data)
  local parsed = {}
  local separators_count = 0
  -- must be invalidated across calls to prevent using stale file presence information
  filereadable_cache = {}

  for i = 1, #data do
    local line = data[i]

    if line:len() == 0 or line == '--' then
      separators_count = separators_count + 1
    else
      -- Heuristic to try the fastest matching with a fallback to the comprehensive algorithm
      local filename, lnum, text = line:match('(.-)[:%-](%d+)[:%-](.*)')
      if filename == nil or text == nil or not filereadable(filename) then
        filename, lnum, text = parse_line(line)
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

EOF
else
lua << EOF

filereadable_cache = {}

function filereadable(path)
  if filereadable_cache[path] then
    return true
  end
  local result = vim.funcref('filereadable')(path)

  if result == 1 then
    filereadable_cache[path] = true;
    return true
  else
    filereadable_cache[path] = false;
    return false
  end
end

function fnameescape(path)
  return vim.funcref('fnameescape')(path)
end

-- parse lines in format filename[-:]line_number[-:]text
function parse_lines(data)
  local parsed = vim.list()
  local separators_count = 0
  -- must be invalidated across calls to prevent using stale file presence information
  filereadable_cache = {}

  for i = 0, #data - 1 do
    local line = data[i]

    if line:len() == 0 or line == '--' then
      separators_count = separators_count + 1
    else
      -- Heuristic to try the fastest matching with a fallback to the comprehensive algorithm
      local filename, lnum, text = line:match('(.-)[:%-](%d+)[:%-](.*)')
      if filename == nil or text == nil or not filereadable(filename) then
        filename, lnum, text = parse_line(line)
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

EOF
endif
