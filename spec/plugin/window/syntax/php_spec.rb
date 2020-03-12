# frozen_string_literal: true

require 'spec_helper'
require_relative 'setup_syntax_testing_shared_context'

describe 'esearch window context syntax', :window do
  include Helpers::FileSystem
  include Helpers::WindowSyntaxContext

  describe 'php' do
    let(:source_file_content) do
      <<~SOURCE
        declare
        else
        enddeclare
        endswitch
        elseif
        endif
        if
        switch

        as
        do
        endfor
        endforeach
        endwhile
        for
        foreach
        while

        case
        default
        switch

        "string"
        "escaped quote\\"
        "str with escape\\n"
        "missing quote

        $identifier

        'string'
        'escaped quote\\'
        'str with escape\\n'
        'missing quote

        return
        break
        continue
        exit
        goto
        yield

        // comment line
        /* comment block */
        /* ellipsized comment #{'.' * 500}*/
        // terminated with ?>

        var
        const

        # comment
        #comment
        # ellipsized comment #{'.' * 500}*/
        # terminated with ?>

        namespace
        extends
        implements
        instanceof
        parent
        self

        __LINE__
        __FILE__
        __FUNCTION__
        __METHOD__
        __CLASS__
        __DIR__
        __NAMESPACE__
        __TRAIT__
      SOURCE
    end
    let(:source_file) { file(source_file_content, 'main.php') }

    include_context 'setup syntax testing'

    # 1. Verification is done in a single example for performance reasons (as
    # vim's +clientserver is too sluggish; it doesn't affect debuggability as
    # the matcher is diffable)
    # 2. Lines that can cause matching across line end (e.g. not terminated strings
    # or comments) are not groupped and scattered across source_file to cause as
    # more potential errors as possible
    it do
      is_expected.to have_highligh_aliases(
        word('declare')                           => %w[es_phpConditional Conditional],
        word('else')                              => %w[es_phpConditional Conditional],
        word('enddeclare')                        => %w[es_phpConditional Conditional],
        word('endswitch')                         => %w[es_phpConditional Conditional],
        word('elseif')                            => %w[es_phpConditional Conditional],
        word('endif')                             => %w[es_phpConditional Conditional],
        word('if')                                => %w[es_phpConditional Conditional],
        word('switch')                            => %w[es_phpConditional Conditional],

        word('as')                                => %w[es_phpRepeat Repeat],
        word('do')                                => %w[es_phpRepeat Repeat],
        word('endfor')                            => %w[es_phpRepeat Repeat],
        word('endforeach')                        => %w[es_phpRepeat Repeat],
        word('endwhile')                          => %w[es_phpRepeat Repeat],
        word('for')                               => %w[es_phpRepeat Repeat],
        word('foreach')                           => %w[es_phpRepeat Repeat],
        word('while')                             => %w[es_phpRepeat Repeat],

        word('case')                              => %w[es_phpLabel Label],
        word('default')                           => %w[es_phpLabel Label],
        word('switch')                            => %w[es_phpLabel Label],

        region('"string"')                        => %w[es_phpStringDouble String],
        region('"escaped quote\\\\"')             => %w[es_phpStringDouble String],
        region('"str with escape\\\\n"')          => %w[es_phpStringDouble String],
        region('"missing quote')                  => %w[es_phpStringDouble String],

        region('$identifier')                     => %w[es_phpIdentifier Identifier],

        region("'string'")                        => %w[es_phpStringSingle String],
        region("'escaped quote\\\\'")             => %w[es_phpStringSingle String],
        region("'str with escape\\\\n'")          => %w[es_phpStringSingle String],
        region("'missing quote")                  => %w[es_phpStringSingle String],

        word('return')                            => %w[es_phpStatement Statement],
        word('break')                             => %w[es_phpStatement Statement],
        word('continue')                          => %w[es_phpStatement Statement],
        word('exit')                              => %w[es_phpStatement Statement],
        word('goto')                              => %w[es_phpStatement Statement],
        word('yield')                             => %w[es_phpStatement Statement],

        region('// comment line')                 => %w[es_phpComment Comment],
        region('/\* comment block')               => %w[es_phpComment Comment],
        region('/\* ellipsized comment')          => %w[es_phpComment Comment],
        region('// terminated with ?>', at: ..-3) => %w[es_phpComment Comment],

        word('var')                               => %w[es_phpKeyword Statement],
        word('const')                             => %w[es_phpKeyword Statement],

        region('# comment')                       => %w[es_phpComment Comment],
        region('#comment')                        => %w[es_phpComment Comment],
        region('# ellipsized comment')            => %w[es_phpComment Comment],
        region('# terminated with ?>', at: ..-3)  => %w[es_phpComment Comment],

        word('namespace')                         => %w[es_phpStructure Structure],
        word('extends')                           => %w[es_phpStructure Structure],
        word('implements')                        => %w[es_phpStructure Structure],
        word('instanceof')                        => %w[es_phpStructure Structure],
        word('parent')                            => %w[es_phpStructure Structure],
        word('self')                              => %w[es_phpStructure Structure],

        word('__LINE__')                          => %w[es_phpConstant Constant],
        word('__FILE__')                          => %w[es_phpConstant Constant],
        word('__FUNCTION__')                      => %w[es_phpConstant Constant],
        word('__METHOD__')                        => %w[es_phpConstant Constant],
        word('__CLASS__')                         => %w[es_phpConstant Constant],
        word('__DIR__')                           => %w[es_phpConstant Constant],
        word('__NAMESPACE__')                     => %w[es_phpConstant Constant],
        word('__TRAIT__')                         => %w[es_phpConstant Constant]
      )
    end
  end
end
