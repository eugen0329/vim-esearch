# frozen_string_literal: true

require 'spec_helper'
require_relative 'setup_syntax_testing_shared_context'

describe 'esearch window context syntax', :window do
  include Helpers::FileSystem
  include Helpers::WindowSyntaxContext

  describe 'hcl' do
    # blank line is kept intentionally to know whether the last verified line
    # corrupts LineNr virtual UI or not

    let(:source_file_content) do
      <<~SOURCE
        telemetry {}

        resource "aws_key_pair" "auth" {}

        resource "aws" {
          name = "es_hclValueString"
          route_table_id = "${es_hclStringInterp}"
          route_table_id = "${es.hclStringInterp}"
          map_public_ip_on_launch = [true, false]

          #comment
          # comment
          //comment
          // comment
          /*comment*/
          /* comment */
          /*comment
          /* comment

          content
          in
          for
          if
          string
          bool
          number
          tuple
          object
          list
          map
          set
          null
        }

      SOURCE
    end
    let(:source_file) { file(source_file_content, 'main.hcl') }

    include_context 'setup syntax testing'

    # 1. Verification is done in a single example for performance reasons (as
    # vim's +clientserver is too sluggish; it doesn't affect debuggability as
    # the matcher is diffable)
    # 2. Lines that can cause matching across line end (e.g. not terminated strings
    # or comments) are not groupped and scattered across source_file to cause as
    # more potential errors as possible
    it do
      is_expected.to have_highligh_aliases(
        word('telemetry')               => %w[es_hclSection Structure],
        word('resource')                => %w[es_hclSection Structure],
        region('"es_hclValueString"')   => %w[es_hclValueString String],
        region('${es_hclStringInterp}') => %w[es_hclStringInterp Identifier],
        region('${es.hclStringInterp}') => %w[es_hclStringInterp Identifier],
        region('#comment')              => %w[es_hclComment Comment],
        region('# comment')             => %w[es_hclComment Comment],
        region('//comment')             => %w[es_hclComment Comment],
        region('// comment')            => %w[es_hclComment Comment],
        region('/\*comment\*/')         => %w[es_hclComment Comment],
        region('/\* comment \*/')       => %w[es_hclComment Comment],
        region('/\*comment')            => %w[es_hclComment Comment],
        region('/\* comment ')          => %w[es_hclComment Comment],
        char('[')                       => %w[es_hclBraces Delimiter],
        char(']')                       => %w[es_hclBraces Delimiter],
        word('content')                 => %w[es_hclContent Structure],
        word('in')                      => %w[es_hclRepeat Repeat],
        word('for')                     => %w[es_hclRepeat Repeat],
        word('if')                      => %w[es_hclConditional Conditional],
        word('string')                  => %w[es_hclPrimitiveType Type],
        word('bool')                    => %w[es_hclPrimitiveType Type],
        word('number')                  => %w[es_hclPrimitiveType Type],
        word('tuple')                   => %w[es_hclStructuralType Type],
        word('object')                  => %w[es_hclStructuralType Type],
        word('list')                    => %w[es_hclCollectionType Type],
        word('map')                     => %w[es_hclCollectionType Type],
        word('set')                     => %w[es_hclCollectionType Type],
        word('null')                    => %w[es_hclValueNull Constant]
      )
    end
  end
end
