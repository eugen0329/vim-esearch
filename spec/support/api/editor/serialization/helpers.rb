# frozen_string_literal: true

module API::Editor::Serialization::Helpers
  def var(string_representation)
    API::Editor::Serialization::Identifier.new(string_representation)
  end

  def func(name, *arguments)
    API::Editor::Serialization::FunctionCall.new(name, *arguments)
  end
end
