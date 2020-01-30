# frozen_string_literal: true

require 'spec_helper'

describe 'esearch window context syntax' do
  include Helpers::FileSystem
  include Helpers::Syntax

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
      is_expected.to have_highlights(
        '\\$deref':      %w[shDerefSimple PreProc],
        '\\$1':          %w[shDerefSimple PreProc],

        'case':          %w[shKeyword Keyword],
        'esac':          %w[shKeyword Keyword],
        'do':            %w[shKeyword Keyword],
        'done':          %w[shKeyword Keyword],
        'for':           %w[shKeyword Keyword],
        'in':            %w[shKeyword Keyword],
        'if':            %w[shKeyword Keyword],
        'fi':            %w[shKeyword Keyword],
        'until':         %w[shKeyword Keyword],
        'while':         %w[shKeyword Keyword],

        '"string"':      %w[shDoubleQuote String],
        '"string\\\\n"': %w[shDoubleQuote String],
        "'string'":      %w[shSingleQuote String]
      )
    end

    it 'keeps lines highligh untouched' do
      expect(sh_code).to have_line_numbers_highlight(%w[esearchLnum LineNr])
    end
  end
end
