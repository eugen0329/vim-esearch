# frozen_string_literal: true

require 'spec_helper'

describe 'Smoke of esearch#util' do
  describe 'esearch#util#escape_kind' do
    def invoke(arg)
      vim.echo("esearch#util#escape_kind(\"#{arg}\")")
    end

    shared_examples 'works with all escape methods except Shift' do |char|
      it "recognizes <C-#{char}> as control" do
        expect(invoke("\\<C-#{char}>")).to eq("'control'")
      end

      it "recognizes <M-#{char}> as meta" do
        expect(invoke("\\<M-#{char}>")).to eq("'meta'")
      end

      it "recognizes <A-#{char}> as meta" do
        expect(invoke("\\<A-#{char}>")).to eq("'meta'")
      end

      context 'super char' do
        it "recognizes <D-#{char}> as meta", :osx_only do
          expect(invoke("\\<D-#{char}>")).to eq("'meta'")
        end
      end
    end

    shared_examples 'works with all escape methods' do |char|
      include_examples 'works with all escape methods except Shift', char

      it "recognizes <S-#{char}> as shift" do
        expect(invoke("\\<S-#{char}>")).to eq("'shift'")
      end
    end

    shared_examples 'recognize as a simple char' do |char|
      it "recognizes #{char.inspect} as a simple char" do
        expect(invoke(char)).to eq("''")
      end
    end

    context 'ascii alphabet' do
      ('a'..'z').each do |char|
        include_examples 'works with all escape methods except Shift', char

        include_examples 'recognize as a simple char', char
      end
    end

    context 'multibyte alphabet' do

      context 'with escaping', :multibyte_commandline do
        around { |e| use_nvim(&e) }

        ('α'..'ω').to_a.concat(('Α'..'Ω').to_a).each do |char|
          include_examples 'works with all escape methods except Shift', char
        end
      end

      context 'regular' do
        ('α'..'ω').to_a.concat(('Α'..'Ω').to_a).each do |char|
          include_examples 'recognize as a simple char', char
        end
      end
    end

    (1..12).each do |char|
      it "recognizes <F#{char}> as f" do
        expect(invoke("\\<F#{char}>")).to eq("'f'")
      end

      include_examples 'works with all escape methods', "F#{char}"
    end

    (0..9).each do |char|
      include_examples 'works with all escape methods', "k#{char}"
    end

    %w[
      Tab
      Nul
      BS
      NL
      Space
      lt
      Bslash
      Bar
      Esc
      Del
      CSI
      Return
      CR
      Enter
      xCSI
      Up
      Down
      Left
      Right
      Help
      Undo
      Insert
      Home
      End
      PageUp
      PageDown
      kUp
      kDown
      kLeft
      kRight
      kHome
      kEnd
      kOrigin
      kPageUp
      kPageDown
      kDel
      kPlus
      kMinus
      kMultiply
      kDivide
      kPoint
      kComma
      kEqual
      kEnter
    ].each do |char|
      include_examples 'works with all escape methods', char
    end
  end
end
