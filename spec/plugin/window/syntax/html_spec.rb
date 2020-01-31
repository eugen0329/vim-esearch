# frozen_string_literal: true

require 'spec_helper'

describe 'esearch window context syntax' do
  include Helpers::FileSystem
  include Helpers::WindowSyntaxContext

  describe 'ruby' do
    let(:source_text) do
      <<~SOURCE_TEXT
        <div attr="double-quoted"></div>

        <div attr=

        <div1 attr="unterminated double-quoted
        <any-other-tag>

        <div2 attr='unterminated single-quoted
        <nonexisting-tag at-tr='single-quoted'></nonexisting-tag>

        <without-closing-tag>
        <any-other-tag>

        <incorrectly-closed></incorrectly-closed
        <any-other-tag>
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
        region('<div', at: ..1)                 => %w[htmlTag Function],
        region('<div', at: 1..)                 => %w[htmlTagName Statement],
        region('</div', at: ..2)                => %w[htmlEndTag Identifier],
        region('</div', at: 2..)                => %w[htmlTagName Statement],

        region('<nonexisting-tag', at: ..1)     => %w[htmlTag Function],
        word('attr')                            => %w[htmlTag Function],
        region('attr=$')                        => %w[htmlTag Function],
        word('at-tr')                           => %w[htmlTag Function],
        region('"double-quoted"')               => %w[htmlString String],
        region("'single-quoted'")               => %w[htmlString String],

        region('"unterminated double-quoted')   => %w[htmlString String],
        region("'unterminated single-quoted")   => %w[htmlString String],
        region('<without-closing-tag', at: ..1) => %w[htmlTag Function],
        region('<without-closing-tag', at: 1..) => %w[htmlTagName Statement],

        region('<incorrectly-closed', at: ..1)  => %w[htmlTag Function],
        region('<incorrectly-closed', at: 1..)  => %w[htmlTagName Statement],
        region('</incorrectly-closed', at: ..2) => %w[htmlEndTag Identifier],
        region('</incorrectly-closed', at: 2..) => %w[htmlTagName Statement]
      )
    end

    it 'keeps lines highligh untouched' do
      expect(source_text).to have_line_numbers_highlight(%w[esearchLnum LineNr])
    end
  end
end
