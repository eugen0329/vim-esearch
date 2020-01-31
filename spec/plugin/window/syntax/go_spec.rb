# frozen_string_literal: true

require 'spec_helper'

describe 'esearch window context syntax' do
  include Helpers::FileSystem
  include Helpers::WindowSyntaxContext

  describe 'go' do
    let(:go_code) do
      <<~GO_CODE
        package main
        import "fmt"

        var a int
        const b int
        func main() {}
        type _ struct {}
        type _ interface {}

        "string"
        "str with escaped slash\"
        "str with escape\\n"
        "long string#{'.' * 100}"
        `raw string`

        defer
        go
        goto
        return
        break
        continue
        fallthrough

        "unterminated string
        `unterminated raw string

        case
        default

        // comment line
        /* comment block */
        /* long comment #{'.' * 100}*/

        for {}
        range()
      GO_CODE
    end
    let(:main_go) { file(go_code, 'main.go') }
    let!(:test_directory) { directory([main_go], 'window/syntax/').persist! }

    before do
      esearch.configure!(regex: 1, backend: 'system', adapter: 'ag')
      esearch.search! '^', cwd: main_go.path.to_s
    end

    it do
      is_expected.to have_highligh_aliases(
        word('package')                      => %w[es_goDirective Statement],
        word('import')                       => %w[es_goDirective Statement],

        word('var')                          => %w[es_goDeclaration Keyword],
        word('const')                        => %w[es_goDeclaration Keyword],
        word('type')                         => %w[es_goDeclaration Keyword],
        word('func')                         => %w[es_goDeclaration Keyword],
        word('struct')                       => %w[es_goDeclType Keyword],
        word('interface')                    => %w[es_goDeclType Keyword],

        region('"string"')                   => %w[es_goString String],
        region('"str with escaped slash\\"') => %w[es_goString String],
        region('"str with escape\\\\n"')     => %w[es_goString String],
        region('"long string[^"]\\+$')       => %w[es_goString String],
        region('`raw string`$')              => %w[es_goRawString String],

        word('defer')                        => %w[es_goStatement Statement],
        word('go')                           => %w[es_goStatement Statement],
        word('goto')                         => %w[es_goStatement Statement],
        word('return')                       => %w[es_goStatement Statement],
        word('break')                        => %w[es_goStatement Statement],
        word('continue')                     => %w[es_goStatement Statement],
        word('fallthrough')                  => %w[es_goStatement Statement],

        region('"unterminated string')       => %w[es_goString String],
        region('`unterminated raw string')   => %w[es_goRawString String],

        word('case')                         => %w[es_goLabel Label],
        word('default')                      => %w[es_goLabel Label],

        region('// comment line')            => %w[es_goComment Comment],
        region('/\* comment block')          => %w[es_goComment Comment],
        region('/\* long comment')           => %w[es_goComment Comment],

        word('for')                          => %w[es_goRepeat Repeat],
        word('range')                        => %w[es_goRepeat Repeat]
      )
    end

    it 'keeps lines highligh untouched' do
      expect(go_code).to have_line_numbers_highlight(%w[esearchLnum LineNr])
    end
  end
end
