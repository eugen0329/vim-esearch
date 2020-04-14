# frozen_string_literal: true

require 'spec_helper'
require_relative 'setup_syntax_testing_shared_context'

describe 'esearch window context syntax', :window do
  include Helpers::FileSystem
  include Helpers::WindowSyntaxContext

  describe 'xml' do
    # blank line is kept intentionally to know whether the last verified line
    # corrupts LineNr virtual UI or not

    let(:source_file_content) do
      <<~SOURCE
        <?xml version="1.0" encoding="UTF-8"?>

        <es_xmlTag es_xmlAttrib="es_xmlString"></es_xmlEndTag>
        <es_xmlTag es_xmlAttrib="es_xmlString"></es_xmlEndTag
        <es_xmlTag es_xmlAttrib="es_xmlString"></
        <es_xmlTag es_xmlAttrib="es_xmlString">
        <es_xmlTag es_xmlAttrib="es_xmlString\\"
        <es_xmlTag es_xmlAttrib="es_xmlString"
        <es_xmlTag es_xmlAttrib="es_xmlString
        <es_xmlTag es_xmlAttrib="
        <es_xmlTag es_xmlAttrib=
        <es_xmlTag
        <

        <es_xmlTag es_xmlAttrib='es_xmlString'></es_xmlEndTag>
        <es_xmlTag es_xmlAttrib='es_xmlString'></es_xmlEndTag
        <es_xmlTag es_xmlAttrib='es_xmlString'></
        <es_xmlTag es_xmlAttrib='es_xmlString'>
        <es_xmlTag es_xmlAttrib='es_xmlString\\'
        <es_xmlTag es_xmlAttrib='es_xmlString'
        <es_xmlTag es_xmlAttrib='es_xmlString

        <!es_xmlComment>
        <! es_xmlComment >
        <!--es_xmlComment-->
        <!-- es_xmlComment -->
        <!--es_xmlComment
        <!-- es_xmlComment

      SOURCE
    end
    let(:source_file) { file(source_file_content, 'main.xml') }

    include_context 'setup syntax testing'

    # 1. Verification is done in a single example for performance reasons (as
    # vim's +clientserver is too sluggish; it doesn't affect debuggability as
    # the matcher is diffable)
    # 2. Lines that can cause matching across line end (e.g. not terminated strings
    # or comments) are not groupped and scattered across source_file to cause as
    # more potential errors as possible
    it do
      is_expected.to have_highlight_aliases(
        region('<?')                     => %w[es_xmlProcessingDelim Comment],
        region('?>')                     => %w[es_xmlProcessingDelim Comment],
        region('<?\zsxml')               => %w[es_xmlProcessingAttrib Type],
        region('version')                => %w[es_xmlProcessingAttrib Type],
        region('encoding')               => %w[es_xmlProcessingAttrib Type],
        region('"1.0"')                  => %w[es_xmlString String],
        region('"UTF-8"')                => %w[es_xmlString String],

        region('<es_xmlTag')             => %w[es_xmlTag Function],
        region('</es_xmlEndTag')         => %w[es_xmlEndTag Identifier],
        region('es_xmlAttrib')           => %w[es_xmlAttrib Type],
        region('"es_xmlString"')         => %w[es_xmlString String],
        region('"es_xmlString"')         => %w[es_xmlString String],

        region('<!es_xmlComment>')       => %w[es_xmlComment Comment],
        region('<! es_xmlComment >')     => %w[es_xmlComment Comment],
        region('<!--es_xmlComment-->')   => %w[es_xmlComment Comment],
        region('<!-- es_xmlComment -->') => %w[es_xmlComment Comment],
        region('<!--es_xmlComment')      => %w[es_xmlComment Comment],
        region('<!-- es_xmlComment')     => %w[es_xmlComment Comment]
      )
    end
  end
end
