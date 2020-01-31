# frozen_string_literal: true

require 'spec_helper'

describe 'esearch window context syntax' do
  include Helpers::FileSystem
  include Helpers::WindowSyntaxContext

  describe 'javascript' do
    let(:javascript_code) do
      <<~JAVASCRIPT_CODE
        if
        else
        switch

        while
        for
        do
        in

        break
        continue

        new
        delete
        instanceof
        typeof

        "string"
        "str_with_escape\\n"
        "long string#{'.' * 100}"

        'string'
        'str_with_escape\\n'
        'long string#{'.' * 100}'

        return
        with

        "unterminated string
        'unterminated string

        null
        undefined

        // comment line
        /* comment block */
        /* long comment #{'.' * 100}*/

        true
        false

        arguments
        this
        var
        let

        case
        default

        try
        catch
        finally
        throw

        abstract
        class
        const
        debugger
        export
        extends
        import

        function
      JAVASCRIPT_CODE
    end
    let(:main_js) { file(javascript_code, 'main.js') }
    let!(:test_directory) { directory([main_js], 'window/syntax/').persist! }

    before do
      esearch.configure!(regex: 1, backend: 'system', adapter: 'ag')
      esearch.search! '^', cwd: main_js.path.to_s
    end

    it 'contains matches' do
      is_expected.to have_highligh_aliases(
        word('if')                       => %w[javaScriptConditional Conditional],
        word('else')                     => %w[javaScriptConditional Conditional],
        word('switch')                   => %w[javaScriptConditional Conditional],

        word('while')                    => %w[javaScriptRepeat Repeat],
        word('for')                      => %w[javaScriptRepeat Repeat],
        word('do')                       => %w[javaScriptRepeat Repeat],
        word('in')                       => %w[javaScriptRepeat Repeat],

        word('break')                    => %w[javaScriptBranch Conditional],
        word('continue')                 => %w[javaScriptBranch Conditional],

        word('new')                      => %w[javaScriptOperator Operator],
        word('delete')                   => %w[javaScriptOperator Operator],
        word('instanceof')               => %w[javaScriptOperator Operator],
        word('typeof')                   => %w[javaScriptOperator Operator],

        region('"string"')               => %w[javaScriptStringD String],
        region('"str_with_escape\\\\n"') => %w[javaScriptStringD String],
        region('"long string[^"]\\+$')   => %w[javaScriptStringD String],

        region("'string'")               => %w[javaScriptStringS String],
        region("'str_with_escape\\\\n'") => %w[javaScriptStringS String],
        region("'long string[^']\\+$")   => %w[javaScriptStringS String],

        word('return')                   => %w[javaScriptStatement Statement],
        word('with')                     => %w[javaScriptStatement Statement],

        region("'unterminated string")   => %w[javaScriptStringS String],
        region('"unterminated string')   => %w[javaScriptStringD String],

        word('null')                     => %w[javaScriptNull Keyword],
        word('undefined')                => %w[javaScriptNull Keyword],

        region('// comment line')        => %w[javaScriptComment Comment],
        region('/\* comment block')      => %w[javaScriptComment Comment],
        region('/\* long comment')       => %w[javaScriptComment Comment],

        word('true')                     => %w[javaScriptBoolean Boolean],
        word('false')                    => %w[javaScriptBoolean Boolean],

        word('arguments')                => %w[javaScriptIdentifier Identifier],
        word('this')                     => %w[javaScriptIdentifier Identifier],
        word('var')                      => %w[javaScriptIdentifier Identifier],
        word('let')                      => %w[javaScriptIdentifier Identifier],

        word('case')                     => %w[javaScriptLabel Label],
        word('default')                  => %w[javaScriptLabel Label],

        word('try')                      => %w[javaScriptException Exception],
        word('catch')                    => %w[javaScriptException Exception],
        word('finally')                  => %w[javaScriptException Exception],
        word('throw')                    => %w[javaScriptException Exception],

        word('abstract')                 => %w[javaScriptReserved Keyword],
        word('class')                    => %w[javaScriptReserved Keyword],
        word('const')                    => %w[javaScriptReserved Keyword],
        word('debugger')                 => %w[javaScriptReserved Keyword],
        word('export')                   => %w[javaScriptReserved Keyword],
        word('extends')                  => %w[javaScriptReserved Keyword],
        word('import')                   => %w[javaScriptReserved Keyword],

        word('function')                 => %w[javaScriptFunction Function]
      )
    end

    it 'keeps lines highligh untouched' do
      expect(javascript_code).to have_line_numbers_highlight(%w[esearchLnum LineNr])
    end
  end
end
