# frozen_string_literal: true

module Helpers::Commandline
  extend RSpec::Matchers::DSL
  include API::Mixins::BecomeTruthyWithinTimeout
  include VimlValue::SerializationHelpers

  def open_menu
    '\\<C-o>'
  end

  def open_input
    [:leader, 'ff']
  end

  def output_spy_calls
    esearch.output.calls_history
  end

  def menu_items
    esearch.output.echo_calls_history.last(3)
  end

  shared_context 'push' do |value:, to:|
    before { editor.command("call add(#{to}, \"#{value.gsub('"', '\"')}\")") }
    after { editor.pop(to) }
  end

  shared_context 'fix vim internal quirks with mapping timeout' do
    # in vim8 when pressing keys like <Left> or <Right> a trailing char appears
    # for a short period and cause extra character to be searched
    before { editor.command('set timeoutlen=0') }
    after { editor.command('set timeoutlen=1000') }
  end

  shared_context 'defined commandline hotkey' do |lhs, rhs|
    before { editor.command("cnoremap  #{lhs} #{rhs}") }
    after  { editor.command("cunmap #{lhs}") }
  end

  define_negated_matcher :not_to_change, :change
  define_negated_matcher :not_to_start_search, :start_search

  matcher :finish_search_for do |string|
    attr_reader :expected, :actual

    diffable
    supports_block_expectations

    match do |block|
      block.call

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

  matcher :set_global_options do |options, timeout: 1|
    attr_reader :expected, :actual
    supports_block_expectations

    match do |block|
      @was = esearch.configuration.global
      block.call

      editor.with_ignore_cache do
        @has_changed = became_truthy_within?(timeout) do
          @actual = esearch.configuration.global
          @was != @actual
        end
      end

      return false unless @has_changed

      @expected = include(*options)
      values_match?(@expected, @actual)
    end
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

  # NOTE: #start_search internally use timeout (like other gems like capybara
  # do), so using it with #not_to will lead to extra delays avoiding of which
  # can cause false positives

  matcher :start_search do |_previous_search_string, timeout: 1|
    supports_block_expectations

    match do |block|
      @was = output_spy_calls.last
      block.call

      editor.with_ignore_cache do
        became_truthy_within?(timeout) do
          @actual = output_spy_calls.last
          @was != output_spy_calls.last
        end
      end
    end

    failure_message_when_negated do
      "expected not to start search, but was changed from \n#{@was.pretty_inspect} to \n#{@actual.pretty_inspect}"
    end
  end
end
