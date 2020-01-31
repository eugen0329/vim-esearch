# frozen_string_literal: true

require 'spec_helper'
require_relative 'setup_syntax_testing_shared_context'

describe 'esearch window context syntax' do
  include Helpers::FileSystem
  include Helpers::WindowSyntaxContext

  describe 'ruby' do
    let(:source_file_content) do
      <<~SOURCE
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
      SOURCE
    end
    let(:source_file) { file(source_file_content, 'main.html') }

    include_context 'setup syntax testing'

    # 1. Verification is done in a single example for performance reasons (as
    # vim's +clientserver is too sluggish; it doesn't affect debuggability as
    # the matcher is diffable)
    # 2. Lines that can cause matching across line end (e.g. not terminated strings
    # or comments) are not groupped and scattered across source_file to cause as
    # more potential errors as possible
    it do
      is_expected.to have_highligh_aliases(
        region('<div', at: ..1)                 => %w[es_htmlTag Function],
        region('<div', at: 1..)                 => %w[es_htmlTagName Statement],
        region('</div', at: ..2)                => %w[es_htmlEndTag Identifier],
        region('</div', at: 2..)                => %w[es_htmlTagName Statement],

        region('<nonexisting-tag', at: ..1)     => %w[es_htmlTag Function],
        word('attr')                            => %w[es_htmlTag Function],
        region('attr=$')                        => %w[es_htmlTag Function],
        word('at-tr')                           => %w[es_htmlTag Function],
        region('"double-quoted"')               => %w[es_htmlString String],
        region("'single-quoted'")               => %w[es_htmlString String],

        region('"unterminated double-quoted')   => %w[es_htmlString String],
        region("'unterminated single-quoted")   => %w[es_htmlString String],
        region('<without-closing-tag', at: ..1) => %w[es_htmlTag Function],
        region('<without-closing-tag', at: 1..) => %w[es_htmlTagName Statement],

        region('<incorrectly-closed', at: ..1)  => %w[es_htmlTag Function],
        region('<incorrectly-closed', at: 1..)  => %w[es_htmlTagName Statement],
        region('</incorrectly-closed', at: ..2) => %w[es_htmlEndTag Identifier],
        region('</incorrectly-closed', at: 2..) => %w[es_htmlTagName Statement]
      )
    end
  end
end
