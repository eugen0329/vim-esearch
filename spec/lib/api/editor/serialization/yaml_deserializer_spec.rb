# frozen_string_literal: true

require 'spec_helper'

describe API::Editor::Serialization::YAMLDeserializer do
  include API::Editor::Serialization::Helpers

  let(:editor) { API::Editor.new(method(:vim)) }
  let(:deserializer) { API::Editor::Serialization::YAMLDeserializer.new }
  let(:string) { '' }

  subject { deserializer.deserialize(string) }

  context 'toplevel list' do
    context 'blank' do
      let(:string) { '[]' }

      it { is_expected.to eq([]) }
    end

    context 'non blank' do
      let(:string) { '[1]' }
      it { is_expected.to eq([1]) }
    end
  end

  context 'toplevel dict' do
    context 'blank' do
      let(:string) { '{}' }

      it { is_expected.to eq({}) }
    end

    context 'non blank' do
      let(:string) { "{'1': 2}" }
      it { is_expected.to eq('1' => 2) }
    end
  end

  context 'toplevel scalar' do
    context 'numbers' do
      it { expect(deserializer.deserialize('1')).to eq(1) }
      it { expect(deserializer.deserialize('1.2')).to eq(1.2) }
    end

    context 'string' do
      context 'blank' do
        let(:string) { '""' }

        it { is_expected.to eq('') }
      end

      context 'non blank' do
        let(:string) { "'given string'" }

        it { is_expected.to eq('given string') }
      end

      # vim feature that should be avoided
      context 'without surrounding quotes' do
        context 'stripped (like after #strip call)' do
          let(:string) { 'given string' }

          it { is_expected.to eq('given string') }
        end

        context 'with surrounding spaces' do
          let(:string) { '  given string ' }

          it { is_expected.to eq('  given string ') }
        end

        context 'any other object with leading spaces' do
          let(:string) { '  {} ' }

          it { is_expected.to eq('  {} ') }
        end
      end
    end
  end
end
