# frozen_string_literal: true

module Helpers::VimlValue
  extend RSpec::Matchers::DSL

  def tok(token_type, ruby_value, location)
    token_value = VimlValue::Lexer::TokenData
                  .new(ruby_value, location.begin, location.end)

    [token_type, token_value]
  end

  matcher :be_processed_by_calling_subject_as do |expected|
    match do |actual|
      @actual_return_value = subject.call(actual)
      match(expected).matches?(@actual_return_value)
    end

    description do |actual|
      "return#{human_readable(expected)} after processing #{actual.inspect}"
    end

    failure_message do |actual|
      ["to return#{human_readable(expected)}",
       "after processing #{actual.inspect},",
       "got #{@actual_return_value.inspect}"].join(' ')
    end

    def human_readable(object)
      RSpec::Matchers::EnglishPhrasing.list(object)
    end
  end

  matcher :fail_on_calling_subject_with do |exception|
    match do |actual|
      block = -> { @actual_return_value = subject.call(actual) }
      raise_error(exception).matches? block
    end

    description do |actual|
      "#{human_readable_name} #{exception} while processing #{actual.inspect}"
    end

    failure_message do
      ["#{human_readable_name} #{exception}",
       "but #{@actual_return_value.inspect} was returned"].join(' ')
    end

    def human_readable_name
      name.to_s.tr('_', ' ')
    end
  end
end
