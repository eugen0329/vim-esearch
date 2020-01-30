# frozen_string_literal: true

require 'spec_helper'

describe 'esearch window context syntax' do
  include Helpers::FileSystem
  include Helpers::Syntax

  describe 'ruby' do
    let(:html_code) do
      <<~HTML_CODE
        <div attr1="1"></div>
        <nonexisting-tag at-tr2='2'></nonexisting-tag>
      HTML_CODE
    end
    let(:main_html) { file(html_code, 'main.html') }
    let!(:test_directory) { directory([main_html], 'window/syntax/').persist! }

    before do
      # esearch.editor.command('set background=dark | colorscheme solarized')
      esearch.editor.command('colorscheme default')
      esearch.configure!(regex: 1, backend: 'system', adapter: 'ag')
      esearch.search! '^', cwd: main_html.path.to_s
    end

    it 'contains matches' do
      is_expected.to have_highlights(
        '<div':             %w[htmlTag Function],
        '<nonexisting-tag': %w[htmlTag Function],
        '<\\zsdiv':         %w[htmlTagName Statement],
        '</\\zsdiv':        %w[htmlTagName Statement],
        '\\zs</div':        %w[htmlEndTag Identifier],
        '<\\zs/div':        %w[htmlEndTag Identifier],
        'attr1':            %w[htmlTag Function],
        'at-tr2':           %w[htmlTag Function],
        '"1"':              %w[htmlString String],
        "'2'":              %w[htmlString String]
      )
    end

    it 'keeps lines highligh untouched' do
      expect(html_code).to have_line_numbers_highlight(%w[esearchLnum LineNr])
    end
  end
end
