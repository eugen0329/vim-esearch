# frozen_string_literal: true

module Helpers::VimlValue::Tokenize
  extend ActiveSupport::Concern
  extend Helpers::VimlValue::DefineSharedMatchers

  # Pretty ugly way to reduce duplication (other approaches involve even
  # more problems mostly tied with implicit dependencies)
  define_action_matcher!(:be_tokenized_as, verb: 'tokenize') do
    VimlValue::Lexer.new(actual).each_token.to_a
  end
  define_raise_on_action_matcher!(:raise_on_tokenizing, verb: 'tokenizing') do
    VimlValue::Lexer.new(actual).each_token.to_a
  end

  def val(ruby_value, location)
    VimlValue::Lexer::TokenData.new(ruby_value, *location)
  end
end
