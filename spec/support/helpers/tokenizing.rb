# frozen_string_literal: true

module Helpers::Tokenizing
  extend ActiveSupport::Concern
  extend RSpec::Matchers::DSL

  def val(ruby_value, location)
    VimlValue::Lexer::TokenData.new(ruby_value, *location)
  end

  matcher :be_tokenized_as do |*expected|
    match do |actual|
      @tokenized = VimlValue::Lexer.new(actual).each_token.to_a
      eq(expected).matches?(@tokenized)
    end

    description do |actual|
      "tokenize #{actual.inspect} as #{expected.inspect}"
    end

    failure_message do |actual|
      ["expected #{VimlValue::Lexer}",
       "to tokenize #{actual.inspect}",
       "as #{expected.inspect},",
       "got #{@tokenized.inspect}"].join(' ')
    end
  end

  matcher :raise_on_tokenizing do |exception|
    supports_block_expectations
    match do |actual|
      @tokenized = VimlValue::Lexer.new(actual).each_token.to_a
      false
    rescue exception
      true
    end

    description do |actual|
      "raise #{VimlValue::ParseError} while parsing #{actual.inspect}"
    end

    failure_message do |actual|
      ["expected #{described_class}",
       "to raise #{exception}",
       "while tokenizing #{actual.inspect},",
       "got #{@tokenized.inspect}"].join(' ')
    end
  end
end
