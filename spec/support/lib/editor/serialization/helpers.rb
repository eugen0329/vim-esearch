# frozen_string_literal: true

module Editor::Serialization::Helpers
  def var(string_representation)
    Editor::Serialization::Identifier.new(string_representation)
  end

  def func(name, *arguments)
    Editor::Serialization::FunctionCall.new(name, *arguments)
  end
end
