# frozen_string_literal: true

class VimlValue::Serializable::Identifier < VimlValue::Serializable::Expression
  attr_reader :string_representation
  alias to_s string_representation

  def initialize(string_representation)
    @string_representation = string_representation
  end

  def inspect
    "<Id of=#{string_representation}>"
  end
end
