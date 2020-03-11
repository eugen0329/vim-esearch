# frozen_string_literal: true

require 'spec_helper'
require_relative 'setup_syntax_testing_shared_context'

describe 'esearch window context syntax', :window do
  include Helpers::FileSystem
  include Helpers::WindowSyntaxContext

  describe 'typescriptreact' do
    # blank line is kept intentionally to know whether the last verified line
    # corrupts LineNr virtual UI or not

    let(:source_file_content) do
      <<~SOURCE
        from
        as
        import
        export
        namespace
        module
        prototype
        as
        arguments
        this
        super
        in
        instanceof
        delete
        new
        typeof
        void
        in
        of
        true
        false
        null
        undefined
        alert
        confirm
        prompt
        status
        self
        top
        parent
        if
        else
        switch
        do
        while
        for
        break
        continue
        case
        default
        with
        yield
        return
        try
        catch
        throw
        keyof
        finally
        debugger
        await
        declare
        extends
        implements
        interface
        abstract
        class
        enum foo {}
        type
        global
        process
        console
        Buffer
        module
        exports
        setTimeout
        clearTimeout
        setInterval
        clearInterval

        const
        let
        var
        const name
        let   name
        var   name

        type es_typescriptAliasDeclaration

        function es_typescriptFuncName() {}
        class Klass {
          es_typescriptFuncName() {}
        }

        //es_typescriptLineComment1
        // es_typescriptLineComment2
        /*es_typescriptComment1*/
        /* es_typescriptComment2 */
        /*es_typescriptComment3
        /* es_typescriptComment4

        "es_typescriptString"
        "es_typescriptString\\"
        "es_typescriptString
        'es_typescriptString'
        'es_typescriptString\\'
        'es_typescriptString


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
    let(:source_file) { file(source_file_content, 'main.tsx') }

    include_context 'setup syntax testing'

    # 1. Verification is done in a single example for performance reasons (as
    # vim's +clientserver is too sluggish; it doesn't affect debuggability as
    # the matcher is diffable)
    # 2. Lines that can cause matching across line end (e.g. not terminated strings
    # or comments) are not groupped and scattered across source_file to cause as
    # more potential errors as possible
    it do
      is_expected.to have_highligh_aliases(
        word('from')                              => %w[es_typescriptImport Special],
        word('as')                                => %w[es_typescriptImport Special],
        word('import')                            => %w[es_typescriptImport Special],
        word('export')                            => %w[es_typescriptExport Special],
        word('namespace')                         => %w[es_typescriptModule Special],
        word('module')                            => %w[es_typescriptModule Special],
        word('prototype')                         => %w[es_typescriptPrototype Type],
        word('as')                                => %w[es_typescriptCastKeyword Special],
        word('arguments')                         => %w[es_typescriptIdentifier Structure],
        word('this')                              => %w[es_typescriptIdentifier Structure],
        word('super')                             => %w[es_typescriptIdentifier Structure],
        word('in')                                => %w[es_typescriptKeywordOp Identifier],
        word('instanceof')                        => %w[es_typescriptKeywordOp Identifier],
        word('delete')                            => %w[es_typescriptOperator Identifier],
        word('new')                               => %w[es_typescriptOperator Identifier],
        word('typeof')                            => %w[es_typescriptOperator Identifier],
        word('void')                              => %w[es_typescriptOperator Identifier],
        word('in')                                => %w[es_typescriptForOperator Repeat],
        word('of')                                => %w[es_typescriptForOperator Repeat],
        word('true')                              => %w[es_typescriptBoolean Boolean],
        word('false')                             => %w[es_typescriptBoolean Boolean],
        word('null')                              => %w[es_typescriptNull Boolean],
        word('undefined')                         => %w[es_typescriptNull Boolean],
        word('alert')                             => %w[es_typescriptKeyword Keyword],
        word('confirm')                           => %w[es_typescriptKeyword Keyword],
        word('prompt')                            => %w[es_typescriptKeyword Keyword],
        word('status')                            => %w[es_typescriptKeyword Keyword],
        word('if')                                => %w[es_typescriptConditional Conditional],
        word('else')                              => %w[es_typescriptConditional Conditional],
        word('switch')                            => %w[es_typescriptConditional Conditional],
        word('do')                                => %w[es_typescriptRepeat Repeat],
        word('while')                             => %w[es_typescriptRepeat Repeat],
        word('for')                               => %w[es_typescriptRepeat Repeat],
        word('break')                             => %w[es_typescriptConditional Conditional],
        word('continue')                          => %w[es_typescriptConditional Conditional],
        word('case')                              => %w[es_typescriptConditional Conditional],
        word('default')                           => %w[es_typescriptConditional Conditional],
        word('with')                              => %w[es_typescriptStatementKeyword Statement],
        word('yield')                             => %w[es_typescriptStatementKeyword Statement],
        word('return')                            => %w[es_typescriptStatementKeyword Statement],
        word('try')                               => %w[es_typescriptTry Special],
        word('catch')                             => %w[es_typescriptExceptions Special],
        word('throw')                             => %w[es_typescriptExceptions Special],
        word('finally')                           => %w[es_typescriptExceptions Special],
        word('debugger')                          => %w[es_typescriptDebugger cleared],
        word('await')                             => %w[es_typescriptKeyword Keyword],
        word('declare')                           => %w[es_typescriptAmbientDeclaration Special],
        word('extends')                           => %w[es_typescriptKeyword Keyword],
        word('implements')                        => %w[es_typescriptKeyword Keyword],
        word('interface')                         => %w[es_typescriptKeyword Keyword],
        word('abstract')                          => %w[es_typescriptAbstract Special],
        word('class')                             => %w[es_typescriptKeyword Keyword],
        word('function')                          => %w[es_typescriptKeyword Keyword],
        word('es_typescriptFuncName')             => %w[es_typescriptFuncName Function],
        word('es_typescriptAliasDeclaration')     => %w[es_typescriptAliasDeclaration Identifier],
        word('keyof')                             => %w[es_typescriptKeyword Keyword],

        word('self')                              => %w[es_typescriptGlobal Constant],
        word('top')                               => %w[es_typescriptGlobal Constant],
        word('parent')                            => %w[es_typescriptGlobal Constant],
        word('global')                            => %w[es_typescriptGlobal Constant],
        word('process')                           => %w[es_typescriptGlobal Constant],
        word('console')                           => %w[es_typescriptGlobal Constant],
        word('Buffer')                            => %w[es_typescriptGlobal Constant],
        word('module')                            => %w[es_typescriptGlobal Constant],
        word('exports')                           => %w[es_typescriptGlobal Constant],
        word('setTimeout')                        => %w[es_typescriptGlobal Constant],
        word('clearTimeout')                      => %w[es_typescriptGlobal Constant],
        word('setInterval')                       => %w[es_typescriptGlobal Constant],
        word('clearInterval')                     => %w[es_typescriptGlobal Constant],

        word('type')                              => %w[es_typescriptAliasKeyword Keyword],
        word('enum')                              => %w[es_typescriptEnumKeyword Identifier],
        word('let')                               => %w[es_typescriptVariable Identifier],
        word('var')                               => %w[es_typescriptVariable Identifier],

        region('"es_typescriptString"')           => %w[es_typescriptString String],
        region('"es_typescriptString\\\\"')       => %w[es_typescriptString String],
        region('"es_typescriptString')            => %w[es_typescriptString String],
        region("'es_typescriptString'")           => %w[es_typescriptString String],
        region("'es_typescriptString\\\\'")       => %w[es_typescriptString String],
        region("'es_typescriptString")            => %w[es_typescriptString String],

        region('//es_typescriptLineComment1')     => %w[es_typescriptLineComment Comment],
        region('// es_typescriptLineComment2')    => %w[es_typescriptLineComment Comment],

        region('/\\*es_typescriptComment1\\*/')   => %w[es_typescriptComment Comment],
        region('/\\* es_typescriptComment2 \\*/') => %w[es_typescriptComment Comment],
        region('/\\*es_typescriptComment3')       => %w[es_typescriptComment Comment],
        region('/\\* es_typescriptComment4')      => %w[es_typescriptComment Comment],

        region('<es_jsxTag')                      => %w[es_jsxTag Identifier],
        region('es_jsxAttrib')                    => %w[es_jsxAttrib Type],
        region('Es_jsxComponentName')             => %w[es_jsxComponentName Function],

        region('es_jsxExpressionBlock\zs}')       => %w[es_jsxBraces Special],
        region('\${\ze')                          => %w[es_jsxBraces Special]
      )
    end
  end
end
