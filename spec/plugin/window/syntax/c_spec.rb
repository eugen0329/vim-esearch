# frozen_string_literal: true

require 'spec_helper'
require_relative 'setup_syntax_testing_shared_context'

describe 'esearch window context syntax', :window do
  include Helpers::FileSystem
  include Helpers::WindowSyntaxContext

  describe 'c' do
    let(:source_file_content) do
      <<~SOURCE
        goto
        break
        return
        continue
        asm

        case
        default

        if
        else
        switch

        while(1) {}
        for(;;) {}
        do {} while();

        "string"
        "escaped quote\\"
        "str with escape\\n"

        #define
        #undef

        "missing quote

        #pragma
        #line
        #warning
        #warn
        #error

        // comment line
        /* comment block */
        /* ellipsized comment #{'.' * 500}*/

        struct{}
        union{}
        enum{}
        typedef{}

        static var;
        register var;
        auto var;
        volatile var;
        extern var;
        const var;
      SOURCE
    end
    let(:source_file) { file(source_file_content, 'main.c') }

    include_context 'setup syntax testing'

    # 1. Verification is done in a single example for performance reasons (as
    # vim's +clientserver is too sluggish; it doesn't affect debuggability as
    # the matcher is diffable)
    # 2. Lines that can cause matching across line end (e.g. not terminated strings
    # or comments) are not groupped and scattered across source_file to cause as
    # more potential errors as possible
    it do
      is_expected.to have_highligh_aliases(
        word('goto')                     => %w[es_cStatement Statement],
        word('continue')                 => %w[es_cStatement Statement],
        word('break')                    => %w[es_cStatement Statement],
        word('return')                   => %w[es_cStatement Statement],
        word('asm')                      => %w[es_cStatement Statement],

        word('case')                     => %w[es_cLabel Label],
        word('default')                  => %w[es_cLabel Label],

        word('if')                       => %w[es_cConditional Conditional],
        word('else')                     => %w[es_cConditional Conditional],
        word('switch')                   => %w[es_cConditional Conditional],

        word('while')                    => %w[es_cRepeat Repeat],
        word('for')                      => %w[es_cRepeat Repeat],
        word('do')                       => %w[es_cRepeat Repeat],

        region('"string"')               => %w[es_cString String],
        region('"escaped quote\\\\"')    => %w[es_cString String],
        region('"str with escape\\\\n"') => %w[es_cString String],

        region('#define')                => %w[es_cDefine Macro],
        region('#undef')                 => %w[es_cDefine Macro],

        region('"missing quote')         => %w[es_cString String],

        region('#pragma')                => %w[es_cPreProc PreProc],
        region('#line')                  => %w[es_cPreProc PreProc],
        region('#warning')               => %w[es_cPreProc PreProc],
        region('#warn')                  => %w[es_cPreProc PreProc],
        region('#error')                 => %w[es_cPreProc PreProc],

        region('// comment line')        => %w[es_cComment Comment],
        region('/\* comment block')      => %w[es_cComment Comment],
        region('/\* ellipsized comment') => %w[es_cComment Comment],

        word('struct')                   => %w[es_cStructure Structure],
        word('union')                    => %w[es_cStructure Structure],
        word('enum')                     => %w[es_cStructure Structure],
        word('typedef')                  => %w[es_cStructure Structure],

        word('static')                   => %w[es_cStorageClass StorageClass],
        word('register')                 => %w[es_cStorageClass StorageClass],
        word('auto')                     => %w[es_cStorageClass StorageClass],
        word('volatile')                 => %w[es_cStorageClass StorageClass],
        word('extern')                   => %w[es_cStorageClass StorageClass],
        word('const')                    => %w[es_cStorageClass StorageClass]
      )
    end
  end
end
