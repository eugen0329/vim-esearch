# frozen_string_literal: true

require 'spec_helper'
require_relative 'setup_syntax_testing_shared_context'

describe 'esearch window context syntax', :window do
  include Helpers::FileSystem
  include Helpers::WindowSyntaxContext

  describe 'generic' do
    # blank line is kept intentionally to know whether the last verified line
    # corrupts LineNr virtual UI or not

    let(:source_file_content) do
      <<~SOURCE
      null
      nil
      none
      NULL
      NIL
      NONE
      Null
      Nil
      None
      true
      false
      TRUE
      FALSE
      True
      False
      if
      unless
      else
      elseif
      case
      switch
      select
      when
      default
      throw
      raise
      try
      catch
      rescue
      finally
      ensure
      while
      until
      for
      foreach
      do
      public
      protected
      private
      abstract
      global
      shared
      include
      import
      use
      require
      package
      native
      new
      delete
      as
      in
      break
      next
      continue
      return
      goto
      begin
      end
      func
      function
      fn
      def
      this
      self
      super
      yield
      implements
      extends
      implement
      extend
      const
      mutable
      var
      let
      static
      register
      volatile
      struct
      class
      export
      union
      enum
      interface
      typedef
      Constant
      Boolean
      Conditional
      Exception
      Repeat
      StorageClass
      Include
      Operator
      Statement
      Keyword
      StorageClass
      Structure
      Comment
      String


      func es_genericFunction1
      function es_genericFunction2
      fn es_genericFunction3
      def es_genericFunction4


      //es_genericComment1
      // es_genericComment2
      #es_genericComment3
      # es_genericComment4
      /*es_genericComment1*/
      /* es_genericComment2 */
      /*es_genericComment3
      /* es_genericComment4

      "es_genericString"
      "es_genericString\\"
      "es_genericString
      'es_genericString'
      'es_genericString\\'
      'es_genericString

      SOURCE
    end
    let(:source_file) { file(source_file_content, 'main.rs') }

    include_context 'setup syntax testing'

    # 1. Verification is done in a single example for performance reasons (as
    # vim's +clientserver is too sluggish; it doesn't affect debuggability as
    # the matcher is diffable)
    # 2. Lines that can cause matching across line end (e.g. not terminated strings
    # or comments) are not groupped and scattered across source_file to cause as
    # more potential errors as possible
    it do
      is_expected.to have_highligh_aliases(
        word('null')                         => %w[es_genericConstant Constant],
        word('nil')                          => %w[es_genericConstant Constant],
        word('none')                         => %w[es_genericConstant Constant],
        word('NULL')                         => %w[es_genericConstant Constant],
        word('NIL')                          => %w[es_genericConstant Constant],
        word('NONE')                         => %w[es_genericConstant Constant],
        word('Null')                         => %w[es_genericConstant Constant],
        word('Nil')                          => %w[es_genericConstant Constant],
        word('None')                         => %w[es_genericConstant Constant],
        word('true')                         => %w[es_genericBoolean Boolean],
        word('false')                        => %w[es_genericBoolean Boolean],
        word('TRUE')                         => %w[es_genericBoolean Boolean],
        word('FALSE')                        => %w[es_genericBoolean Boolean],
        word('True')                         => %w[es_genericBoolean Boolean],
        word('False')                        => %w[es_genericBoolean Boolean],
        word('if')                           => %w[es_genericConditional Conditional],
        word('unless')                       => %w[es_genericConditional Conditional],
        word('else')                         => %w[es_genericConditional Conditional],
        word('elseif')                       => %w[es_genericConditional Conditional],
        word('case')                         => %w[es_genericConditional Conditional],
        word('switch')                       => %w[es_genericConditional Conditional],
        word('select')                       => %w[es_genericConditional Conditional],
        word('when')                         => %w[es_genericConditional Conditional],
        word('default')                      => %w[es_genericConditional Conditional],
        word('throw')                        => %w[es_genericException Exception],
        word('raise')                        => %w[es_genericException Exception],
        word('try')                          => %w[es_genericException Exception],
        word('catch')                        => %w[es_genericException Exception],
        word('rescue')                       => %w[es_genericException Exception],
        word('finally')                      => %w[es_genericException Exception],
        word('ensure')                       => %w[es_genericException Exception],
        word('while')                        => %w[es_genericRepeat Repeat],
        word('until')                        => %w[es_genericRepeat Repeat],
        word('for')                          => %w[es_genericRepeat Repeat],
        word('foreach')                      => %w[es_genericRepeat Repeat],
        word('do')                           => %w[es_genericRepeat Repeat],
        word('public')                       => %w[es_genericScopeDecl StorageClass],
        word('protected')                    => %w[es_genericScopeDecl StorageClass],
        word('private')                      => %w[es_genericScopeDecl StorageClass],
        word('abstract')                     => %w[es_genericScopeDecl StorageClass],
        word('global')                       => %w[es_genericScopeDecl StorageClass],
        word('shared')                       => %w[es_genericScopeDecl StorageClass],
        word('include')                      => %w[es_genericInclude Include],
        word('import')                       => %w[es_genericInclude Include],
        word('use')                          => %w[es_genericInclude Include],
        word('require')                      => %w[es_genericInclude Include],
        word('package')                      => %w[es_genericInclude Include],
        word('native')                       => %w[es_genericInclude Include],
        word('new')                          => %w[es_genericOperator Operator],
        word('delete')                       => %w[es_genericOperator Operator],
        word('as')                           => %w[es_genericOperator Operator],
        word('in')                           => %w[es_genericOperator Operator],
        word('break')                        => %w[es_genericStatement Statement],
        word('next')                         => %w[es_genericStatement Statement],
        word('continue')                     => %w[es_genericStatement Statement],
        word('return')                       => %w[es_genericStatement Statement],
        word('goto')                         => %w[es_genericStatement Statement],
        word('begin')                        => %w[es_genericStatement Statement],
        word('end')                          => %w[es_genericStatement Statement],
        word('var')                          => %w[es_genericKeyword Keyword],
        word('let')                          => %w[es_genericKeyword Keyword],
        word('this')                         => %w[es_genericKeyword Keyword],
        word('self')                         => %w[es_genericKeyword Keyword],
        word('super')                        => %w[es_genericKeyword Keyword],
        word('yield')                        => %w[es_genericKeyword Keyword],
        word('implement\>')                  => %w[es_genericKeyword Keyword],
        word('extend\>')                     => %w[es_genericKeyword Keyword],
        word('implements')                   => %w[es_genericKeyword Keyword],
        word('extends')                      => %w[es_genericKeyword Keyword],
        word('func')                         => %w[es_genericKeyword Keyword],
        word('es_genericFunction1')                         => %w[es_genericFunction Function],
        word('es_genericFunction2')                         => %w[es_genericFunction Function],
        word('es_genericFunction3')                         => %w[es_genericFunction Function],
        word('es_genericFunction4')                         => %w[es_genericFunction Function],
        word('function')                     => %w[es_genericKeyword Keyword],
        word('fn')                           => %w[es_genericKeyword Keyword],
        word('def')                          => %w[es_genericKeyword Keyword],
        word('const')                        => %w[es_genericStorageClass StorageClass],
        word('mutable')                      => %w[es_genericStorageClass StorageClass],
        word('static')                       => %w[es_genericStorageClass StorageClass],
        word('register')                     => %w[es_genericStorageClass StorageClass],
        word('volatile')                     => %w[es_genericStorageClass StorageClass],
        word('struct')                       => %w[es_genericStructure Structure],
        word('class')                        => %w[es_genericStructure Structure],
        word('export')                       => %w[es_genericStructure Structure],
        word('union')                        => %w[es_genericStructure Structure],
        word('enum')                         => %w[es_genericStructure Structure],
        word('interface')                    => %w[es_genericStructure Structure],
        word('typedef')                      => %w[es_genericStructure Structure],

        region('"es_genericString"')           => %w[es_genericString String],
        region('"es_genericString\\\\"')       => %w[es_genericString String],
        region('"es_genericString')            => %w[es_genericString String],
        region("'es_genericString'")           => %w[es_genericString String],
        region("'es_genericString\\\\'")       => %w[es_genericString String],
        region("'es_genericString")            => %w[es_genericString String],

        region('//es_genericComment1')     => %w[es_genericComment Comment],
        region('// es_genericComment2')    => %w[es_genericComment Comment],
        region('#es_genericComment3')     => %w[es_genericComment Comment],
        region('# es_genericComment4')    => %w[es_genericComment Comment],
        region('/\\*es_genericComment1\\*/')   => %w[es_genericComment Comment],
        region('/\\* es_genericComment2 \\*/') => %w[es_genericComment Comment],
        region('/\\*es_genericComment3')       => %w[es_genericComment Comment],
        region('/\\* es_genericComment4')      => %w[es_genericComment Comment]
      )
    end
  end
end
