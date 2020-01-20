# frozen_string_literal: true

module Helpers::VimlValue
  extend RSpec::Matchers::DSL

  matcher :become do |expected|
    match do |actual|
      @processed = @method.call(actual)
      eq(expected).matches?(@processed)
    end

    chain :after do |method|
      @method = method
    end

    description do
      "return #{expected.inspect} after processing #{actual.inspect}"
    end

    failure_message do |actual|
      ["to become #{expected.inspect}",
       "from #{actual.inspect},",
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
      "#{name.to_s.tr('_', ' ')} #{exception} but #{@processed.inspect} has returned"
    end
  end
end

