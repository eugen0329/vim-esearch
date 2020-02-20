# frozen_string_literal: true

module VimlValue
  class ParseError < RuntimeError; end

  def self.load(string, allow_toplevel_literals: false)
    tree = Parser
           .new(Lexer.new(string), allow_toplevel_literals: allow_toplevel_literals)
           .parse

    return tree if tree.nil?

    Visitors::ToRuby.new.accept(tree)
  end

  def self.dump(object, visitor: Visitors::ToVim)
    visitor.new.accept(object)
  end
end
