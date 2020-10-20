# frozen_string_literal: true

require 'spec_helper'

# TODO: testing
# - test directories with spaces in names
# - abosolute path
# - outside cwd
# - single file should be tested separately
describe 'esearch#adapter', :adapters do
  include Helpers::FileSystem
  include Helpers::Strings
  include Helpers::Output
  include Helpers::ReportEditorStateOnError
  include Helpers::Commandline

  include_context 'report editor state on error'

  before { esearch.configure(prefill: [], root_markers: [], adapters: {grep: {options: '--exclude-dir=.git'}}) }

  shared_examples 'adapter paths testing examples' do |adapter|
    describe "##{adapter}", adapter.to_sym, adapter: adapter.to_sym do
      before do
        esearch.configure(
          adapter: adapter,
          out:     'win',
          backend: 'system',
          regex:   (adapter =~ /grep|git/ ? 'pcre' : 1)
        )
        esearch.configuration.submit!
      end
      after { esearch.cleanup! }
      let!(:test_directory) { directory(files).persist! }

      shared_examples 'search specifying custom paths' do |paths_string:, expected_names:, files:|
        let(:files) { files }
        before { editor.cd! test_directory }

        it do
          editor.send_keys(*open_input_keys, '.*', *open_menu_keys)
          editor.send_keys(*open_paths_input_keys, paths_string, :enter, close_menu_key, :enter)

          KnownIssues.mark_example_pending_if_known_issue(self) do
            expect(esearch).to found_results_in_files(expected_names)
          end
        end
      end

      describe 'ugly names' do
        let!(:test_directory) { directory(files).persist! }

        it_behaves_like 'search specifying custom paths',
          paths_string:   %q[
             with\\\\ ws/file.e
             with\\\\\\\\backslash/file.e
             with\\\\'squote/file.e
             with\\\\"dquote/file.e
          ].gsub("\n", ' '),
          expected_names: [
            'with\\ ws/file.e',
            'with\\\\backslash/file.e',
            "with\\'squote/file.e",
            'with\\"dquote/file.e',
          ],
          files:          [
            file('any content', 'with ws/file.e'),
            file('any content', 'with\\backslash/file.e'),
            file('any content', "with'squote/file.e"),
            file('any content', 'with"dquote/file.e'),
            file('any content', 'with\\ws/file.e'),
            file('any content', 'withws/file.e'),
            file('any content', 'with backslash/file.e'),
            file('any content', 'other/file.e'),
          ]

        context 'when searching using prefilled directories' do
          let(:files) do
            [file('any content', '*.txt'),
             file('any content', 'b c.json'),]
          end
          let!(:test_directory) { directory(files).persist! }
          let(:names) { files.map { |f| editor.escape_filename(f.relative_path) } }
          let(:paths_string) { '\\\\*.txt b\\\\ c.json' }

          before do
            editor.cd! test_directory
            editor.send_keys(*open_input_keys, '.*', *open_menu_keys)
            editor.send_keys(*open_paths_input_keys, paths_string, :enter, close_menu_key, :enter)
            expect(esearch).to found_results_in_files(names) # fail fast
            editor.close_current_window!
          end

          it do
            editor.send_keys(*open_input_keys, '.*', *open_menu_keys)
            editor.send_keys(*open_paths_input_keys)
            expect(editor).to have_commandline_content(inputted_keys(paths_string))
            editor.send_keys(:enter, close_menu_key, :enter)

            expect(esearch).to found_results_in_files(names)
          end
        end
      end

      describe 'context height' do
        let(:before_lines) { 0 }
        let(:after_lines) { 0 }
        let(:context_lines) { 0 }
        before do
          esearch.configure(
            adapter: adapter,
            out:     'win',
            backend: 'system',
            regex:   (adapter =~ /grep|git/ ? 'pcre' : 1),
            before:  before_lines,
            after:   after_lines,
            context: context_lines
          )
          esearch.configuration.submit!
        end
        let!(:test_directory) { directory(files).persist! }
        let(:search_string) { 'line3' }
        let(:path) { 'file.txt' }
        let(:line) { 3 }
        let(:files) do
          [file("line1\nline2\n#{search_string}\nline4\nline5", path)]
        end
        before { editor.cd! test_directory }
        after { esearch.cleanup! }

        before do
          esearch.search!(search_string)

          expect(esearch)
            .to  have_search_started
            .and have_search_finished
            .and have_not_reported_errors
            .and have_search_highlight(path, 3, 1..(search_string.length + 1))
        end

        context "when 'before' is set" do
          let(:before_lines) { 1 }

          it do
            expect(esearch)
              .to have_outputted_results(count: 2)
              .and have_search_highlight(path, 3, 1..(search_string.length + 1))
              .and have_outputted_result_from_file_in_line(path, line)
              .and have_outputted_result_from_file_in_line(path, line - 1)
          end
        end

        context "when 'after' is set" do
          let(:after_lines) { 2 }

          it do
            expect(esearch)
              .to have_outputted_results(count: 3)
              .and have_outputted_result_from_file_in_line(path, line)
              .and have_outputted_result_from_file_in_line(path, line + 1)
              .and have_outputted_result_from_file_in_line(path, line + 2)
          end
        end

        context "when 'before' and 'after' are set" do
          let(:after_lines) { 1 }
          let(:before_lines) { 2 }

          it do
            expect(esearch)
              .to have_outputted_results(count: 4)
              .and have_outputted_result_from_file_in_line(path, line)
              .and have_outputted_result_from_file_in_line(path, line + 1)
              .and have_outputted_result_from_file_in_line(path, line - 1)
              .and have_outputted_result_from_file_in_line(path, line - 2)
          end
        end

        context "when 'context' is set" do
          let(:context_lines) { 1 }

          it do
            expect(esearch)
              .to have_outputted_results(count: 3)
              .and have_outputted_result_from_file_in_line(path, line)
              .and have_outputted_result_from_file_in_line(path, line - 1)
              .and have_outputted_result_from_file_in_line(path, line + 1)
          end
        end
      end

      describe 'globbing' do
        context 'single *' do
          it_behaves_like 'search specifying custom paths',
            paths_string:   '*.txt',
            expected_names: ['a.txt', 'b.txt', '\\*.txt'],
            files:          [
              file('any content', 'a.txt'),
              file('any content', 'b.txt'),
              file('any content', '*.txt'),
              file('any content', 'c.json'),
            ]
        end

        context 'escaped *' do
          it_behaves_like 'search specifying custom paths',
            paths_string:   '\\\\*.txt',
            expected_names: ['\\*.txt'],
            files:          [
              file('any content', 'a.txt'),
              file('any content', 'b.txt'),
              file('any content', '*.txt'),
              file('any content', 'c.json'),
            ]
        end
      end
    end
  end

  shared_examples 'adapter filetypes testing examples' do |adapter|
    before do
      esearch.configure(
        adapter: adapter,
        out:     'win',
        backend: 'system',
        regex:   (adapter =~ /grep|git/ ? 'pcre' : 1)
      )
      esearch.configuration.submit!
      editor.cd! test_directory
    end
    after { esearch.cleanup! }
    let!(:test_directory) { directory(files).persist! }
    let(:files) { [file('a', 'file.vim'), file('a', 'file.c')] }

    it do
      editor.send_keys(*open_input_keys, '.*', *open_menu_keys)
      editor.send_keys(*open_filetypes_input_keys, 'vim', :enter, close_menu_key, :enter)

      KnownIssues.mark_example_pending_if_known_issue(self) do
        expect(esearch).to found_results_in_files(['file.vim'])
      end
    end
  end

  shared_examples '[path] testing examples' do
    include_examples 'adapter paths testing examples', 'ag'
    include_examples 'adapter paths testing examples', 'ack'
    include_examples 'adapter paths testing examples', 'git'
    include_examples 'adapter paths testing examples', 'grep'
    include_examples 'adapter paths testing examples', 'pt'
    include_examples 'adapter paths testing examples', 'rg'
  end

  shared_examples '[filetypes] testing examples' do
    include_examples 'adapter filetypes testing examples', 'ag'
    include_examples 'adapter filetypes testing examples', 'ack'
    include_examples 'adapter filetypes testing examples', 'rg'
  end

  include_examples '[path] testing examples'
  include_examples '[filetypes] testing examples'
end
