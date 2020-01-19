# frozen_string_literal: true

module VimlValue
  def self.load(viml, lexer: Lexer, parser: Parser, visitor: ToRuby)
    tree = parser
           .new(lexer.new, viml)
           .parse

    visitor.new.accept(tree)
  end
end
