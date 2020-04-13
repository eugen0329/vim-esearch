# frozen_string_literal: true

require 'spec_helper'
require_relative 'setup_syntax_testing_shared_context'

describe 'esearch window context syntax', :window do
  include Helpers::FileSystem
  include Helpers::WindowSyntaxContext

  describe 'yaml' do
    # blank line is kept intentionally to know whether the last verified line
    # corrupts LineNr virtual UI or not

    let(:source_file_content) do
      <<~SOURCE
        key1_with_ws_before_delim :
        key1:
        key2: null
        key3: true
        key4: false
        key5: &anchor
        <<:   *alias
        key6: 'str'
        key7: "str"
        key8: 'missing quote
        key9: "missing quote
        key10: [1, 'collection str1', "collection str2", {"kw1": [], 'kw2': null }]
        key10: # comment
        key10: #comment
        key11:
          - collection item

      SOURCE
    end
    let(:source_file) { file(source_file_content, 'main.yml') }

    include_context 'setup syntax testing'

    # 1. Verification is done in a single example for performance reasons (as
    # vim's +clientserver is too sluggish; it doesn't affect debuggability as
    # the matcher is diffable)
    # 2. Lines that can cause matching across line end (e.g. not terminated strings
    # or comments) are not groupped and scattered across source_file to cause as
    # more potential errors as possible
    it do
      is_expected.to have_highlight_aliases(
        word('null')                => %w[es_yamlNull Constant],
        word('true')                => %w[es_yamlBool Boolean],
        word('false')               => %w[es_yamlBool Boolean],

        char('-')                   => %w[es_yamlBlockCollectionItemStart Label],
        char('[')                   => %w[es_yamlFlowIndicator Special],
        char(']')                   => %w[es_yamlFlowIndicator Special],
        char('{')                   => %w[es_yamlFlowIndicator Special],
        char('}')                   => %w[es_yamlFlowIndicator Special],
        char(':')                   => %w[es_yamlKeyValueDelimiter Special],
        region('<<')                => %w[es_yamlMappingMerge Special],

        region('&anchor')           => %w[es_yamlAnchorOrAnchor Type],
        region('\*alias')           => %w[es_yamlAnchorOrAnchor Type],

        region('"str')              => %w[es_yamlFlowString String],
        region("'str")              => %w[es_yamlFlowString String],
        region("'collection str1'") => %w[es_yamlFlowString String],
        region('"collection str2"') => %w[es_yamlFlowString String],
        region('"missing quote')    => %w[es_yamlFlowString String],
        region("'missing quote")    => %w[es_yamlFlowString String],

        region('"kw1"')             => %w[es_yamlFlowString String],
        region("'kw2'")             => %w[es_yamlFlowString String],

        region('# comment')         => %w[es_yamlComment Comment],
        region('#comment')          => %w[es_yamlComment Comment],

        region('key\d\+')           => %w[es_yamlBlockMappingKey Identifier]
      )
    end
  end
end
