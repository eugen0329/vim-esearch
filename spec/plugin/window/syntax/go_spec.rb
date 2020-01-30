
describe 'esearch window context syntax', :backend do
  include Helpers::FileSystem
  include Helpers::Syntax

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

        // comment line
        /* comment block */
        /* long comment #{'.' * 100}*/

        defer
        go
        goto
        return
        break
        continue
        fallthrough

        case
        default

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
      is_expected.to have_highlights({
        'package': %w[goDirective   Statement],
        'import':  %w[goDirective   Statement],

        'var':     %w[goDeclaration Keyword],
        'const':   %w[goDeclaration Keyword],
        'type':    %w[goDeclaration Keyword],
        'func':    %w[goDeclaration Keyword],
        'struct':     %w[goDeclType          Keyword],
        'interface':  %w[goDeclType          Keyword],

        '"string"':                %w[goString    String],
        '"str with escaped slash\\"': %w[goString    String],
        '"str with escape\\\\n"':     %w[goString    String],
        '"long string[^"]\+$':     %w[goString    String],
        '`raw string`$':     %w[goRawString String],

        '// comment line':         %w[goComment Comment],
        '/\* comment block':       %w[goComment Comment],
        '/\* long comment':        %w[goComment Comment],

        'defer':       %w[goStatement         Statement],
        'go':          %w[goStatement         Statement],
        'goto':        %w[goStatement         Statement],
        'return':      %w[goStatement         Statement],
        'break':       %w[goStatement         Statement],
        'continue':    %w[goStatement         Statement],
        'fallthrough': %w[goStatement         Statement],

        'case':    %w[goLabel             Label],
        'default': %w[goLabel             Label],

        'for':    %w[ goRepeat            Repeat],
        'range':  %w[ goRepeat            Repeat],
      })
    end

    it "keeps lines highligh untouched" do
      expect(go_code).to have_line_numbers_highlight(["esearchLnum", "LineNr"])
    end
  end
end
