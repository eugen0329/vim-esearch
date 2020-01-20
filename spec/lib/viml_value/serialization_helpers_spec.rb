# frozen_string_literal: true

require 'spec_helper'

describe VimlValue::SerializationHelpers do
  include described_class

  subject(:dumped) { VimlValue.dump(original_object) }

  context '#var' do
    context 'vim option variable' do
      let(:original_object) { var('&filetype') }
      it { expect(dumped).to eq('&filetype') }
    end

    context 'vim autoloadable variable' do
      let(:original_object) { var('g:a#b') }
      it { expect(dumped).to eq('g:a#b') }
    end
  end

  context '#func' do
    context 'without arguments' do
      let(:original_object) { func('g:Given#Function') }

      it { expect(dumped).to eq('g:Given#Function()') }
    end

    context 'when scalar arguments' do
      let(:original_object) { func('g:Given#Function', 1, '2', var('&ft'), [], {}) }

      it { expect(dumped).to eq("g:Given#Function(1,'2',&ft,[],{})") }
    end

    context 'when nested arguments' do
      let(:original_object) { func('g:Given#Function', 1, '2', var('&ft'), [4, {}], key5: [6]) }

      it { expect(dumped).to eq("g:Given#Function(1,'2',&ft,[4,{}],{'key5':[6]})") }
    end
  end
end
