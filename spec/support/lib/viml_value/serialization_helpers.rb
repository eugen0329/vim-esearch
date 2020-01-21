# frozen_string_literal: true

module VimlValue::SerializationHelpers
  def var(string_representation)
    VimlValue::Serializable::Identifier.new(string_representation)
  end

  def func(name, *arguments)
    VimlValue::Serializable::FunctionCall.new(name, *arguments)
  end

  def funcref(name)
    VimlValue::Types::Funcref.new(name)
  end
end
