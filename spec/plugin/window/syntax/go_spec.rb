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

    it 'contains matches' do
      is_expected.to have_highligh_aliases(
        word('package')                      => %w[goDirective Statement],
        word('import')                       => %w[goDirective Statement],

        word('var')                          => %w[goDeclaration Keyword],
        word('const')                        => %w[goDeclaration Keyword],
        word('type')                         => %w[goDeclaration Keyword],
        word('func')                         => %w[goDeclaration Keyword],
        word('struct')                       => %w[goDeclType Keyword],
        word('interface')                    => %w[goDeclType Keyword],

        region('"string"')                   => %w[goString String],
        region('"str with escaped slash\\"') => %w[goString String],
        region('"str with escape\\\\n"')     => %w[goString String],
        region('"long string[^"]\\+$')       => %w[goString String],
        region('`raw string`$')              => %w[goRawString String],

        word('defer')                        => %w[goStatement Statement],
        word('go')                           => %w[goStatement Statement],
        word('goto')                         => %w[goStatement Statement],
        word('return')                       => %w[goStatement Statement],
        word('break')                        => %w[goStatement Statement],
        word('continue')                     => %w[goStatement Statement],
        word('fallthrough')                  => %w[goStatement Statement],

        region('"unterminated string')       => %w[goString String],
        region('`unterminated raw string')   => %w[goRawString String],

        word('case')                         => %w[goLabel Label],
        word('default')                      => %w[goLabel Label],

        region('// comment line')            => %w[goComment Comment],
        region('/\* comment block')          => %w[goComment Comment],
        region('/\* long comment')           => %w[goComment Comment],

        word('for')                          => %w[goRepeat Repeat],
        word('range')                        => %w[goRepeat Repeat]
      )
    end

    it 'keeps lines highligh untouched' do
      expect(go_code).to have_line_numbers_highlight(%w[esearchLnum LineNr])
    end
  end
end
