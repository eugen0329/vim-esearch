# frozen_string_literal: true

require 'spec_helper'

describe 'esearch window context syntax' do
  include Helpers::FileSystem
  include Helpers::WindowSyntaxContext

  describe 'sh' do
    let(:sh_code) do
      <<~SH_CODE
        $deref
        $1

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

        'string'
        "string"
        "string\\n"
      SH_CODE
    end
    let(:main_sh) { file(sh_code, 'main.sh') }
    let!(:test_directory) { directory([main_sh], 'window/syntax/').persist! }

    before do
      esearch.configure!(regex: 1, backend: 'system', adapter: 'ag')
      esearch.search! '^', cwd: main_sh.path.to_s
    end

    it 'contains matches' do
      is_expected.to have_highligh_aliases(
        region('\\$deref')      => %w[shDerefSimple PreProc],
        region('\\$1')          => %w[shDerefSimple PreProc],

        word('case')            => %w[shKeyword Keyword],
        word('esac')            => %w[shKeyword Keyword],
        word('do')              => %w[shKeyword Keyword],
        word('done')            => %w[shKeyword Keyword],
        word('for')             => %w[shKeyword Keyword],
        word('in')              => %w[shKeyword Keyword],
        word('if')              => %w[shKeyword Keyword],
        word('fi')              => %w[shKeyword Keyword],
        word('until')           => %w[shKeyword Keyword],
        word('while')           => %w[shKeyword Keyword],

        region('"string"')      => %w[shDoubleQuote String],
        region('"string\\\\n"') => %w[shDoubleQuote String],
        region("'string'")      => %w[shSingleQuote String]
      )
    end

    it 'keeps lines highligh untouched' do
      expect(sh_code).to have_line_numbers_highlight(%w[esearchLnum LineNr])
    end
  end
end
