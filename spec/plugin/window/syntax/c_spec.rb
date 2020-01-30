require 'spec_helper'

describe 'esearch#backend', :backend do
  include Helpers::FileSystem
  include Helpers::Syntax

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
        "str with escaped slash\"
        "str with escape\\n"
        "long string#{'.' * 100}"

        // comment line
        /* comment block */
        /* long comment #{'.' * 100}*/

        #define
        #undef

        #pragma
        #line
        #warning
        #warn
        #error

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
      is_expected.to have_highlights(
        'goto':                    %w[cStatement Statement],
        'continue':                %w[cStatement Statement],
        'break':                   %w[cStatement Statement],
        'return':                  %w[cStatement Statement],
        'asm':                     %w[cStatement Statement],

        'case':                    %w[cLabel Label],
        'default':                 %w[cLabel Label],

        'if':                      %w[cConditional Conditional],
        'else':                    %w[cConditional Conditional],
        'switch':                  %w[cConditional Conditional],

        'while':                   %w[cRepeat Repeat],
        'for':                     %w[cRepeat Repeat],
        'do':                      %w[cRepeat Repeat],

        '"string"':                %w[cString String],
        '"str with escaped slash\\"': %w[cString String],
        '"str with escape\\\\n"':     %w[cString String],
        '"long string[^"]\+$':     %w[cString String],

        '// comment line':         %w[cComment Comment],
        '/\* comment block':       %w[cComment Comment],
        '/\* long comment':        %w[cComment Comment],

        '#define':                 %w[cDefine Macro],
        '#undef':                  %w[cDefine Macro],

        '#pragma':                 %w[cPreProc PreProc],
        '#line':                   %w[cPreProc PreProc],
        '#warning':                %w[cPreProc PreProc],
        '#warn':                   %w[cPreProc PreProc],
        '#error':                  %w[cPreProc PreProc],

        'struct':                  %w[cStructure Structure],
        'union':                   %w[cStructure Structure],
        'enum':                    %w[cStructure Structure],
        'typedef':                 %w[cStructure Structure],

        'static':                  %w[cStorageClass StorageClass],
        'register':                %w[cStorageClass StorageClass],
        'auto':                    %w[cStorageClass StorageClass],
        'volatile':                %w[cStorageClass StorageClass],
        'extern':                  %w[cStorageClass StorageClass],
        'const':                   %w[cStorageClass StorageClass]
      )
    end

    it "keeps lines highligh untouched" do
      expect(c_code).to have_line_numbers_highlight(["esearchLnum", "LineNr"])
    end
  end
end
