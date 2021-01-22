# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#util' do
  include VimlValue::SerializationHelpers
  include Helpers::FileSystem

  describe '#escape_kind' do
    shared_examples 'it recognizes' do |arg, as:, **meta|
      it "recognizes #{arg} as #{as.inspect}", **meta do
        expect(vim.echo("esearch#keymap#escape_kind(\"#{arg}\")")).to eq(VimlValue.dump(as))
      end
    end

    shared_examples 'it recognizes with all escapes except Shift-*' do |char|
      include_examples 'it recognizes', "\\<c-#{char}>", as: 'control'
      include_examples 'it recognizes', "\\<m-#{char}>", as: 'meta'
      include_examples 'it recognizes', "\\<a-#{char}>", as: 'meta'
      include_examples 'it recognizes', "\\<d-#{char}>", as: 'meta', osx_only: true
    end

    shared_examples 'it recognizes with all escapes' do |char|
      include_examples 'it recognizes with all escapes except Shift-*', char

      include_examples 'it recognizes', "\\<s-#{char}>", as: 'shift'
    end

    shared_examples 'recognize as a regular char' do |char|
      include_examples 'it recognizes', char, as: ''
    end

    context 'ascii alphabet' do
      ('a'..'z').to_a.sample(5).each do |char|
        include_examples 'it recognizes with all escapes except Shift-*', char
        include_examples 'recognize as a regular char', char
      end
    end

    context 'multibyte alphabet' do
      # TODO: VADER migration :neovim
      xcontext 'with escaping', :multibyte do
        ('α'..'ω').to_a.concat(('Α'..'Ω').to_a).sample(5).each do |char|
          include_examples 'it recognizes with all escapes except Shift-*', char
        end
      end

      context 'regular' do
        ('α'..'ω').to_a.concat(('Α'..'Ω').to_a).sample(5).each do |char|
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
