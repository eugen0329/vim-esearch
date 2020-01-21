# frozen_string_literal: true

module Helpers::VimlValue
  extend RSpec::Matchers::DSL

  def tok(token_type, ruby_value, location)
    token_value = VimlValue::Lexer::TokenData
      .new(ruby_value, location.begin, location.end)

    [token_type, token_value]
  end

  matcher :become do |expected|
    match do |actual|
      @processed = @method.call(actual)
      match(expected).matches?(@processed)
    end

    chain :after do |method|
      @method = method
    end

    description do
      expected_list = RSpec::Matchers::EnglishPhrasing.list(expected)
      "return#{expected_list} after processing #{actual.inspect}"
    end

    failure_message do |actual|
      expected_list = RSpec::Matchers::EnglishPhrasing.list(expected)
      ["to return#{expected_list}",
       "after processing #{actual.inspect},",
       "got #{@processed.inspect}"].join(' ')
    end
  end

  matcher :fail_with do |exception|
    supports_block_expectations

    match do |actual|
      @processed = @method.call(actual)
      false
    rescue exception
      true
    end

    chain :while do |method|
      @method = method
    end

    description do |actual|
      "#{name.to_s.tr('_', ' ')} #{exception} while processing #{actual.inspect}"
    end

    failure_message do
      "#{name.to_s.tr('_', ' ')} #{exception} but #{@processed.inspect} has been returned"
    end
  end
end
