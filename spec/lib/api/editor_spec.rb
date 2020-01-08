# frozen_string_literal: true

require 'spec_helper'

describe 'lib/api/editor', :editor do
  include Helpers::FileSystem

  let(:editor) { API::Editor.new(method(:vim)) }

  describe 'batch echo' do
    let(:filename) { 'file.txt' }
    let!(:test_directory) { directory([file("a\nb", filename)]).persist! }
    before do
      editor.cd! test_directory
      editor.edit! filename
    end

    it  do
      expect(vim).to receive(:echo).once.and_call_original
      expect(editor.echo { |e| [e.line(1), e.line(2)] }).to eq(%w[a b])
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
