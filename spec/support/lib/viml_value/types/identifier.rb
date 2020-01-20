# frozen_string_literal: true

class VimlValue::Types::Identifier < VimlValue::Types::Expression
  attr_reader :string_representation
  alias to_s string_representation

  def initialize(string_representation)
    @string_representation = string_representation
  end

  def inspect
    "<Id of=#{string_representation}>"
  end
end
