local M = {}

function M.path_under_cursor()
  local api = require('nvim-tree.api')
  local node = api.tree.get_node_under_cursor()
  return node.absolute_path
end

function M.selected_nodes()
  local paths = {}
  for i, node in ipairs(require('nvim-tree.api').marks.list()) do
    table.insert(paths, node['absolute_path'])
  end
  return paths
end

return M
