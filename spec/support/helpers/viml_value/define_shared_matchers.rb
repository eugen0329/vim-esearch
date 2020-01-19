# frozen_string_literal: true

module Helpers::VimlValue::DefineSharedMatchers
  include RSpec::Matchers::DSL

  # Pretty ugly way to reduce duplication (other approaches involve even
  # more problems mostly tied with implicit dependencies)

  def define_action_matcher!(matcher_name, verb:, &action)
    matcher matcher_name do |expected|
      match do |_actual|
        @processed = instance_exec(&action)
        eq(expected).matches?(@processed)
      end

      description do |actual|
        "#{verb} #{actual.inspect} as #{expected.inspect}"
      end

      failure_message do |actual|
        ["expected #{VimlValue::Lexer}",
         "to #{verb} #{actual.inspect}",
         "as #{expected.inspect},",
         "got #{@processed.inspect}"].join(' ')
      end
    end
  end

  def define_raise_on_action_matcher!(matcher_name, verb:, &action)
    matcher matcher_name do |exception|
      supports_block_expectations

      match do |_actual|
        @processed = instance_exec(&action)
        false
      rescue exception
        true
      end

      description do |actual|
        "raise #{exception} while #{verb} #{actual.inspect}"
      end

      failure_message do |actual|
        ["expected #{described_class}",
         "to raise #{exception}",
         "while #{verb} #{actual.inspect},",
         "got #{@processed.inspect}"].join(' ')
      end
    end
  end
end
