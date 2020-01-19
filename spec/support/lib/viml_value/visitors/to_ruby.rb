# frozen_string_literal: true

class VimlValue::Visitors::ToRuby
  Funcref = Struct.new(:name)
  DictRecursiveReference = Class.new
  ListRecursiveReference = Class.new

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

  def visit_funcref(node)
    Funcref.new(visit_value(node))
  end

  def visit_dict_recursive_ref(_node)
    DictRecursiveReference
  end

  def visit_list_recursive_ref(_node)
    ListRecursiveReference
  end

  def visit_value(node)
    node.children.first
  end
  alias visit_boolean visit_value
  alias visit_null    visit_value
  alias visit_string  visit_value
  alias visit_numeric visit_value
end
