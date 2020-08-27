# frozen_string_literal: true

module VimlValue::SerializationHelpers
  def var(string_representation)
    VimlValue::Serializable::Identifier.new(string_representation)
  end

  def func(name, *arguments)
    VimlValue::Serializable::FunctionCall.new(name, *arguments)
  end

  def funcref(*args)
    VimlValue::Types::Funcref.new(*args)
  end

  def none
    VimlValue::Types::None.new
  end
end
