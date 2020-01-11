# frozen_string_literal: true

class API::Editor::Serialization::Identifier < API::Editor::Serialization::VimlValue
  attr_reader :string_representation
  alias_method :to_s, :string_representation

  def initialize(string_representation)
  @string_representation = string_representation
  end

  def inspect
    "<Id of=#{string_representation}>"
  end
end
