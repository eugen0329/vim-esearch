module VimlValue
  class ToRuby
    def accept(tree)
      visit(tree)
    end

    private

    def visit(node)
      send(:"visit_#{node.type}", node)
    end

    def visit_dict(node)
      node
        .children
        .map { |pair| visit_pair(pair) }
        .to_h
    end

    def visit_pair(pair)
      [visit_string(pair.children.first), visit(pair.children.last)]
    end

    def visit_list(node)
      node
        .children
        .map { |value| visit(value) }
    end

    def visit_value(node)
      node.children.first
    end
    alias visit_bool visit_value
    alias visit_null visit_value
    alias visit_string visit_value
    alias visit_number visit_value
  end
end
