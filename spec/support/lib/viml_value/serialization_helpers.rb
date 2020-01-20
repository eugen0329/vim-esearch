module VimlValue::SerializationHelpers
  def var(string_representation)
    VimlValue::Types::Identifier.new(string_representation)
  end

  def func(name, *arguments)
    VimlValue::Types::FunctionCall.new(name, *arguments)
  end
end
