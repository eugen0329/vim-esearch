# frozen_string_literal: true

module VimlValue
  class ParseError < RuntimeError; end

  def self.load(string, allow_toplevel_literals: false)
    tree = VimlValue::Parser
           .new(VimlValue::Lexer.new(string), allow_toplevel_literals: allow_toplevel_literals)
           .parse

    return tree if tree.nil?

    VimlValue::Visitors::ToRuby.new.accept(tree)
  end

  def self.dump(object, visitor: VimlValue::Visitors::ToVim)
    visitor.new.accept(object)
  end
end
