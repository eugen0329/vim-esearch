# frozen_string_literal: true

require 'spec_helper'

describe API::Editor::Serialization::Serializer do
  include API::Editor::Serialization::Helpers

  let(:editor) { API::Editor.new(method(:vim)) }
  let(:serializer) { API::Editor::Serialization::Serializer.new }
  subject { serializer.serialize(original_object) }

  context API::Editor::Serialization::Identifier do
    context 'vim option variable' do
      let(:original_object) { var('&filetype') }
      it { is_expected.to eq('&filetype') }
    end

    context 'vim autoload variable' do
      let(:original_object) { var('g:a#b') }
      it { is_expected.to eq('g:a#b') }
    end
  end

  context API::Editor::Serialization::FunctionCall do
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
