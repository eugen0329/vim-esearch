# frozen_string_literal: true

require 'spec_helper'
require 'plugin/shared_examples/backend'
require 'plugin/shared_examples/abortable_backend'

describe 'esearch#backend', :backend do
  include Helpers::FileSystem

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
  let(:main_c) { file(c_code, 'main.c') }

  let(:go_code) do
    <<~GO_CODE
      package main
      import "fmt"

      var a int
      const b int
      func main() {}
      type _ struct {}
      type _ interface {}

      "string"
      "str with escaped slash\"
      "str with escape\\n"
      "long string#{'.' * 100}"
      `raw string`

      // comment line
      /* comment block */
      /* long comment #{'.' * 100}*/

      defer
      go
      goto
      return
      break
      continue
      fallthrough

      case
      default

      for {}
      range()
    GO_CODE
  end
  let(:main_go) { file(go_code, 'main.go') }

  let!(:test_directory) do
    directory([
                main_c,
                main_go,
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

  matcher :have_line_numbers_highlight do |expected|
    diffable
    attr_reader :actual, :expected

    match do |code|
      line_numbers = code
        .split("\n")
        .each.with_index(1)
        .reject { |l, i| l.empty? }
        .map { |_, i| i }

      regexps = line_numbers.map { |i|  "^\\s\\+#{i}\\ze\\s" }

      syntax_names = esearch
        .editor
        .detailed_inspect_syntax(regexps)
        .to_a

      @actual = line_numbers.zip(syntax_names).to_h
      @expected = line_numbers.zip([expected] * line_numbers.count).to_h

      values_match?(@expected, @actual)
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

  describe 'go' do
    subject { main_go }

    it 'contains matches' do
      is_expected.to have_highlights({
        'package': %w[goDirective   Statement],
        'import':  %w[goDirective   Statement],

        'var':     %w[goDeclaration Keyword],
        'const':   %w[goDeclaration Keyword],
        'type':    %w[goDeclaration Keyword],
        'func':    %w[goDeclaration Keyword],
        'struct':     %w[goDeclType          Keyword],
        'interface':  %w[goDeclType          Keyword],

        '"string"':                %w[goString    String],
        '"str with escaped slash\\"': %w[goString    String],
        '"str with escape\\\\n"':     %w[goString    String],
        '"long string[^"]\+$':     %w[goString    String],
        '`raw string`$':     %w[goRawString String],

        '// comment line':         %w[goComment Comment],
        '/\* comment block':       %w[goComment Comment],
        '/\* long comment':        %w[goComment Comment],

        'defer':       %w[goStatement         Statement],
        'go':          %w[goStatement         Statement],
        'goto':        %w[goStatement         Statement],
        'return':      %w[goStatement         Statement],
        'break':       %w[goStatement         Statement],
        'continue':    %w[goStatement         Statement],
        'fallthrough': %w[goStatement         Statement],

        'case':    %w[goLabel             Label],
        'default': %w[goLabel             Label],

        'for':    %w[ goRepeat            Repeat],
        'range':  %w[ goRepeat            Repeat],
      })
    end

    it "keeps lines highligh untouched" do
      expect(go_code).to have_line_numbers_highlight(["esearchLnum", "LineNr"])
    end
  end
end
