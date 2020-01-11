# frozen_string_literal: true

require 'spec_helper'

describe API::Editor::Serialization do
  let(:editor) { API::Editor.new(method(:vim)) }
  let(:serializer) { API::Editor::Serialization::Serializer.new }
  let(:deserializer) { API::Editor::Serialization::YAMLDeserializer.new }

  context 'roundtrip' do
    subject do
      original_object
        .then(&serializer.method(:serialize))
        .then(&editor.method(:raw_echo))
        .then(&deserializer.method(:deserialize))
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

    context 'non blank array' do
      let(:original_object) { [1, '2', [], {}, [3], { '4' => 5 }] }

      it { is_expected.to eq(original_object) }
    end

    context 'non blank hash' do
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
