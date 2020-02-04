# frozen_string_literal: true

require 'spec_helper'
require 'plugin/shared_examples/backend'
require 'plugin/shared_examples/abortable_backend'

describe 'esearch#backend', :backend do
  include Helpers::FileSystem
  include Helpers::Strings
  include Helpers::OutputErrors
  include Helpers::ReportEditorStateOnError
  include Helpers::Commandline

  before { esearch.configure(out: 'win', backend: 'system', use: 'last') }
  after do
    esearch.cleanup!
    esearch.output.reset_calls_history!
  end

  context '' do
    let(:files) do
      [
        file('a', 'a/file1.txt'),
        file('a', 'b/file2.txt'),
        file('a', 'c/file3.txt'),
      ]
    end
    let(:search_directory) { directory(files).persist! }

    it do
      editor.cd! search_directory
      editor.send_keys(*open_input_keys, *open_menu_keys)
      editor.send_keys_separately('p', 'a b', :enter)
      editor.send_keys_separately('a', :enter)

      expect(esearch.output.entries.map(&:relative_path))
        .to match_array(['a/file1.txt', 'b/file2.txt'])
    end
  end
end
