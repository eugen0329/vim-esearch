# frozen_string_literal: true

module Helpers::CommandlineMenu
  extend RSpec::Matchers::DSL
  include API::Mixins::BecomeTruthyWithinTimeout

  def output_spy_calls
    esearch.output.calls_history
  end

  def menu_items
    esearch.output.echo_calls_history.last(3)
  end

  define_negated_matcher :not_to_change, :change

  matcher :have_search_finished_for do |string|
    attr_reader :expected, :actual

    diffable
    supports_block_expectations

    match do |actual|
      actual.call if actual.is_a? Proc

      @actual =
        [esearch.output.calls_history.last&.dig('exp', 'pcre'),
         esearch.output.calls_history.last&.dig('exp', 'literal')]
      @expected = [string, string]

      values_match?(@expected, @actual)
    end
  end

  matcher :start_search_with_options do |options|
    attr_reader :expected, :actual

    supports_block_expectations
    diffable

    match do |actual|
      actual.call

      @expected = include(options)
      @actual = output_spy_calls.last
      values_match?(@expected, @actual)
    end
  end

  matcher :set_global_options do |options|
    attr_reader :expected, :actual
    supports_block_expectations

    match do |block|
      @matcher = change { esearch.configuration.global }
                 .to include(*options)
      @matcher.matches?(block)
    end

    description { @matcher&.description }
    failure_message { @matcher&.failure_message }
  end

  matcher :start_search_with_previous_input do |previous_search_string|
    supports_block_expectations

    match do |block|
      @matcher = not_to_change do
        [output_spy_calls.last.dig('exp', 'pcre'),
         output_spy_calls.last.dig('exp', 'literal')]
      end.from([previous_search_string, previous_search_string])
      @matcher.matches?(block)
    end

    description { @matcher&.description }
    failure_message { @matcher&.failure_message }
  end

  matcher :start_search do |_previous_search_string, timeout: 1|
    supports_block_expectations

    match do |block|
      @was = output_spy_calls.last
      block.call

      became_truthy_within?(timeout) do
        @was != output_spy_calls.last
      end
    end
  end
end
