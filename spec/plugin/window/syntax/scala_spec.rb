# frozen_string_literal: true

require 'spec_helper'
require_relative 'setup_syntax_testing_shared_context'

describe 'esearch window context syntax', :window do
  include Helpers::FileSystem
  include Helpers::WindowSyntaxContext

  describe 'scala' do
    # blank line is kept intentionally to know whether the last verified line
    # corrupts LineNr virtual UI or not

    let(:source_file_content) do
      <<~SOURCE
        catch
        do
        else
        final
        finally
        for
        forSome
        if
        match
        return
        throw
        try
        while
        yield
        macro
        class
        trait
        object
        extends
        with
        case
        val
        def
        var
        when
        goto
        using
        startWith
        initialize
        onTransition
        stay
        become
        unbecome
        shouldBe
        abstract
        override
        final
        lazy
        implicit
        implicitly
        private
        protected
        sealed
        null
        require
        super
        this
        true
        false
        ne
        eq
        new
        package
        import


        //es_scalaTrailingComment1
        // es_scalaTrailingComment2
        /*es_scalaMultilineComment1*/
        /* es_scalaMultilineComment2 */
        /*es_scalaMultilineComment3
        /* es_scalaMultilineComment4

        "es_scalaString1"
        "es_scalaString2\\"
        "es_scalaString3

        {{{es_scalaCommentCodeBlock1}}}
        {{{ es_scalaCommentCodeBlock2 }}}
        {{{es_scalaCommentCodeBlock3
        {{{ es_scalaCommentCodeBlock4

        <-
        ->

        new es_scalaInstanceDeclaration

        class es_scalaInstanceDeclaration
        trait es_scalaInstanceDeclaration
        object es_scalaInstanceDeclaration
        extends es_scalaInstanceDeclaration
        with es_scalaInstanceDeclaration

        def es_scalaNameDefinition
        var es_scalaNameDefinition

        type es_scalaTypeDeclaration

        def rep(f: es_scalaTypeDeclaration1 => es_scalaTypeDeclaration2): es_scalaTypeDeclaration = {

        EsScalaCapitalWord

      SOURCE
    end
    let(:source_file) { file(source_file_content, 'main.scala') }

    include_context 'setup syntax testing'

    # 1. Verification is done in a single example for performance reasons (as
    # vim's +clientserver is too sluggish; it doesn't affect debuggability as
    # the matcher is diffable)
    # 2. Lines that can cause matching across line end (e.g. not terminated strings
    # or comments) are not groupped and scattered across source_file to cause as
    # more potential errors as possible
    it do
      is_expected.to have_highligh_aliases(
        word('catch')                                 => %w[es_scalaKeyword Keyword],
        word('do')                                    => %w[es_scalaKeyword Keyword],
        word('else')                                  => %w[es_scalaKeyword Keyword],
        word('final')                                 => %w[es_scalaKeyword Keyword],
        word('finally')                               => %w[es_scalaKeyword Keyword],
        word('for')                                   => %w[es_scalaKeyword Keyword],
        word('forSome')                               => %w[es_scalaKeyword Keyword],
        word('if')                                    => %w[es_scalaKeyword Keyword],
        word('match')                                 => %w[es_scalaKeyword Keyword],
        word('return')                                => %w[es_scalaKeyword Keyword],
        word('throw')                                 => %w[es_scalaKeyword Keyword],
        word('try')                                   => %w[es_scalaKeyword Keyword],
        word('while')                                 => %w[es_scalaKeyword Keyword],
        word('yield')                                 => %w[es_scalaKeyword Keyword],
        word('macro')                                 => %w[es_scalaKeyword Keyword],
        word('class')                                 => %w[es_scalaKeyword Keyword],
        word('trait')                                 => %w[es_scalaKeyword Keyword],
        word('object')                                => %w[es_scalaKeyword Keyword],
        word('extends')                               => %w[es_scalaKeyword Keyword],
        word('with')                                  => %w[es_scalaKeyword Keyword],
        word('case')                                  => %w[es_scalaKeyword Keyword],
        word('val')                                   => %w[es_scalaKeyword Keyword],
        word('def')                                   => %w[es_scalaKeyword Keyword],
        word('var')                                   => %w[es_scalaKeyword Keyword],
        word('when')                                  => %w[es_scalaSpecial PreProc],
        word('goto')                                  => %w[es_scalaSpecial PreProc],
        word('using')                                 => %w[es_scalaSpecial PreProc],
        word('startWith')                             => %w[es_scalaSpecial PreProc],
        word('initialize')                            => %w[es_scalaSpecial PreProc],
        word('onTransition')                          => %w[es_scalaSpecial PreProc],
        word('stay')                                  => %w[es_scalaSpecial PreProc],
        word('become')                                => %w[es_scalaSpecial PreProc],
        word('unbecome')                              => %w[es_scalaSpecial PreProc],
        word('shouldBe')                              => %w[es_scalaSpecial PreProc],
        word('abstract')                              => %w[es_scalaKeywordModifier Function],
        word('override')                              => %w[es_scalaKeywordModifier Function],
        word('final')                                 => %w[es_scalaKeywordModifier Function],
        word('lazy')                                  => %w[es_scalaKeywordModifier Function],
        word('implicit')                              => %w[es_scalaKeywordModifier Function],
        word('implicitly')                            => %w[es_scalaKeywordModifier Function],
        word('private')                               => %w[es_scalaKeywordModifier Function],
        word('protected')                             => %w[es_scalaKeywordModifier Function],
        word('sealed')                                => %w[es_scalaKeywordModifier Function],
        word('null')                                  => %w[es_scalaKeywordModifier Function],
        word('require')                               => %w[es_scalaKeywordModifier Function],
        word('super')                                 => %w[es_scalaKeywordModifier Function],
        word('this')                                  => %w[es_scalaSpecial PreProc],
        word('true')                                  => %w[es_scalaSpecial PreProc],
        word('false')                                 => %w[es_scalaSpecial PreProc],
        word('ne')                                    => %w[es_scalaSpecial PreProc],
        word('eq')                                    => %w[es_scalaSpecial PreProc],
        word('new')                                   => %w[es_scalaSpecial PreProc],
        word('package')                               => %w[es_scalaExternal Include],
        word('import')                                => %w[es_scalaExternal Include],
        region('//es_scalaTrailingComment1')          => %w[es_scalaTrailingComment Comment],
        region('// es_scalaTrailingComment2')         => %w[es_scalaTrailingComment Comment],
        region('/\\*es_scalaMultilineComment1\\*/')   => %w[es_scalaMultilineComment Comment],
        region('/\\* es_scalaMultilineComment2 \\*/') => %w[es_scalaMultilineComment Comment],
        region('/\\*es_scalaMultilineComment3')       => %w[es_scalaMultilineComment Comment],
        region('/\\* es_scalaMultilineComment4')      => %w[es_scalaMultilineComment Comment],
        region('"es_scalaString1"')                   => %w[es_scalaString String],
        region('"es_scalaString2\\\\"')               => %w[es_scalaString String],
        region('"es_scalaString3')                    => %w[es_scalaString String],
        region('{{{es_scalaCommentCodeBlock1}}}')     => %w[es_scalaCommentCodeBlock String],
        region('{{{ es_scalaCommentCodeBlock2 }}}')   => %w[es_scalaCommentCodeBlock String],
        region('{{{es_scalaCommentCodeBlock3')        => %w[es_scalaCommentCodeBlock String],
        region('{{{ es_scalaCommentCodeBlock4')       => %w[es_scalaCommentCodeBlock String],
        region('<-')                                  => %w[es_scalaSpecial PreProc],
        region('->')                                  => %w[es_scalaSpecial PreProc],
        region('es_scalaInstanceDeclaration')         => %w[es_scalaInstanceDeclaration Special],
        region('es_scalaNameDefinition')              => %w[es_scalaNameDefinition Function],
        region('EsScalaCapitalWord')                  => %w[es_scalaCapitalWord Special],
        region('es_scalaTypeDeclaration1')            => %w[es_scalaTypeDeclaration Type],
        region('es_scalaTypeDeclaration2')            => %w[es_scalaTypeDeclaration2 Type]
      )
    end
  end
end
