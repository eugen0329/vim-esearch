# frozen_string_literal: true

class VimlValue::Visitors::ToRuby
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

  def visit_list(node)
    node
      .children
      .map { |value| visit(value) }
  end

  def visit_pair(pair)
    [visit_string(pair.children.first), visit(pair.children.last)]
  end

  def visit_none(_node)
    VimlValue::Types::None.new
  end

  def visit_funcref(node)
    VimlValue::Types::Funcref.new(
      visit_string(node.children.first),
      *node.children[1..].map { |n| visit(n) }
    )
  end

  def visit_dict_recursive_ref(_node)
    VimlValue::Types::DictRecursiveRef.new
  end

  def visit_list_recursive_ref(_node)
    VimlValue::Types::ListRecursiveRef.new
  end

  def visit_literal(node)
    node.children.first
  end
  alias visit_boolean visit_literal
  alias visit_null    visit_literal
  alias visit_string  visit_literal
  alias visit_numeric visit_literal
end
