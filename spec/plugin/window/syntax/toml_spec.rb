# frozen_string_literal: true

require 'spec_helper'
require_relative 'setup_syntax_testing_shared_context'

describe 'esearch window context syntax', :window do
  include Helpers::FileSystem
  include Helpers::WindowSyntaxContext

  describe 'json' do
    # blank line is kept intentionally to know whether the last verified line
    # corrupts LineNr virtual UI or not

    let(:source_file_content) do
      <<~SOURCE
        true false

        "es_tomlString"
        """es_tomlString"""
        'es_tomlString'
        '''es_tomlString'''


        'missing quote
        "missing quote
        'escaped quote
        "escaped quote

        "es_tomlKeyDq" =
        'es_tomlKeySq' = ["es_tomlString"]
         es_tomlKey =

        [es_tomlTable]  #es_tomlComment
        [es.tomlTable]  #es_tomlComment
        [[es_tomlTableArray]] # es_tomlComment
        [[es.tomlTableArray]] # es_tomlComment

      SOURCE
    end
    let(:source_file) { file(source_file_content, 'main.toml') }

    include_context 'setup syntax testing'

    # 1. Verification is done in a single example for performance reasons (as
    # vim's +clientserver is too sluggish; it doesn't affect debuggability as
    # the matcher is diffable)
    # 2. Lines that can cause matching across line end (e.g. not terminated strings
    # or comments) are not groupped and scattered across source_file to cause as
    # more potential errors as possible
    it do
      is_expected.to have_highligh_aliases(
        word('true')                         => %w[es_tomlBoolean Boolean],
        word('false')                        => %w[es_tomlBoolean Boolean],

        region("'es_tomlString'")            => %w[es_tomlString String],
        region('"es_tomlString"')            => %w[es_tomlString String],
        region('"escaped quote')             => %w[es_ctx_toml cleared],
        region('"missing quote')             => %w[es_ctx_toml cleared],
        region("'missing quote")             => %w[es_ctx_toml cleared],
        region("'escaped quote")             => %w[es_ctx_toml cleared],

        region("'es_tomlKeySq'")             => %w[es_tomlKeySq Identifier],
        region('"es_tomlKeyDq"')             => %w[es_tomlKeyDq Identifier],
        word('es_tomlKey')                   => %w[es_tomlKey Identifier],
        region('\[es_tomlTable\]')           => %w[es_tomlTable Title],
        region('\[es\.tomlTable\]')          => %w[es_tomlTable Title],
        region('\[\[es_tomlTableArray\]\]')  => %w[es_tomlTableArray Title],
        region('\[\[es\.tomlTableArray\]\]') => %w[es_tomlTableArray Title],
        region('#es_tomlComment')            => %w[es_tomlComment Comment],
        region('# es_tomlComment')           => %w[es_tomlComment Comment]
      )
    end
  end
end
