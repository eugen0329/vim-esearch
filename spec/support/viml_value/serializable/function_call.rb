# frozen_string_literal: true

class VimlValue::Serializable::FunctionCall < VimlValue::Serializable::Expression
  attr_reader :name, :arguments

  def initialize(name, *arguments)
    @name = name
    @arguments = arguments
  end

  def to_s
    "(#{name} #{arguments.map(&:inspect).join(' ')})"
  end

  def inspect
    "<FunctionCall #{self}>"
  end
end
