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
        word('goto')                     => %w[cStatement Statement],
        word('continue')                 => %w[cStatement Statement],
        word('break')                    => %w[cStatement Statement],
        word('return')                   => %w[cStatement Statement],
        word('asm')                      => %w[cStatement Statement],

        word('case')                     => %w[cLabel Label],
        word('default')                  => %w[cLabel Label],

        word('if')                       => %w[cConditional Conditional],
        word('else')                     => %w[cConditional Conditional],
        word('switch')                   => %w[cConditional Conditional],

        word('while')                    => %w[cRepeat Repeat],
        word('for')                      => %w[cRepeat Repeat],
        word('do')                       => %w[cRepeat Repeat],

        region('"string"')               => %w[cString String],
        region('"str with escape\\\\n"') => %w[cString String],
        region('"long string[^"]\\+$')   => %w[cString String],

        region('#define')                => %w[cDefine Macro],
        region('#undef')                 => %w[cDefine Macro],

        region('"unterminated string')   => %w[cString String],

        region('#pragma')                => %w[cPreProc PreProc],
        region('#line')                  => %w[cPreProc PreProc],
        region('#warning')               => %w[cPreProc PreProc],
        region('#warn')                  => %w[cPreProc PreProc],
        region('#error')                 => %w[cPreProc PreProc],

        region('// comment line')        => %w[cComment Comment],
        region('/\* comment block')      => %w[cComment Comment],
        region('/\* long comment')       => %w[cComment Comment],

        word('struct')                   => %w[cStructure Structure],
        word('union')                    => %w[cStructure Structure],
        word('enum')                     => %w[cStructure Structure],
        word('typedef')                  => %w[cStructure Structure],

        word('static')                   => %w[cStorageClass StorageClass],
        word('register')                 => %w[cStorageClass StorageClass],
        word('auto')                     => %w[cStorageClass StorageClass],
        word('volatile')                 => %w[cStorageClass StorageClass],
        word('extern')                   => %w[cStorageClass StorageClass],
        word('const')                    => %w[cStorageClass StorageClass]
      )
    end

    it 'keeps lines highligh untouched' do
      expect(c_code).to have_line_numbers_highlight(%w[esearchLnum LineNr])
    end
  end
end
