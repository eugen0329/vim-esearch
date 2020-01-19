# frozen_string_literal: true

module Helpers::VimlValue::Parse
  extend ActiveSupport::Concern
  extend Helpers::VimlValue::DefineSharedMatchers

  # Pretty ugly way to reduce duplication (other approaches involve even
  # more problems mostly tied with implicit dependencies)
  define_action_matcher!(:be_parsed_as, verb: 'parse') do
    VimlValue::Parser.new(VimlValue::Lexer.new).parse(actual)
  end
  define_raise_on_action_matcher!(:raise_on_parse, verb: 'parsing') do
    VimlValue::Parser.new(VimlValue::Lexer.new).parse(actual)
  end
end
