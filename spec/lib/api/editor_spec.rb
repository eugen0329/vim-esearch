# frozen_string_literal: true

require 'spec_helper'

# TODO: split and refactor
describe API::Editor, :editor do
  include Helpers::FileSystem

  let(:editor) { API::Editor.new(method(:vim)) }

  describe 'batch echo' do
    context 'array' do
      let(:filename) { 'file.txt' }
      let!(:test_directory) { directory([file("a\nb", filename)]).persist! }
      before do
        editor.cd! test_directory
        editor.edit! filename
      end

      it do
        expect(vim).to receive(:echo).once.and_call_original
        expect([editor.line(1), editor.line(2)]).to eq(%w[a b])
      end
    end

    context 'when caching' do
      # TODO: test for #with_ignore_cache and #cache_enabled
      context 'when enabled' do
        let(:filename) { 'file.txt' }
        let!(:test_directory) { directory([file("a\nb", filename)]).persist! }
        before do
          editor.cd! test_directory
          editor.edit! filename
        end

        it do
          expect(vim).to receive(:echo).once.and_call_original

          expect([editor.line(1), editor.line(2)]).to eq(%w[a b])
          expect(editor.line(2)).to eq('b')
        end

        it do
          expect(vim).to receive(:echo).once.and_call_original

          expect([editor.line(1), editor.line(2)]).to eq(%w[a b])
          expect([editor.line(1), editor.line(2)]).to eq(%w[a b])
        end

        it do
          expect(vim).to receive(:echo).once.with('[getline(1)]').and_call_original
          expect(vim).to receive(:echo).once.with('[getline(2)]').and_call_original

          expect(editor.line(1)).to eq('a')
          expect([editor.line(1), editor.line(2)]).to eq(%w[a b])
        end
      end
    end
  end

  describe 'serialization' do
    let(:serializer) { API::Editor::Serialization::Serializer.new }
    let(:deserializer) { API::Editor::Serialization::Deserializer.new }

    subject do
      deserializer.deserialize(editor.raw_echo(serializer.serialize(original_object)))
    end

    context 'blank array' do
      let(:original_object) { [] }
      it { is_expected.to eq(original_object) }
    end

    context 'blank hash' do
      let(:original_object) { {} }
      it { is_expected.to eq(original_object) }
    end

    context 'nil' do
      let(:original_object) { nil }
      it { is_expected.to eq('') }
    end

    context 'blank_string' do
      let(:original_object) { '' }
      it { is_expected.to eq(original_object) }
    end

    context 'full array' do
      let(:original_object) { [1, '2', [], {}, [3], { '4' => 5 }] }
      it { is_expected.to eq(original_object) }
    end

    context 'full hash' do
      let(:original_object) do
        {
          '1' => 2,
          '3' => [],
          '4' => {},
          '5' => [6],
          '7' => {
            '8' => 9
          }
        }
      end
      it { is_expected.to eq(original_object) }
    end
  end
end
