# frozen_string_literal: true

require 'spec_helper'

describe VimlValue::SerializationHelpers do
  include described_class

  let(:editor) { Editor.new(method(:vim)) }
  subject { VimlValue.dump(original_object) }

  context 'viml variables' do
    context 'vim option variable' do
      let(:original_object) { var('&filetype') }
      it { is_expected.to eq('&filetype') }
    end

    context 'vim autoloadable variable' do
      let(:original_object) { var('g:a#b') }
      it { is_expected.to eq('g:a#b') }
    end
  end

  context 'viml function calls' do
    context 'without arguments' do
      let(:original_object) { func('g:Given#Function') }

      it { is_expected.to eq('g:Given#Function()') }
    end

    context 'when scalar arguments' do
      let(:original_object) { func('g:Given#Function', 1, '2', var('&ft'), [], {}) }

      it { is_expected.to eq("g:Given#Function(1,'2',&ft,[],{})") }
    end

    context 'when nested arguments' do
      let(:original_object) { func('g:Given#Function', 1, '2', var('&ft'), [4, {}], key5: [6]) }

      it { is_expected.to eq("g:Given#Function(1,'2',&ft,[4,{}],{'key5':[6]})") }
    end
  end
end
