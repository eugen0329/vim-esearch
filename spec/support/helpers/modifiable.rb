# frozen_string_literal: true

module Helpers::Modifiable
  extend RSpec::Matchers::DSL

  Context = Struct.new(:name, :content) do
    def line_numbers
      @line_numbers ||= 1.upto(content.length).to_a
    end

    def entries
      line_numbers.map do |line_number|
        esearch.output.find_entry(name, line_number)
      rescue API::ESearch::Window::MissingEntry
        nil
      end
    end
  end

  def editor_lines_except(line)
    editor.lines(..line - 1).to_a +
      editor.lines(line + 1..).to_a
  end

  shared_context 'setup modifiable testing' do
    let(:contexts) do
      [Context.new('context1.txt', 1.upto(5).map { |i| "aa#{i}" }),
       Context.new('context2.txt', 1.upto(5).map { |i| "bb#{i}" }),
       Context.new('context3.txt', 1.upto(5).map { |i| "cc#{i}" })]
    end
    let(:sample_context) { contexts.sample }
    let(:sample_line_number) { sample_context.line_numbers.sample }
    let(:entry) { esearch.output.find_entry(sample_context.name, sample_line_number) }
    let(:line_number_text) { entry.line_number_text }
    let(:files) { contexts.map { |c| file(c.content, c.name) } }
    let!(:test_directory) { directory(files).persist! }

    before do
      esearch.configure!(adapter: 'ag', out: 'win', backend: 'system', regex: 1, use: [])
      editor.command! <<~SETUP
        let g:esearch#adapter#ag#bin = '#{Configuration.root}/spec/support/scripts/sort_search_results.sh ag'
        let g:esearch_win_disable_context_highlights_on_files_count = 0
        set backspace=indent,eol,start
        cd #{test_directory}
        call esearch#init({'exp': {'pcre': '^'}})
        call esearch#out#win#edit()
        call feedkeys("\\<C-\\>\\<C-n>")
      SETUP
    end

    after do
      editor.command <<~TEARDOWN
        let g:esearch_win_disable_context_highlights_on_files_count = 100
      TEARDOWN

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
      editor.cleanup!
    end
  end

  matcher :have_valid_entries do |entries|
    match do |output|
      @actual = output.reloaded_entries!(entries)
      @actual.all?(&:present?)
    end

    failure_message do
      "expected to have valid entries, got #{@actual.inspect}"
    end
  end

  matcher :have_missing_entries do |entries|
    attr_reader :expected

    match do |output|
      @actual = output.reloaded_entries!(entries)
      @actual.all?(&:blank?)
    end

    failure_message do
      "expected to have missing entries, got #{@actual.inspect}"
    end
  end
end