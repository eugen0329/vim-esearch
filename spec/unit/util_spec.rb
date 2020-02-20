# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#util' do
  include VimlValue::SerializationHelpers
  include Helpers::FileSystem

  context '#parse_help_options' do
    shared_examples 'adapter help' do |adapter, path: adapter, arg: '--help'|
      let(:option_regexp) { /\A-{1,2}[a-zA-Z0-9][-a-zA-Z0-9]*/ }
      subject do
        VimlValue.load(vim.echo("esearch#util#parse_help_options('#{path} --help')"))
      end

      it "for command `#{adapter} #{arg}` outputs seemingly valid results" do
        is_expected
          .to  be_present
          .and be_a(Hash)
          .and all(satisfy { |key, _| key =~ option_regexp })
      end
    end

    include_examples 'adapter help', 'ag',       arg: '--help'
    include_examples 'adapter help', 'ack',      arg: '--help'
    include_examples 'adapter help', 'git grep', arg: '-h'
    include_examples 'adapter help', 'grep',     arg: '-h'
    include_examples 'adapter help', 'pt',       arg: '--help', path: Configuration.pt_path
    include_examples 'adapter help', 'rg',       arg: '--help', path: Configuration.rg_path
  end

  describe '#clip' do
    subject(:clip) do
      lambda do |value, from, to|
        editor.echo func('esearch#util#clip', value, from, to)
      end
    end

    it { expect(clip.call(0, 1, 4)).to eq(1)   }
    it { expect(clip.call(1, 1, 4)).to eq(1)   }
    it { expect(clip.call(2, 1, 4)).to eq(2)   }
    it { expect(clip.call(3, 1, 4)).to eq(3)   }
    it { expect(clip.call(4, 1, 4)).to eq(4)   }
    it { expect(clip.call(5, 1, 4)).to eq(4)   }
  end

  describe '#ellipsize' do
    subject(:ellipsize) do
      lambda do |text, col, left, right, ellipsize|
        editor.echo func('esearch#util#ellipsize', text, col, left, right, ellipsize)
      end
    end

    context 'when enough room' do
      it "doesn't add ellipsis" do
        expect(ellipsize.call('aaaBBBccc', 5, 5, 5, '|')).to eq('aaaBBBccc')
      end
    end

    context 'when string is bigger then allowed' do
      it { expect(ellipsize.call('aaaBBBccc', 0, 2, 2, '|')).to eq('aaa|')   }
      it { expect(ellipsize.call('aaaBBBccc', 1, 2, 2, '|')).to eq('aaa|')   }
      it { expect(ellipsize.call('aaaBBBccc', 2, 2, 2, '|')).to eq('aaa|')   }
      it { expect(ellipsize.call('aaaBBBccc', 3, 2, 2, '|')).to eq('|aB|')   }
      it { expect(ellipsize.call('aaaBBBccc', 4, 2, 2, '|')).to eq('|BB|') }
      it { expect(ellipsize.call('aaaBBBccc', 5, 2, 2, '|')).to eq('|BB|') }
      it { expect(ellipsize.call('aaaBBBccc', 6, 2, 2, '|')).to eq('|Bc|') }
      it { expect(ellipsize.call('aaaBBBccc', 7, 2, 2, '|')).to eq('|ccc') }
      it { expect(ellipsize.call('aaaBBBccc', 8, 2, 2, '|')).to eq('|ccc') }
    end
  end

  describe '#escape_kind' do
    shared_examples 'it recognizes' do |arg, as:, **meta|
      it "recognizes #{arg} as #{as.inspect}", **meta do
        expect(vim.echo("esearch#util#escape_kind(\"#{arg}\")")).to eq(VimlValue.dump(as))
      end
    end

    shared_examples 'it recognizes with all escapes except Shift-*' do |char|
      include_examples 'it recognizes', "\\<C-#{char}>", as: 'control'
      include_examples 'it recognizes', "\\<M-#{char}>", as: 'meta'
      include_examples 'it recognizes', "\\<A-#{char}>", as: 'meta'
      include_examples 'it recognizes', "\\<D-#{char}>", as: 'meta', osx_only: true
    end

    shared_examples 'it recognizes with all escapes' do |char|
      include_examples 'it recognizes with all escapes except Shift-*', char

      include_examples 'it recognizes', "\\<S-#{char}>", as: 'shift'
    end

    shared_examples 'recognize as a regular char' do |char|
      include_examples 'it recognizes', char, as: 0
    end

    context 'ascii alphabet' do
      ('a'..'z').each do |char|
        include_examples 'it recognizes with all escapes except Shift-*', char
        include_examples 'recognize as a regular char', char
      end
    end

    context 'multibyte alphabet' do

      context 'with escaping', :multibyte_commandline do
        around { |e| use_nvim(&e) }

        ('α'..'ω').to_a.concat(('Α'..'Ω').to_a).each do |char|
          include_examples 'it recognizes with all escapes except Shift-*', char
        end
      end

      context 'regular' do
        ('α'..'ω').to_a.concat(('Α'..'Ω').to_a).each do |char|
          include_examples 'recognize as a regular char', char
        end
      end
    end

    context 'F1-F12' do
      (1..12).each do |char|
        include_examples 'it recognizes', "\\<F#{char}>", as: 'f'
        include_examples 'it recognizes with all escapes', "F#{char}"
      end
    end

    context 'k0-k9' do
      (0..9).each do |char|
        include_examples 'it recognizes with all escapes', "k#{char}"
      end
    end

    context 'prefixes' do
      context 'looking like a combination with Control' do
        include_examples 'recognize as a regular char', '^'
        include_examples 'recognize as a regular char', '^a'
        include_examples 'recognize as a regular char', '^A'
      end

      context 'looking like a combination with Alt' do
        include_examples 'recognize as a regular char', '^['
        include_examples 'recognize as a regular char', '^[1'
        include_examples 'recognize as a regular char', '^[f'
        include_examples 'recognize as a regular char', '<80><fc>^Hf'
      end
    end

    # :h key-notation
    context 'key-notation' do
      %w[Tab Nul BS NL Space lt Bslash Bar Esc Del CSI Return CR Enter xCSI Up
         Down Left Right Help Undo Insert Home End PageUp PageDown kUp kDown kLeft
         kRight kHome kEnd kOrigin kPageUp kPageDown kDel kPlus kMinus kMultiply
         kDivide kPoint kComma kEqual kEnter].each do |char|
        include_examples 'it recognizes with all escapes', char
      end
    end
  end
end
