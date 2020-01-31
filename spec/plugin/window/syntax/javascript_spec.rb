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
    let(:source_file) { file(javascript_code, 'main.js') }
    let!(:test_directory) { directory([source_file], 'window/syntax/').persist! }

    before do
      esearch.configure!(regex: 1, backend: 'system', adapter: 'ag')
      esearch.search! '^', cwd: source_file.path.to_s
    end

    it do
      is_expected.to have_highligh_aliases(
        word('if')                       => %w[es_javaScriptConditional Conditional],
        word('else')                     => %w[es_javaScriptConditional Conditional],
        word('switch')                   => %w[es_javaScriptConditional Conditional],

        word('while')                    => %w[es_javaScriptRepeat Repeat],
        word('for')                      => %w[es_javaScriptRepeat Repeat],
        word('do')                       => %w[es_javaScriptRepeat Repeat],
        word('in')                       => %w[es_javaScriptRepeat Repeat],

        word('break')                    => %w[es_javaScriptBranch Conditional],
        word('continue')                 => %w[es_javaScriptBranch Conditional],

        word('new')                      => %w[es_javaScriptOperator Operator],
        word('delete')                   => %w[es_javaScriptOperator Operator],
        word('instanceof')               => %w[es_javaScriptOperator Operator],
        word('typeof')                   => %w[es_javaScriptOperator Operator],

        region('"string"')               => %w[es_javaScriptStringD String],
        region('"str_with_escape\\\\n"') => %w[es_javaScriptStringD String],
        region('"long string[^"]\\+$')   => %w[es_javaScriptStringD String],

        region("'string'")               => %w[es_javaScriptStringS String],
        region("'str_with_escape\\\\n'") => %w[es_javaScriptStringS String],
        region("'long string[^']\\+$")   => %w[es_javaScriptStringS String],

        word('return')                   => %w[es_javaScriptStatement Statement],
        word('with')                     => %w[es_javaScriptStatement Statement],

        region("'unterminated string")   => %w[es_javaScriptStringS String],
        region('"unterminated string')   => %w[es_javaScriptStringD String],

        word('null')                     => %w[es_javaScriptNull Keyword],
        word('undefined')                => %w[es_javaScriptNull Keyword],

        region('// comment line')        => %w[es_javaScriptComment Comment],
        region('/\* comment block')      => %w[es_javaScriptComment Comment],
        region('/\* long comment')       => %w[es_javaScriptComment Comment],

        word('true')                     => %w[es_javaScriptBoolean Boolean],
        word('false')                    => %w[es_javaScriptBoolean Boolean],

        word('arguments')                => %w[es_javaScriptIdentifier Identifier],
        word('this')                     => %w[es_javaScriptIdentifier Identifier],
        word('var')                      => %w[es_javaScriptIdentifier Identifier],
        word('let')                      => %w[es_javaScriptIdentifier Identifier],

        word('case')                     => %w[es_javaScriptLabel Label],
        word('default')                  => %w[es_javaScriptLabel Label],

        word('try')                      => %w[es_javaScriptException Exception],
        word('catch')                    => %w[es_javaScriptException Exception],
        word('finally')                  => %w[es_javaScriptException Exception],
        word('throw')                    => %w[es_javaScriptException Exception],

        word('abstract')                 => %w[es_javaScriptReserved Keyword],
        word('class')                    => %w[es_javaScriptReserved Keyword],
        word('const')                    => %w[es_javaScriptReserved Keyword],
        word('debugger')                 => %w[es_javaScriptReserved Keyword],
        word('export')                   => %w[es_javaScriptReserved Keyword],
        word('extends')                  => %w[es_javaScriptReserved Keyword],
        word('import')                   => %w[es_javaScriptReserved Keyword],

        word('function')                 => %w[es_javaScriptFunction Function]
      )
    end

    it 'keeps lines highligh untouched' do
      expect(javascript_code).to have_line_numbers_highlight(%w[esearchLnum LineNr])
    end
  end
end
