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
      {"kw1": null, "kw2": true "kw3": false, "kw4": [], "kw5": {}, "kw6": "val6"}
      {"kw7": "missing quote
      {"kw8": null,
      {"missing keyword quote
      {"kw9": [

      SOURCE
    end
    let(:source_file) { file(source_file_content, 'main.json') }

    include_context 'setup syntax testing'

    # 1. Verification is done in a single example for performance reasons (as
    # vim's +clientserver is too sluggish; it doesn't affect debuggability as
    # the matcher is diffable)
    # 2. Lines that can cause matching across line end (e.g. not terminated strings
    # or comments) are not groupped and scattered across source_file to cause as
    # more potential errors as possible
    it do
      is_expected.to have_highligh_aliases(
        word('null')                     => %w[es_jsonNull Function],
        word('true')                     => %w[es_jsonBoolean Boolean],
        word('false')                    => %w[es_jsonBoolean Boolean],

        char('[')                    => %w[es_jsonBraces Delimiter],
        char(']')                    => %w[es_jsonBraces Delimiter],
        char('{')                    => %w[es_jsonBraces Delimiter],
        char('}')                    => %w[es_jsonBraces Delimiter],
        char(':')                    => %w[es_ctx_json cleared],

        region('"val6"')         => %w[es_jsonString String],
        region('"missing quote') => %w[es_jsonString String],
        region('"missing keyword quote') => %w[es_jsonString String],

        region('"kw1"') => %w[es_jsonKeyword Label],
        region('"kw2"') => %w[es_jsonKeyword Label],
        region('"kw3"') => %w[es_jsonKeyword Label],
        region('"kw4"') => %w[es_jsonKeyword Label],
        region('"kw5"') => %w[es_jsonKeyword Label],
        region('"kw6"') => %w[es_jsonKeyword Label],
        region('"kw7"') => %w[es_jsonKeyword Label],
        region('"kw8"') => %w[es_jsonKeyword Label],
        region('"kw9"') => %w[es_jsonKeyword Label],
      )
    end
  end
end

