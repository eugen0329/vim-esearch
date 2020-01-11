class API::Editor::Serialization::FunctionCall < API::Editor::Serialization::VimlValue
  attr_reader :name, :arguments

  def initialize(name, *arguments)
    @name = name
    @arguments = arguments
  end

  def to_s
    "(#{name} #{arguments.join(' ')})"
  end
end
