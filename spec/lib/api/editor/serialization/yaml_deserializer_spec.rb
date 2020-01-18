# frozen_string_literal: true

require 'spec_helper'

# Just a superficial unit testing to allow isolate a problem (if the one
# occurs) without involving Vimrunner.
# For more rigorious specs refer to spec/lib/integration/serialization_spec.rb
describe API::Editor::Serialization::YAMLDeserializer do
  let(:deserializer) { API::Editor::Serialization::YAMLDeserializer.new }
  let(:allow_toplevel_unquoted_strings) { false }

  subject { deserializer.deserialize(string) }

  def deserialize(string)
    deserializer.deserialize(string, allow_toplevel_unquoted_strings)
  end

  context 'toplevel list' do
    context 'blank' do
      it { expect(deserialize('[]')).to eq([]) }
    end

    context 'non blank' do
      it { expect(deserialize('[1]')).to eq([1]) }
    end
  end

  context 'toplevel dict' do
    context 'blank' do
      it { expect(deserialize('{}')).to eq({}) }
    end

    context 'non blank' do
      it { expect(deserialize("{'1': 2}")).to eq('1' => 2) }
    end
  end

  context 'toplevel scalar' do
    context 'numbers' do
      it { expect(deserialize('1')).to eq(1) }
      it { expect(deserialize('1.2')).to eq(1.2) }
    end

    context 'string' do
      context 'blank' do
        it { expect(deserialize('""')).to eq('') }
        it { expect(deserialize("''")).to eq('') }
      end

      context 'non blank' do
        it { expect(deserialize("'given'")).to eq('given') }
        it { expect(deserialize('"given"')).to eq('given') }
      end

      # Consider to forbid toplevel strings
      context 'without surrounding quotes' do
        let(:allow_toplevel_unquoted_strings) { true }

        context 'stripped' do
          it { expect(deserialize('no \w around')).to eq('no \w around') }
        end

        context 'with surrounding spaces' do
          it { expect(deserialize(' given  ')).to eq(' given  ') }
        end

        context 'any other object with leading spaces' do
          it { expect(deserialize('  {} ')).to eq('  {} ') }
        end
      end
    end
  end
end
