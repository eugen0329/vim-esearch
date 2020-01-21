# frozen_string_literal: true

class VimlValue::Types::FunctionCall < VimlValue::Types::Expression
  attr_reader :name, :arguments

  def initialize(name, *arguments)
    @name = name
    @arguments = arguments
  end

  def to_s
    "(#{name} #{arguments.join(' ')})"
  end

  def inspect
    "<FunctionCall #{self}>"
  end
end
