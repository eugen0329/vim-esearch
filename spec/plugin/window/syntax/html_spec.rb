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
      # esearch.editor.command('set background=dark | colorscheme solarized')
      # esearch.editor.command('colorscheme default')
      esearch.configure!(regex: 1, backend: 'system', adapter: 'ag')
      esearch.search! '^', cwd: source_file.path.to_s
    end

    it 'contains matches' do
      is_expected.to have_highligh_aliases(
        '<\\zediv'             => %w[htmlTag Function],
        '<\\zenonexisting-tag' => %w[htmlTag Function],
        '<\\zsdiv'             => %w[htmlTagName Statement],
        '</\\zsdiv'            => %w[htmlTagName Statement],
        '\\zs</\\zediv'        => %w[htmlEndTag Identifier],
        '<\\zs/\\zediv'        => %w[htmlEndTag Identifier],
        '</\\zsdiv\\ze'        => %w[htmlTagName Statement],
        'attr1'                => %w[htmlTag Function],
        'at-tr2'               => %w[htmlTag Function],
        '"1"'                  => %w[htmlString String],
        "'2'"                  => %w[htmlString String]
      )
    end

    it 'keeps lines highligh untouched' do
      expect(source_text).to have_line_numbers_highlight(%w[esearchLnum LineNr])
    end
  end
end
