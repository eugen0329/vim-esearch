# frozen_string_literal: true

module Helpers::VimlValue
  extend RSpec::Matchers::DSL

  def tok(token_type, ruby_value, location)
    token_value = VimlValue::Lexer::TokenData
                  .new(ruby_value, location.begin, location.end)

    [token_type, token_value]
  end

  # Documented in: https://rubydoc.info/github/rspec/rspec-expectations/RSpec/Matchers
  # Section: Custom matcher from scratch
  # Is used instead of DSL syntax to specify parameters more explicitly
  class BeProcessedAs
    include RSpec::Matchers::Composable

    def initialize(expected, &processing_proc)
      @processing_proc = processing_proc
      @expected = expected
    end

    def matches?(actual)
      @actual = actual
      @processed = @processing_proc.call(actual)
      values_match?(@expected, @processed)
    end

    def description
      "return#{human_readable(@expected)} after processing #{@actual.inspect}"
    end

    def failure_message
      ["to return#{human_readable(@expected)}",
       "after processing #{@actual.inspect},",
       "got #{@processed.inspect}",].join(' ')
    end

    # helps to expand messages for be_kind_of matchers etc.
    def human_readable(object)
      RSpec::Matchers::EnglishPhrasing.list(object)
    end
  end

  class FailProcessingWith
    include RSpec::Matchers::Composable

    def initialize(exception, &processing_proc)
      @processing_proc = processing_proc
      @exception = exception
    end

    def matches?(actual)
      @actual = actual
      @processed = @processing_proc.call(actual)
      false
    rescue Exception => e # rubocop:disable Lint/RescueException
      values_match?(@exception, e)
    end

    def description
      "#{human_readable_name} #{@exception} while processing #{@actual.inspect}"
    end

    def failure_message
      ["#{human_readable_name} #{@exception}",
       "but #{@processed.inspect} was returned",].join(' ')
    end

    def human_readable_name
      self.class.name.demodulize.underscore.tr('_', ' ')
    end
  end

  class BeParsedAs < BeProcessedAs; end

  class FailParsingWith < FailProcessingWith; end

  class BeTokenizedAs < BeProcessedAs; end

  class FailTokenizingWith < FailProcessingWith; end

  class BeLoadedAs < BeProcessedAs; end

  class FailLoadingWith < FailProcessingWith; end
end
