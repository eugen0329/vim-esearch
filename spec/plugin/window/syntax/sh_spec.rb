# frozen_string_literal: true

require 'spec_helper'

describe 'esearch window context syntax' do
  include Helpers::FileSystem
  include Helpers::WindowSyntaxContext

  describe 'sh' do
    let(:sh_code) do
      <<~SH_CODE
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
      SH_CODE
    end
    let(:source_file) { file(sh_code, 'main.sh') }
    let!(:test_directory) { directory([source_file], 'window/syntax/').persist! }

    before do
      esearch.configure!(regex: 1, backend: 'system', adapter: 'ag')
      esearch.search! '^', cwd: source_file.path.to_s
    end

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

    it 'keeps lines highligh untouched' do
      expect(sh_code).to have_line_numbers_highlight(%w[esearchLnum LineNr])
    end
  end
end
