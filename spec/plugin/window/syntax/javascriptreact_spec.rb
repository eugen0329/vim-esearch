# frozen_string_literal: true

require 'spec_helper'
require_relative 'setup_syntax_testing_shared_context'

describe 'esearch window context syntax', :window do
  include Helpers::FileSystem
  include Helpers::WindowSyntaxContext

  describe 'javascriptreact' do
    # blank line is kept intentionally to know whether the last verified line
    # corrupts LineNr virtual UI or not

    let(:source_file_content) do
      <<~SOURCE
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
        "escaped quote\\"
        "str_with_escape\\n"
        'string'
        'str_with_escape\\n'
        'escaped quote\\'
        return
        with
        "unterminated string
        'unterminated string
        null
        undefined
        // comment line
        /* comment block */
        /* ellipsized comment #{'.' * 500}*/
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

        <es_jsxTag es_jsxAttrib="es_javaScriptString">
        <es_jsxTag es_jsxAttrib="es_javaScriptString"
        <es_jsxTag
        <

        <Es_jsxComponentName es_jsxAttrib="es_javaScriptString">
        <Es_jsxComponentName es_jsxAttrib="es_javaScriptString"
        <Es_jsxComponentName

        <es_jsxTag es_jsxAttrib=${es_jsxExpressionBlock}> {es_jsxExpressionBlock}

      SOURCE
    end
    let(:source_file) { file(source_file_content, 'main.jsx') }

    include_context 'setup syntax testing'

    # 1. Verification is done in a single example for performance reasons (as
    # vim's +clientserver is too sluggish; it doesn't affect debuggability as
    # the matcher is diffable)
    # 2. Lines that can cause matching across line end (e.g. not terminated strings
    # or comments) are not groupped and scattered across source_file to cause as
    # more potential errors as possible
    it do
      is_expected.to have_highligh_aliases(
        word('if')                          => %w[es_javaScriptConditional Conditional],
        word('else')                        => %w[es_javaScriptConditional Conditional],
        word('switch')                      => %w[es_javaScriptConditional Conditional],

        word('while')                       => %w[es_javaScriptRepeat Repeat],
        word('for')                         => %w[es_javaScriptRepeat Repeat],
        word('do')                          => %w[es_javaScriptRepeat Repeat],
        word('in')                          => %w[es_javaScriptRepeat Repeat],

        word('break')                       => %w[es_javaScriptBranch Conditional],
        word('continue')                    => %w[es_javaScriptBranch Conditional],

        word('new')                         => %w[es_javaScriptOperator Operator],
        word('delete')                      => %w[es_javaScriptOperator Operator],
        word('instanceof')                  => %w[es_javaScriptOperator Operator],
        word('typeof')                      => %w[es_javaScriptOperator Operator],

        region('"string"')                  => %w[es_javaScriptString String],
        region('"str_with_escape\\\\n"')    => %w[es_javaScriptString String],
        region('"escaped quote\\\\"')       => %w[es_javaScriptString String],

        region("'string'")                  => %w[es_javaScriptString String],
        region("'str_with_escape\\\\n'")    => %w[es_javaScriptString String],
        region("'escaped quote\\\\'")       => %w[es_javaScriptString String],

        word('return')                      => %w[es_javaScriptStatement Statement],
        word('with')                        => %w[es_javaScriptStatement Statement],

        region("'unterminated string")      => %w[es_javaScriptString String],
        region('"unterminated string')      => %w[es_javaScriptString String],

        word('null')                        => %w[es_javaScriptNull Keyword],
        word('undefined')                   => %w[es_javaScriptNull Keyword],

        region('// comment line')           => %w[es_javaScriptComment Comment],
        region('/\* comment block')         => %w[es_javaScriptComment Comment],
        region('/\* ellipsized comment')    => %w[es_javaScriptComment Comment],

        word('true')                        => %w[es_javaScriptBoolean Boolean],
        word('false')                       => %w[es_javaScriptBoolean Boolean],

        word('arguments')                   => %w[es_javaScriptIdentifier Identifier],
        word('this')                        => %w[es_javaScriptIdentifier Identifier],
        word('var')                         => %w[es_javaScriptIdentifier Identifier],
        word('let')                         => %w[es_javaScriptIdentifier Identifier],

        word('case')                        => %w[es_javaScriptLabel Label],
        word('default')                     => %w[es_javaScriptLabel Label],

        word('try')                         => %w[es_javaScriptException Exception],
        word('catch')                       => %w[es_javaScriptException Exception],
        word('finally')                     => %w[es_javaScriptException Exception],
        word('throw')                       => %w[es_javaScriptException Exception],

        word('abstract')                    => %w[es_javaScriptReserved Keyword],
        word('class')                       => %w[es_javaScriptReserved Keyword],
        word('const')                       => %w[es_javaScriptReserved Keyword],
        word('debugger')                    => %w[es_javaScriptReserved Keyword],
        word('export')                      => %w[es_javaScriptReserved Keyword],
        word('extends')                     => %w[es_javaScriptReserved Keyword],
        word('import')                      => %w[es_javaScriptReserved Keyword],

        word('function')                    => %w[es_javaScriptFunction Function],

        region('<es_jsxTag')                => %w[es_jsxTag Identifier],
        region('es_jsxAttrib')              => %w[es_jsxAttrib Type],
        region('Es_jsxComponentName')       => %w[es_jsxComponentName Function],

        region('es_jsxExpressionBlock\zs}') => %w[es_jsxBraces Special],
        region('\${\ze')                    => %w[es_jsxBraces Special]
      )
    end
  end
end
