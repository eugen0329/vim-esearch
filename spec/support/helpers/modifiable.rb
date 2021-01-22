# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module Helpers::Modifiable
  extend ActiveSupport::Concern
  include Helpers::FileSystem
  include VimlValue::SerializationHelpers
  extend RSpec::Matchers::DSL

  Context = Struct.new(:name, :content) do
    include VimlValue::SerializationHelpers
    attr_accessor :file

    def lines
      entries.map(&:result_text)
    end

    def buffer_lines
      editor.echo(func('getbufline', file.path.to_s, 1, 10_000))
    end

    def line_numbers
      @line_numbers ||= 1.upto(content.length).to_a
    end

    def locate!
      entries.first.locate!
    end

    def absolute_path
      file.path.to_s
    end

    def entries
      line_numbers.map do |line_number|
        esearch.output.find_entry(name, line_number)
      rescue API::ESearch::Window::MissingEntryError
        nil
      end
    end
  end

  def editor_lines_except(line)
    editor.lines(..line - 1).to_a +
      editor.lines(line + 1..).to_a
  end

  define_negated_matcher :not_to_change, :change
  define_negated_matcher :not_change, :change

  shared_context 'setup modifiable testing' do |default_mappings: 1|
    let(:contexts) do
      [Context.new('context1.txt', 1.upto(5).map { |i| "aa#{i}" }),
       Context.new('context2.txt', 1.upto(5).map { |i| "bb#{i}" }),
       Context.new('context3.txt', 1.upto(5).map { |i| "cc#{i}" }),]
    end
    let(:sample_context) { contexts.sample }
    let(:sample_line_number) { sample_context.line_numbers.sample }
    let(:entry) { output.find_entry(sample_context.name, sample_line_number) }
    let(:line_number_text) { entry.line_number_text }
    let(:files) do
      contexts.map { |c| c.file = file(c.content, c.name) }
    end
    let!(:test_directory) { directory(files).persist! }
    let(:entries) { contexts.map(&:entries).flatten }
    let(:output) { esearch.output }
    let(:writer) { 'buffer' }

    before do
      esearch.configure!(
        adapter:          'ag',
        out:              'win',
        backend:          'system',
        regex:            1,
        prefill:          [],
        default_mappings: defined?(default_mappings) ? default_mappings : 0,
        root_markers:     []
      )
      # TODO: reduce duplication with configuration#adapter=()
      path = "#{Configuration.root}/spec/support/scripts/sort_search_results.sh ag"
      editor.command! <<~SETUP
        call esearch#config#eager()
        call extend(g:esearch.adapters, {#{esearch.configuration.adapter.dump}: {}}, 'keep')
        call extend(g:esearch.adapters[#{esearch.configuration.adapter.dump}], {'bin': '#{path}'})

        let g:esearch.win_contexts_syntax = 0
        set backspace=indent,eol,start
        cd #{test_directory}
        call esearch#init({'pattern': '^'})
        call esearch#out#win#modifiable#init()
        call feedkeys("\\<c-\\>\\<c-n>lh")
      SETUP
    end

    after do
      messages = Debug.messages.join
      errors = editor.echo(var('v:errors'))
      lines = editor.lines

      expect(messages).not_to include('Error')
      expect(errors).to be_empty

      # TODO: extract this logic to the parser
      if esearch.output.inside_search_window?
        expect(lines.first).to match(API::ESearch::Window::HeaderParser::HEADER_REGEXP)
        expect(lines.to_a[1]).to be_blank
        expect(lines.to_a.last).not_to be_blank if lines.to_a.count > 2
      end
      vim.normal # fix e315 raised while trying to leave insert mode within teardown
      editor.cleanup!
    end
  end

  # Isn't good from SRP perspective, but good enough in terms of natural way of
  # thinking abount verification of present and missing elements. So instead of
  # checking:
  # all_entries == (entries - other_entries) &&
  #   (entries - other_entries).all?(:present?) &&
  #   other_entries.all?(&:emtpy?)
  # we have a single matcher have_entries(entries).except(other_entries)
  # Could be splitted into 3 matchers if it'd be possible to combine other
  # matchers within a custom one without hacks.
  matcher :have_entries do |entries|
    diffable

    match do
      @except ||= []
      @except = esearch.output.reloaded_entries!(@except)
      @expected = esearch.output.reloaded_entries!(entries) - @except
      @actual = esearch.output.entries.to_a

      @expected_present = @expected.all?(&:present?)
      return false unless @expected_present

      @actual_matches_expected = @actual == @expected
      return false unless @actual_matches_expected

      @except_missing = @except.all?(&:blank?)
      return false unless @except_missing

      true
    end

    chain :except do |except|
      @except = esearch.output.reloaded_entries!(except)
    end

    failure_message do
      if !@expected_present
        "expected #{@expected.inspect} to all be present"
      elsif !@actual_matches_expected
        "expected to have entries #{@expected.inspect}, got #{@actual.inspect}"
      else
        "expected #{@except.inspect} to be missing"
      end
    end
  end

  matcher :have_valid_entries do |entries|
    match do
      @actual = esearch.output.reloaded_entries!(entries)
      @actual.all?(&:present?)
    end

    failure_message do
      "expected to have valid entries, got #{@actual.inspect}"
    end
  end

  matcher :have_missing_entries do |entries|
    attr_reader :expected

    match do
      @actual = esearch.output.reloaded_entries!(entries)
      @actual.all?(&:blank?)
    end

    failure_message do
      "expected to have missing entries, got #{@actual.inspect}"
    end
  end
end
# rubocop:enable Metrics/ModuleLength
