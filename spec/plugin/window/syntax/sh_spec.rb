# frozen_string_literal: true

require 'spec_helper'
require_relative 'setup_syntax_testing_shared_context'

describe 'esearch window context syntax' do
  include Helpers::FileSystem
  include Helpers::WindowSyntaxContext

  describe 'sh' do
    let(:source_file_content) do
      <<~SOURCE
        'string'
        "string"
        "string\\n"

        $deref
        $1

        "unterminated string
        'unterminated string

        case
        esac
        do
        done
        for
        in
        if
        fi
        until
        while
      SOURCE
    end
    let(:source_file) { file(source_file_content, 'main.sh') }
    include_context 'setup syntax testing'

    it do
      is_expected.to have_highligh_aliases(
        region('"string"')             => %w[es_shDoubleQuote String],
        region('"string\\\\n"')        => %w[es_shDoubleQuote String],
        region("'string'")             => %w[es_shSingleQuote String],

        region('\\$deref')             => %w[es_shDerefSimple PreProc],
        region('\\$1')                 => %w[es_shDerefSimple PreProc],

        region("'unterminated string") => %w[es_shSingleQuote String],
        region('"unterminated string') => %w[es_shDoubleQuote String],

        word('case')                   => %w[es_shKeyword Keyword],
        word('esac')                   => %w[es_shKeyword Keyword],
        word('do')                     => %w[es_shKeyword Keyword],
        word('done')                   => %w[es_shKeyword Keyword],
        word('for')                    => %w[es_shKeyword Keyword],
        word('in')                     => %w[es_shKeyword Keyword],
        word('if')                     => %w[es_shKeyword Keyword],
        word('fi')                     => %w[es_shKeyword Keyword],
        word('until')                  => %w[es_shKeyword Keyword],
        word('while')                  => %w[es_shKeyword Keyword]
      )
    end
  end
end
