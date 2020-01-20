module VimlValue::SerializationHelpers
  def var(string_representation)
    VimlValue::Types::Identifier.new(string_representation)
  end

  def func(name, *arguments)
    VimlValue::Types::FunctionCall.new(name, *arguments)
  end

  def funcref(name)
    VimlValue::Types::Funcref.new(name)
  end

  def dict_recursive_ref
    VimlValue::Types::DictRecursiveRef
  end

  def list_recursive_ref
    VimlValue::Types::ListRecursiveRef
  end
end
