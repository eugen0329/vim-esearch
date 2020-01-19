module VimlValue
  class ToRuby
    def accept(tree)
      visit(tree)
    end

    private

    def visit(node)
      send(:"visit_#{node.type}", node)
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
