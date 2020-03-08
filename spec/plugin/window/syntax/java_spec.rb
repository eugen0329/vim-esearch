# frozen_string_literal: true

require 'spec_helper'
require_relative 'setup_syntax_testing_shared_context'

describe 'esearch window context syntax', :window do
  include Helpers::FileSystem
  include Helpers::WindowSyntaxContext

  describe 'java' do
    let(:source_file_content) do
      <<~SOURCE
        if
        else
        switch
<<<<<<< c59f4f155a3b9a67589db474f3c43178bd3e049b

        while
        for
        do

        true
        false

=======
        while
        for
        do
        true
        false
>>>>>>> Minor fix
        "string"
        "escaped quote\\"
        "str with escape\\n"
        "ellipsized string#{'.' * 500}"
        null
        "unterminated string
        `unterminated raw string
        this
        super
        // comment line
        /* comment block */
        /* ellipsized comment #{'.' * 500}*/
        new
        instanceof
        return
        static
        synchronized
        transient
        volatile
        final
        strictfp
        serializable
        throw
        try
        catch
        finally
        assert
        extends
        implements
        @interface
        enum
        public
        protected
        private
        abstract

      SOURCE
    end
    let(:source_file) { file(source_file_content, 'main.java') }

    include_context 'setup syntax testing'

    # 1. Verification is done in a single example for performance reasons (as
    # vim's +clientserver is too sluggish; it doesn't affect debuggability as
    # the matcher is diffable)
    # 2. Lines that can cause matching across line end (e.g. not terminated strings
    # or comments) are not groupped and scattered across source_file to cause as
    # more potential errors as possible
    it do
      is_expected.to have_highligh_aliases(
        word('if')                           => %w[es_javaConditional Conditional],
        word('else')                         => %w[es_javaConditional Conditional],
        word('switch')                       => %w[es_javaConditional Conditional],

        word('while')                        => %w[es_javaRepeat Repeat],
        word('for')                          => %w[es_javaRepeat Repeat],
        word('do')                           => %w[es_javaRepeat Repeat],

        word('true')                         => %w[es_javaBoolean Boolean],
        word('false')                        => %w[es_javaBoolean Boolean],

        region('"string"')                   => %w[es_javaString String],
        region('"escaped quote\\\\"')        => %w[es_javaString String],
        region('"str with escape\\\\n"')     => %w[es_javaString String],
        region('"ellipsized string[^"]\\+$') => %w[es_javaString String],

        word('null')                         => %w[es_javaConstant Constant],

        region('"unterminated string')       => %w[es_javaString String],

        word('this')                         => %w[es_javaTypedef Typedef],
        word('super')                        => %w[es_javaTypedef Typedef],

        region('// comment line')            => %w[es_javaComment Comment],
        region('/\* comment block')          => %w[es_javaComment Comment],
        region('/\* ellipsized comment')     => %w[es_javaComment Comment],

        word('new')                          => %w[es_javaOperator Operator],
        word('instanceof')                   => %w[es_javaOperator Operator],

        word('return')                       => %w[es_javaStatement Statement],

        word('static')                       => %w[es_javaStorageClass StorageClass],
        word('synchronized')                 => %w[es_javaStorageClass StorageClass],
        word('transient')                    => %w[es_javaStorageClass StorageClass],
        word('volatile')                     => %w[es_javaStorageClass StorageClass],
        word('final')                        => %w[es_javaStorageClass StorageClass],
        word('strictfp')                     => %w[es_javaStorageClass StorageClass],
        word('serializable')                 => %w[es_javaStorageClass StorageClass],

        word('throw')                        => %w[es_javaExceptions Exception],
        word('try')                          => %w[es_javaExceptions Exception],
        word('catch')                        => %w[es_javaExceptions Exception],
        word('finally')                      => %w[es_javaExceptions Exception],

        word('assert')                       => %w[es_javaAssert Statement],

        word('extends')                      => %w[es_javaClassDecl StorageClass],
        word('implements')                   => %w[es_javaClassDecl StorageClass],
        region('@interface')                 => %w[es_javaClassDecl StorageClass],
        word('enum')                         => %w[es_javaClassDecl StorageClass],

        word('public')                       => %w[es_javaScopeDecl StorageClass],
        word('protected')                    => %w[es_javaScopeDecl StorageClass],
        word('private')                      => %w[es_javaScopeDecl StorageClass],
        word('abstract')                     => %w[es_javaScopeDecl StorageClass]
      )
    end
  end
end
