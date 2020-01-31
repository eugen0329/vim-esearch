# frozen_string_literal: true

require 'spec_helper'

describe 'esearch window context syntax' do
  include Helpers::FileSystem
  include Helpers::WindowSyntaxContext

  describe 'ruby' do
    let(:source_text) do
      <<~SOURCE_TEXT
        <div attr1="1"></div>
        <nonexisting-tag at-tr2='2'></nonexisting-tag>
      SOURCE_TEXT
    end
    let(:source_file) { file(source_text, 'main.html') }
    let!(:test_directory) { directory([source_file], 'window/syntax/').persist! }

    before do
      esearch.configure!(regex: 1, backend: 'system', adapter: 'ag')
      esearch.search! '^', cwd: source_file.path.to_s
    end

    it 'contains matches' do
      is_expected.to have_highligh_aliases(
        region('<div', at: ..1)             => %w[htmlTag Function],
        region('<nonexisting-tag', at: ..1) => %w[htmlTag Function],
        region('</div', at: ..2)            => %w[htmlEndTag Identifier],
        region('<div', at: 1..)             => %w[htmlTagName Statement],
        region('</div', at: 2..)            => %w[htmlTagName Statement],
        word('attr1')                       => %w[htmlTag Function],
        word('at-tr2')                      => %w[htmlTag Function],
        region('"1"')                       => %w[htmlString String],
        region("'2'")                       => %w[htmlString String]
      )
    end

    it 'keeps lines highligh untouched' do
      expect(source_text).to have_line_numbers_highlight(%w[esearchLnum LineNr])
    end
  end
end
