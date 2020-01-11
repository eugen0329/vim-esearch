# frozen_string_literal: true

module API::Editor::Serialization::Helpers
  def id(string_representation)
    API::Editor::Serialization::Identifier.new(string_representation)
  end
  alias var id

  def func(name, *arguments)
    API::Editor::Serialization::FunctionCall.new(name, *arguments)
  end
end
