# frozen_string_literal: true

module Helpers::VimlValue::Convert
  extend RSpec::Matchers::DSL

  matcher :be_converted_by_calling_subject_as do |expected|
    match do |actual|
      @converted = subject.call(actual)
      eq(expected).matches?(@converted)
    end

    description do
      "#{name.to_s.tr('_', ' ')} #{expected.inspect} from #{actual.inspect}"
    end

    failure_message do |actual|
      ["to #{name.to_s.tr('_', ' ')} #{expected.inspect}",
       "from #{actual.inspect},",
       "got #{@converted.inspect}"].join(' ')
    end
  end

  matcher :raise_on_converting_by_calling_subject do |exception|
    supports_block_expectations

    match do |actual|
      subject.call(actual)
      false
    rescue exception
      true
    end

    description do
      "#{name.to_s.tr('_', ' ')} of #{actual.inspect} (#{exception})"
    end

    failure_message do
      "expected to #{name.to_s.tr('_', ' ')} of #{actual.inspect} (#{exception})"
    end
  end
end
