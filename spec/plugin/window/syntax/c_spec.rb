# frozen_string_literal: true

require 'spec_helper'

describe 'esearch window context syntax' do
  include Helpers::FileSystem
  include Helpers::WindowSyntaxContext

  describe 'c' do
    let(:c_code) do
      <<~C_CODE
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
        "str with escape\\n"
        "long string#{'.' * 100}"

        #define
        #undef

        "unterminated string

        #pragma
        #line
        #warning
        #warn
        #error

        // comment line
        /* comment block */
        /* long comment #{'.' * 100}*/

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
      C_CODE
    end
    let!(:test_directory) { directory([main_c], 'window/syntax/').persist! }
    let(:main_c) { file(c_code, 'main.c') }

    before do
      esearch.configure!(regex: 1, backend: 'system', adapter: 'ag')
      esearch.search! '^', cwd: main_c.path.to_s
    end

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
        region('"str with escape\\\\n"') => %w[es_cString String],
        region('"long string[^"]\\+$')   => %w[es_cString String],

        region('#define')                => %w[es_cDefine Macro],
        region('#undef')                 => %w[es_cDefine Macro],

        region('"unterminated string')   => %w[es_cString String],

        region('#pragma')                => %w[es_cPreProc PreProc],
        region('#line')                  => %w[es_cPreProc PreProc],
        region('#warning')               => %w[es_cPreProc PreProc],
        region('#warn')                  => %w[es_cPreProc PreProc],
        region('#error')                 => %w[es_cPreProc PreProc],

        region('// comment line')        => %w[es_cComment Comment],
        region('/\* comment block')      => %w[es_cComment Comment],
        region('/\* long comment')       => %w[es_cComment Comment],

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

    it 'keeps lines highligh untouched' do
      expect(c_code).to have_line_numbers_highlight(%w[esearchLnum LineNr])
    end
  end
end
