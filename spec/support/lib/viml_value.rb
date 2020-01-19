# frozen_string_literal: true

module VimlValue
  class ParseError < RuntimeError; end

  def self.load(viml, lexer: Lexer, parser: Parser, visitor: Visitors::ToRuby)
    tree = parser
           .new(lexer.new, viml)
           .parse

    visitor.new.accept(tree)
  end
end
