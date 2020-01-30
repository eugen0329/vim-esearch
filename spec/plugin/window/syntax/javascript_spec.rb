# frozen_string_literal: true

require 'spec_helper'

describe 'esearch window context syntax' do
  include Helpers::FileSystem
  include Helpers::Syntax

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
        "str with escape\\n"
        "long string#{'.' * 100}"

        'string'
        'str with escape\\n'
        'long string#{'.' * 100}'

        return
        with

        // comment line
        /* comment block */
        /* long comment #{'.' * 100}*/

        null
        undefined

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
      is_expected.to have_highlights(
        'if':                     %w[javaScriptConditional Conditional],
        'else':                   %w[javaScriptConditional Conditional],
        'switch':                 %w[javaScriptConditional Conditional],

        'while':                  %w[javaScriptRepeat Repeat],
        'for':                    %w[javaScriptRepeat Repeat],
        'do':                     %w[javaScriptRepeat Repeat],
        'in':                     %w[javaScriptRepeat Repeat],

        'break':                  %w[javaScriptBranch Conditional],
        'continue':               %w[javaScriptBranch Conditional],

        'new':                    %w[javaScriptOperator Operator],
        'delete':                 %w[javaScriptOperator Operator],
        'instanceof':             %w[javaScriptOperator Operator],
        'typeof':                 %w[javaScriptOperator Operator],

        '"string"':               %w[javaScriptStringD String],
        '"str with escape\\\\n"': %w[javaScriptStringD String],
        '"long string[^"]\\+$':   %w[javaScriptStringD String],

        "'string'":               %w[javaScriptStringS String],
        "'str with escape\\\\n'": %w[javaScriptStringS String],
        "'long string[^']\\+$":   %w[javaScriptStringS String],

        'return':                 %w[javaScriptStatement Statement],
        'with':                   %w[javaScriptStatement Statement],

        '// comment line':        %w[javaScriptComment Comment],
        '/\* comment block':      %w[javaScriptComment Comment],
        '/\* long comment':       %w[javaScriptComment Comment],

        'null':                   %w[javaScriptNull Keyword],
        'undefined':              %w[javaScriptNull Keyword],

        'true':                   %w[javaScriptBoolean Boolean],
        'false':                  %w[javaScriptBoolean Boolean],

        'arguments':              %w[javaScriptIdentifier Identifier],
        'this':                   %w[javaScriptIdentifier Identifier],
        'var':                    %w[javaScriptIdentifier Identifier],
        '\<let':                  %w[javaScriptIdentifier Identifier],

        'case':                   %w[javaScriptLabel Label],
        'default':                %w[javaScriptLabel Label],

        'try':                    %w[javaScriptException Exception],
        'catch':                  %w[javaScriptException Exception],
        'finally':                %w[javaScriptException Exception],
        'throw':                  %w[javaScriptException Exception],

        'abstract':               %w[javaScriptReserved Keyword],
        'class':                  %w[javaScriptReserved Keyword],
        'const':                  %w[javaScriptReserved Keyword],
        'debugger':               %w[javaScriptReserved Keyword],
        'export':                 %w[javaScriptReserved Keyword],
        'extends':                %w[javaScriptReserved Keyword],
        'import':                 %w[javaScriptReserved Keyword],

        'function':               %w[javaScriptFunction Function]
      )
    end

    it 'keeps lines highligh untouched' do
      expect(javascript_code).to have_line_numbers_highlight(%w[esearchLnum LineNr])
    end
  end
end
