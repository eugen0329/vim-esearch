# frozen_string_literal: true

require 'spec_helper'
require 'plugin/shared_examples/backend'
require 'plugin/shared_examples/abortable_backend'

describe 'esearch#backend', :backend do
  include Helpers::FileSystem

  let(:ccode) do
    <<~CCODE
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
      "escaped_slash\\\\"
      "escaped_char\\d"
      "long_string#{'.' * 100}"

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
    CCODE
  end

  let(:main_c) { file(ccode, 'main.c') }

  let!(:test_directory) do
    directory([
                main_c
              ], 'window/syntax/').persist!
  end

  before do
    esearch.cd! test_directory.path
    esearch.configure!(regex: 1, backend: 'system', adapter: 'ag')
    esearch.search! '^', cwd: subject.path.to_s
  end

  matcher :have_highlights do |expected|
    diffable

    match do
      syntax_names = esearch.editor.inspect_syntax(expected.keys)
      @actual = expected.keys.zip(syntax_names).to_h
      values_match?(expected, @actual)
    end
  end

  describe 'c' do
    subject { main_c }
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
        '"escaped_slash\\\\\\\\"': %w[cString String],
        '"escaped_char\\\\d"':     %w[cString String],
        '"long_string[^"]\+$':     %w[cString String],

        '// comment line':         %w[cCommentL Comment],
        '/\* comment block':       %w[cComment  Comment],
        '/\* long comment':        %w[cComment  Comment],

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
  end
end
