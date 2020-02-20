# frozen_string_literal: true

require 'spec_helper'
require 'plugin/shared_examples/backend'
require 'plugin/shared_examples/abortable_backend'

# TODO: testing
# - test directories with spaces in names
# - abosolute path
# - outside cwd
# - single file should be tested separately
describe 'esearch#adapter', :adapter do
  include Helpers::FileSystem
  include Helpers::Strings
  include Helpers::Output
  include Helpers::ReportEditorStateOnError
  include Helpers::Commandline

  include_context 'report editor state on error'

  shared_examples 'adapter testing examples' do |adapter, adapter_bin|
    describe "##{adapter}" do
      before do
        esearch.configure!(adapter: adapter, out: 'win', backend: 'system', regex: 1, use: [])
        esearch.configuration.adapter_bin = adapter_bin if adapter_bin
      end
      after { esearch.cleanup! }
      let!(:test_directory) { directory(files).persist! }

      shared_examples 'search specifying custom paths' do |paths_string:, expected_names:, files:|
        let(:files) { files }
        before { editor.cd! test_directory }

        it do
          editor.send_keys(*open_input_keys, '.*', *open_menu_keys)
          editor.send_keys(*open_paths_input_keys, paths_string, :enter, :enter)

          KnownIssues.mark_example_pending_if_known_issue(self) do
            expect(esearch).to finish_search_in_files(expected_names)
          end
        end
      end

      context 'ugly names' do
        let(:test_directory) { directory(files) }
        around { |e| temporary_persist_and_add_to_index(test_directory, &e) }

        it_behaves_like 'search specifying custom paths',
          paths_string:   %q[
             with\\\\ ws/file.e
             with\\\\\\\\backslash/file.e
             with\\\\'squote/file.e
             with\\\\"dquote/file.e
          ].gsub("\n", ' '),
          expected_names: [
            'with ws/file.e',
            'with\\backslash/file.e',
            "with'squote/file.e",
            'with"dquote/file.e'
          ],
          files:          [
            file('any content', 'with ws/file.e'),
            file('any content', 'with\\backslash/file.e'),
            file('any content', "with'squote/file.e"),
            file('any content', 'with"dquote/file.e'),
            file('any content', 'with\\ws/file.e'),
            file('any content', 'withws/file.e'),
            file('any content', 'with backslash/file.e'),
            file('any content', 'other/file.e')
          ]

        context 'when searching using prefilled directories' do
          let(:files) do
            [file('any content', '*.txt'),
             file('any content', 'b c.json')]
          end
          let!(:test_directory) { directory(files).persist! }
          let(:names) { files.map(&:relative_path) }
          let(:paths_string) { '\\\\*.txt b\\\\ c.json' }

          before do
            editor.cd! test_directory
            editor.send_keys(*open_input_keys, '.*', *open_menu_keys)
            editor.send_keys(*open_paths_input_keys, paths_string, :enter, :enter)
            expect(esearch).to finish_search_in_files(names) # fail fast
            editor.close_current_window!
          end

          it do
            editor.send_keys(*open_input_keys, '.*', *open_menu_keys)
            editor.send_keys(*open_paths_input_keys)
            expect(editor).to have_commandline_content(inputted_keys(paths_string))
            editor.send_keys(:enter, :enter)

            expect(esearch).to finish_search_in_files(names)
          end
        end
      end

      context 'globbing' do
        context 'single *' do
          it_behaves_like 'search specifying custom paths',
            paths_string:   '*.txt',
            expected_names: ['a.txt', 'b.txt', '*.txt'],
            files:          [
              file('any content', 'a.txt'),
              file('any content', 'b.txt'),
              file('any content', '*.txt'),
              file('any content', 'c.json')
            ]
        end

        context 'escaped *' do
          it_behaves_like 'search specifying custom paths',
            paths_string:   '\\\\*.txt',
            expected_names: ['*.txt'],
            files:          [
              file('any content', 'a.txt'),
              file('any content', 'b.txt'),
              file('any content', '*.txt'),
              file('any content', 'c.json')
            ]
        end
      end
    end
  end

  shared_examples 'all adapters testing examples' do
    include_examples 'adapter testing examples', 'ag'
    include_examples 'adapter testing examples', 'ack'
    include_examples 'adapter testing examples', 'git'
    include_examples 'adapter testing examples', 'grep'
    include_examples 'adapter testing examples', 'pt', Configuration.pt_path
    include_examples 'adapter testing examples', 'rg', Configuration.rg_path
  end

  describe '#nvim' do
    around(Configuration.vimrunner_switch_to_neovim_callback_scope) { |e| use_nvim(&e) }

    include_examples 'all adapters testing examples'
  end

  describe '#vim', :vim do
    include_examples 'all adapters testing examples'
  end
end
