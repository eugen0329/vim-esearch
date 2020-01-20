# frozen_string_literal: true

require 'spec_helper'

describe Editor::Serialization do
  let(:editor) { Editor.new(method(:vim)) }

  describe 'serialize -> eval -> deserialize' do
    subject(:serialize_eval_deserialize) do
      proc do |ruby_object|
        VimlValue.dump(ruby_object)
          .then { |dumped|    editor.raw_echo(dumped) }
          .then { |evaluated| VimlValue.load(evaluated, allow_toplevel_literals: false) }
      end
    end

    context 'literals' do
      context 'integer' do
        it { expect(subject.call([1])).to eq([1]) }
        it { expect(subject.call([-2])).to eq([-2]) }
      end

      context 'float' do
        it { expect(subject.call([1.2])).to eq([1.2]) }
        it { expect(subject.call([1e-20])).to eq([1e-20]) }
        it { expect(subject.call([1e+20])).to eq([1e+20]) }
        it { expect(subject.call([-1.2])).to eq([-1.2]) }
        it { expect(subject.call([-1e-20])).to eq([-1e-20]) }
        it { expect(subject.call([-1e+20])).to eq([-1e+20]) }
      end

      context 'string' do
        it { expect(subject.call([''])).to eq(['']) }
        it { expect(subject.call(['non-blank'])).to eq(['non-blank']) }
      end
    end

    context 'hash' do
      it { expect(subject.call({})).to eq({}) }

      context 'non blank' do
        let(:ruby_object) do
          {
            '1' => 2,
            '3' => [],
            '4' => {},
            '5' => [6],
            '7' => {'8' => 9}
          }
        end

        it { expect(subject.call(ruby_object)).to eq(ruby_object) }
      end
    end
  end
end
