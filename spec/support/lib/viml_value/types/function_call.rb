# frozen_string_literal: true

class VimlValue::Types::FunctionCall < VimlValue::Types::Expression
  attr_reader :name, :arguments

  def initialize(name, *arguments)
    @name = name
    @arguments = arguments
  end

  def to_s
    # Is only used for caching (and sometimes for debug). Display is done in
    # the sexp-like form to avoid coupling with serialization related
    # classes
    "(#{name} #{arguments.join(' ')})"
  end

  def inspect
    "<FunctionCall #{self}>"
  end
end
