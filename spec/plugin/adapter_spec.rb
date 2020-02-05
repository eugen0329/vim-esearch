# frozen_string_literal: true

require 'spec_helper'
require 'plugin/shared_examples/backend'
require 'plugin/shared_examples/abortable_backend'


# TODO test directories with spaces in names
describe 'esearch#backend', :backend do
  include Helpers::FileSystem
  include Helpers::Strings
  include Helpers::OutputErrors
  include Helpers::ReportEditorStateOnError
  include Helpers::Commandline

  include_context 'report editor state on error'

  shared_examples 'adapter testing examples' do |adapter, adapter_bin|
    describe "#{adapter} adapter", :custom_paths, adapter.to_sym do
      before do
        esearch.configure!(adapter: adapter, out: 'win', backend: 'system', use: 'last')
        esearch.configuration.adapter_bin = adapter_bin if adapter_bin
      end
      after { esearch.cleanup! }

      context '2 dirs' do
        let(:files) do
          [
            file('a', 'a/file1.txt'),
            file('a', 'b/file2.txt'),
            file('a', 'c/file3.txt')
          ]
        end
        let(:test_directory) { directory(files, '2 dirs listed').persist! }

        it do
          editor.cd! test_directory
          editor.send_keys(*open_input_keys, *open_menu_keys)
          editor.send_keys_separately('p', 'a b', :enter)
          editor.send_keys_separately('a', :enter)

          expect(esearch).to have_search_started
          expect(esearch)
            .to  have_search_finished
            .and have_not_reported_errors
          expect(esearch.output.entries.map(&:relative_path))
            .to match_array(['a/file1.txt', 'b/file2.txt'])
        end
      end

      context 'weird names' do
        let(:files) do
          [
            file('a', 'f le1/a.txt'),
            file('a', 'f\\le2"/b.txt'),
            file('a', 'c/file3.txt')
          ]
        end
        let(:test_directory) { directory(files, 'weird_names/').persist! }

        it do
          editor.cd! test_directory
          editor.send_keys(*open_input_keys, *open_menu_keys)
          editor.send_keys_separately('p', 'f\\\\ le1/a.txt "f\\\\\\\\le2"\\\\"', :enter)
          editor.send_keys_separately('a', :enter)

          expected_files = ['f le1/a.txt', 'f\\le2"/b.txt']
          expected_files = expected_files.map do |p|
            next p unless  p.include?('"')
            "\"#{Shellwords.escape(p)}\""
          end if adapter =='git'

          expect(esearch).to have_search_started
          expect(esearch)
            .to  have_search_finished
            .and have_not_reported_errors
          expect(esearch.output.entries.map(&:relative_path))
            .to match_array(expected_files)
        end
      end

      context 'globbing' do
        context 'unescaped *' do
          let(:files) do
            [
              file('a', 'a.ext1'),
              file('a', 'b.ext1'),
              file('a', 'c.ext2')
            ]
          end
          let(:test_directory) { directory(files, 'globbing_unescaped/').persist! }

          it do
            editor.cd! test_directory
            editor.send_keys(*open_input_keys, *open_menu_keys)
            editor.send_keys_separately('p', '*.ext1', :enter)
            editor.send_keys_separately('a', :enter)

            expect(esearch).to have_search_started
            expect(esearch)
              .to  have_search_finished
              .and have_not_reported_errors
            expect(esearch.output.entries.map(&:relative_path))
              .to match_array(['a.ext1', 'b.ext1'])
          end
        end

        # + single file should be tested separately
        context 'escaped *' do
          let(:files) do
            [
              file('a', 'a.ext1'),
              file('a', 'b.ext1'),
              file('a', 'c.ext2'),
              file('a', '*.ext1')
            ]
          end
          let(:test_directory) { directory(files, 'globbing_escaped/').persist! }

          it do
            editor.cd! test_directory
            editor.send_keys(*open_input_keys, *open_menu_keys)
            editor.send_keys_separately('p', '\\\\*.ext1', :enter)
            editor.send_keys_separately('a', :enter)

            expect(esearch).to have_search_started
            expect(esearch)
              .to  have_search_finished
              .and have_not_reported_errors
            expect(esearch.output.entries.map(&:relative_path))
              .to match_array(['*.ext1'])
          end
        end
      end
    end
  end

  include_examples 'adapter testing examples', 'ag'
  include_examples 'adapter testing examples', 'ack'
  include_examples 'adapter testing examples', 'git'
  include_examples 'adapter testing examples', 'grep'
  include_examples 'adapter testing examples', 'pt', Configuration.pt_path
  include_examples 'adapter testing examples', 'rg', Configuration.rg_path
end
