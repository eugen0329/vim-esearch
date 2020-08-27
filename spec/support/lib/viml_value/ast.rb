# frozen_string_literal: true

# Defined to be compliant with ast gem, but without introducing it as a
# dependency as we don't use most of it's features
class VimlValue::AST
  Node = Struct.new(:type, :children) do
    def inspect
      "(#{type} #{children.map(&:inspect).join(' ')})"
    end
  end

  module Sexp
    def s(type, *children)
      Node.new(type, children)
    end
  end
end
