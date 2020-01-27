# frozen_string_literal: true

require 'spec_helper'

describe VimlValue::SerializationHelpers do
  include described_class

  describe '#var' do
    subject(:dumped) { VimlValue.dump(ruby_object) }

    context 'vim option variable' do
      let(:ruby_object) { var('&filetype') }

      it { expect(dumped).to eq('&filetype') }
    end

    context 'vim autoloadable variable' do
      let(:ruby_object) { var('g:a#b') }

      it { expect(dumped).to eq('g:a#b') }
    end
  end

  describe '#func' do
    subject(:dumped) { VimlValue.dump(ruby_object) }

    context 'without arguments' do
      let(:ruby_object) { func('g:Given#FunctionName') }

      it { expect(dumped).to eq('g:Given#FunctionName()') }
    end

    context 'when not-nested arguments' do
      let(:ruby_object) { func('g:Given#FunctionName', 1, '2', var('&ft'), [], {}) }

      it { expect(dumped).to eq("g:Given#FunctionName(1,'2',&ft,[],{})") }
    end

    context 'when nested arguments' do
      let(:ruby_object) { func('g:Given#FunctionName', 1, '2', var('&ft'), [4, {}], key5: [6]) }

      it { expect(dumped).to eq("g:Given#FunctionName(1,'2',&ft,[4,{}],{'key5':[6]})") }
    end
  end

  describe '#funcref' do
    subject(:loaded) { VimlValue.load(viml_string, allow_toplevel_literals: true) }
    let(:viml_string) { "function('Given#FunctionName')" }

    it { expect(loaded).to eq(funcref('Given#FunctionName')) }
  end
end
