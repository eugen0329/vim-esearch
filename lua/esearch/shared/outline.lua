local util = require('esearch/shared/util')
local list, dict, buf_get_lines = util.list, util.dict, util.buf_get_lines

local M = {}

function M.extract_headings(bufnr)
  local headings = {}
  local lines = buf_get_lines(bufnr)
  for lnum = 1, #lines do
    local word = lines[lnum]
    if lnum > 2 and word:len() > 0 and word:sub(1, 1) ~= ' ' then
      headings[#headings + 1] = dict({
        lnum = tostring(lnum),
        word = word,
        ['type'] = 'filename',
        level = '1',
      })
    end
  end

  return list(headings)
end

return M
