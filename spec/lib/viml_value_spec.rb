# frozen_string_literal: true

require 'spec_helper'

describe VimlValue do
  include VimlValue::SerializationHelpers

  describe 'dump -> eval -> load' do
    subject(:dump_eval_load) do
      lambda do |ruby_object|
        VimlValue
          .dump(ruby_object)
          .then { |dumped_string| vim.echo(dumped_string) }
          .then { |echo_output_string| VimlValue.load(echo_output_string) }
      end
    end

    context 'literals' do
      context 'integer' do
        it { expect(dump_eval_load.call([1])).to  eq([1])  }
        it { expect(dump_eval_load.call([-2])).to eq([-2]) }
      end

      context 'float' do
        it { expect(dump_eval_load.call([1.2])).to    eq([1.2])    }
        it { expect(dump_eval_load.call([1e-20])).to  eq([1e-20])  }
        it { expect(dump_eval_load.call([1e+20])).to  eq([1e+20])  }
        it { expect(dump_eval_load.call([-1.2])).to   eq([-1.2])   }
        it { expect(dump_eval_load.call([-1e-20])).to eq([-1e-20]) }
        it { expect(dump_eval_load.call([-1e+20])).to eq([-1e+20]) }
      end

      context 'string' do
        it { expect(dump_eval_load.call([''])).to          eq([''])          }
        it { expect(dump_eval_load.call(['non-blank'])).to eq(['non-blank']) }
      end
    end

    context 'expressions' do
      let(:variable) { var('&compatible') }
      let(:function1) { func('tr', 'hi', 'h', 'H') }
      let(:function2) { func('values', '1' => -2, '3' => '4') }
      let(:funcref1)   { funcref('sort', [2, 1]) }
      let(:funcref2)   { funcref('sort') }
      let(:string) { 'regular string' }

      let(:actual) { [variable, function1, function2, funcref1, funcref2, string] }
      let(:expected) { [0, 'Hi', [-2, '4'], funcref1, funcref2, string] }

      it { expect(dump_eval_load.call(actual)).to eq(expected) }
    end

    context 'nested function call' do
      let(:function1) { func('sort', [[1], 2]) }
      let(:function2) { func('sort', function1[1])[0] }

      it { expect(dump_eval_load.call([function2])).to eq([1]) }
    end

    context 'nil' do
      it { expect(dump_eval_load.call([nil])).to eq([nil]) }
    end

    context 'none' do
      it { expect(dump_eval_load.call([none])).to eq([none]) }
    end

    context 'boolean' do
      it { expect(dump_eval_load.call([true])).to  eq([true])  }
      it { expect(dump_eval_load.call([false])).to eq([false]) }
    end

    context 'hash' do
      context 'blank' do
        it { expect(dump_eval_load.call({})).to eq({}) }
      end

      context 'non blank' do
        let(:hash) do
          {
            '1' => 2,
            '3' => [],
            '4' => {},
            '5' => [6],
            '7' => {'8' => 9},
          }
        end

        it { expect(dump_eval_load.call(hash)).to eq(hash) }
      end
    end
  end
end
