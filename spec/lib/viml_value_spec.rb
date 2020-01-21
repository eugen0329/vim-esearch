# frozen_string_literal: true

require 'spec_helper'

describe VimlValue do
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

    context 'nil' do
      it { expect(dump_eval_load.call([nil])).to eq([nil]) }
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
            '7' => {'8' => 9}
          }
        end

        it { expect(dump_eval_load.call(hash)).to eq(hash) }
      end
    end
  end
end
