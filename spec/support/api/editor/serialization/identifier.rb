# frozen_string_literal: true

class API::Editor::Serialization::Identifier < API::Editor::Serialization::VimlExpr
  attr_reader :string_representation
  alias to_s string_representation

  def initialize(string_representation)
    @string_representation = string_representation
  end

  def inspect
    "<Id of=#{string_representation}>"
  end
end
