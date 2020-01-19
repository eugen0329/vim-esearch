# frozen_string_literal: true

module Helpers::Parsing
  extend ActiveSupport::Concern
  extend RSpec::Matchers::DSL

  included do
    def function(name)
      VimlValue::Visitors::ToRuby::Funcref.new(name)
    end

    def self.function(name)
      VimlValue::Visitors::ToRuby::Funcref.new(name)
    end
  end

  def dict_recursive_ref
    VimlValue::Visitors::ToRuby::DictRecursiveRef
  end

  def list_recursive_ref
    VimlValue::Visitors::ToRuby::ListRecursiveRef
  end

  matcher :raise_on_parsing do |exception|
    supports_block_expectations
    match do |actual|
      @parsed = VimlValue.load(actual)
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
       "while parsing #{actual.inspect},",
       "got #{@parsed.inspect}"].join(' ')
    end
  end

  matcher :be_parsed_as do |expected|
    match do |actual|
      @parsed = VimlValue.load(actual)
      eq(expected).matches?(@parsed)
    end

    description do |actual|
      "parse #{actual.inspect} as #{expected.inspect}"
    end

    failure_message do |actual|
      ["expected #{described_class}",
       "to parse #{actual.inspect}",
       "as #{expected.inspect},",
       "got #{@parsed.inspect}"].join(' ')
    end
  end
end
