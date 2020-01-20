# frozen_string_literal: true

module Helpers::VimlValue::Tokenize
  def val(ruby_value, location)
    VimlValue::Lexer::TokenData.new(ruby_value, *location)
  end
end
