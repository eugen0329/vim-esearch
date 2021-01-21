# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module Helpers::Commandline
  extend RSpec::Matchers::DSL
  include API::Mixins::BecomeTruthyWithinTimeout
  include VimlValue::SerializationHelpers

  def close_menu_key
    :escape
  end

  def open_menu_keys
    ['\\<c-o>']
  end

  def open_input_keys
    [:leader, 'ff']
  end

  def open_paths_input_keys
    ['p']
  end

  def open_filetypes_input_keys
    ['f']
  end

  def inputted_keys(keys)
    # TODO
    keys.gsub('\\\\', '\\')
  end

  def stubbed_output_calls
    esearch.output.calls_history
  end

  def locate_cursor_with_arrows(location_string)
    raise ArgumentError unless location_string.include?('')

    [:end].concat([:left] * (location_string.length - location_string.index('|') - 1))
  end

  shared_context 'run preparatory search to enable prefilling' do |search_string|
    before do
      expect { editor.send_keys(*open_input_keys, search_string, :enter) }
        .to start_stubbed_search & finish_stubbed_search_for(search_string)
    end
  end

  shared_context 'add' do |value:, to:|
    before { editor.command("call add(#{to}, \"#{value.gsub('"', '\"')}\")") }
    after { editor.command("unlet #{to}[-1]") }
  end

  shared_context 'fix vim internal quirks with mapping timeout' do
    # in vim8 when pressing keys like <left> or <right> a trailing char appears
    # for a short period and cause extra character to be searched
    before { editor.command('set timeoutlen=0') }
    after { editor.command('set timeoutlen=1000') }
  end

  shared_context 'defined commandline hotkey' do |lhs, rhs|
    before { editor.command("cnoremap  #{lhs} #{rhs}") }
    after  { editor.command("cunmap #{lhs}") }
  end

  shared_context 'defined normal mode hotkey' do |lhs, rhs|
    before { editor.command("nnoremap  #{lhs} #{rhs}") }
    after  { editor.command("nunmap #{lhs}") }
  end

  shared_context 'defined commandline abbreviation' do |lhs, rhs|
    before { editor.command("cabbrev  #{lhs} #{rhs}") }
    after  { editor.command("cunabbrev #{lhs}") }
  end

  shared_context 'defined normal mode abbreviation' do |lhs, rhs|
    before { editor.command("abbrev  #{lhs} #{rhs}") }
    after  { editor.command("unabbrev #{lhs}") }
  end

  define_negated_matcher :not_to_change, :change

  matcher :be_in_commandline do |_location_string|
    match { values_match?(editor.mode, :commandline) }
  end
  define_negated_matcher :not_to_be_in_commandline, :be_in_commandline

  # TODO: consider to run all matchers against facade
  matcher :have_commandline_content do |expected|
    attr_reader :expected, :actual

    diffable

    match do |editor|
      @expected = expected
      @actual = editor.commandline_content
      values_match?(@expected, @actual)
    end
  end

  matcher :have_commandline_cursor_location do |location_string|
    attr_reader :expected, :actual

    match do |editor|
      @expected = {
        commandline_cursor_location: editor.commandline_cursor_location,
        commandline_content:         editor.commandline_content,
      }
      @actual = {
        commandline_cursor_location: location_string.index('|') + 1,
        commandline_content:         location_string.tr('|', ''),
      }
      values_match?(@expected, @actual)
    end
  end

  matcher :finish_stubbed_search_for do |string|
    attr_reader :expected, :actual

    diffable
    supports_block_expectations

    match do |block|
      block.call

      @actual = esearch.output.calls_history.last&.dig('pattern', 'str')
      @expected = string
      values_match?(@expected, @actual)
    end
  end

  matcher :start_stubbed_search_with_options do |options|
    attr_reader :expected, :actual

    supports_block_expectations
    diffable

    match do |actual|
      actual.call

      @expected = include(options)
      @actual = stubbed_output_calls.last
      values_match?(@expected, @actual)
    end
  end

  matcher :set_global_options do |options, timeout: 1|
    attr_reader :actual

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

  # NOTE: #start_stubbed_search internally use timeout (like other gems like capybara
  # do), so using it with #not_to will lead to extra delays avoiding of which
  # can cause false positives

  matcher :start_stubbed_search do |_previous_search_string, timeout: 1|
    supports_block_expectations

    match do |block|
      @was = stubbed_output_calls.last
      block.call

      editor.with_ignore_cache do
        became_truthy_within?(timeout) do
          @actual = stubbed_output_calls.last
          @was != stubbed_output_calls.last
        end
      end
    end

    failure_message_when_negated do
      "expected not to start search, but was changed from \n#{@was.pretty_inspect} to \n#{@actual.pretty_inspect}"
    end
  end
end
# rubocop:enable Metrics/ModuleLength
