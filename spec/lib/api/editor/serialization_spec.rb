# frozen_string_literal: true

require 'spec_helper'

describe API::Editor::Serialization do
  ToplevelUnquotedStrError = API::Editor::Serialization::YAMLDeserializer::ToplevelUnquotedStrError

  let(:editor) { API::Editor.new(method(:vim)) }
  let(:serializer) { API::Editor::Serialization::Serializer.new }
  let(:deserializer) { API::Editor::Serialization::YAMLDeserializer.new }

  describe 'serialize -> eval -> deserialize' do
    let(:allow_toplevel_unquoted_strings) { false }
    shared_context 'allow_toplevel_unquoted_strings: true' do
      let(:allow_toplevel_unquoted_strings) { true }
    end
    shared_context 'allow_toplevel_unquoted_string: false' do
      let(:allow_toplevel_unquoted_strings) { false }
    end

    subject(:serialize_eval_deserialize) do
      proc do |obj|
        obj
          .then { |ruby_object| serializer.serialize(ruby_object)   }
          .then { |serialized|  editor.raw_echo(serialized)         }
          .then { |evaluated|   deserializer.deserialize(evaluated, allow_toplevel_unquoted_strings) }
      end
    end

    context 'literals' do
      context 'integer' do
        context_when 'allow_toplevel_unquoted_strings: true' do
          it { expect(subject.call(1)).to eq(1) }
        end

        context_when 'allow_toplevel_unquoted_string: false' do
          it { expect(subject.call(1)).to eq(1) }
        end
      end

      context 'float' do
        context 'regular' do
          context_when 'allow_toplevel_unquoted_strings: true' do
            it { expect(subject.call(1.2)).to eq(1.2) }
          end

          context_when 'allow_toplevel_unquoted_string: false' do
            it { expect(subject.call(1.2)).to eq(1.2) }
          end
        end

        context 'tiny' do
          context_when 'allow_toplevel_unquoted_strings: true' do
            it { expect(subject.call(1e-20)).to eq(1e-20) }
          end

          context_when 'allow_toplevel_unquoted_string: false' do
            it { expect(subject.call(1e-20)).to eq(1e-20) }
          end
        end

        context 'huge' do
          before { pending 'YAML.safe_load cannot handle "1.0e10"' }

          context_when 'allow_toplevel_unquoted_strings: true' do
            it { expect(subject.call(1e+20)).to eq(1e+20) }
          end

          context_when 'allow_toplevel_unquoted_string: false' do
            it { expect(subject.call(1e+20)).to eq(1e+20) }
          end
        end
      end

      context 'string' do
        context 'toplevel' do
          context_when 'allow_toplevel_unquoted_strings: true' do
            it { expect(subject.call('')).to eq('') }
            it { expect(subject.call('non-blank')).to eq('non-blank') }
          end

          context_when 'allow_toplevel_unquoted_string: false' do
            it do
              expect { subject.call('') }
                .to raise_error ToplevelUnquotedStrError
            end
            it do
              expect { subject.call('non-blank') }
                .to raise_error ToplevelUnquotedStrError
            end
          end
        end

        context "wrapped with array (like [''])" do
          context_when 'allow_toplevel_unquoted_strings: true' do
            it { expect(subject.call([''])).to eq(['']) }
            it { expect(subject.call(['non-blank'])).to eq(['non-blank']) }
          end

          context_when 'allow_toplevel_unquoted_string: false' do
            it { expect(subject.call([''])).to eq(['']) }
            it { expect(subject.call(['non-blank'])).to eq(['non-blank']) }
          end
        end
      end

      context 'nil' do
        context_when 'allow_toplevel_unquoted_strings: true' do
          it { expect(subject.call(nil)).to eq('') }
        end

        context_when 'allow_toplevel_unquoted_string: false' do
          it do
            expect { subject.call('non-blank') }
              .to raise_error ToplevelUnquotedStrError
          end
        end
      end
    end

    # non-scalars are pretty stable, no need to test wrapped/unwrapped
    context 'array' do
      context 'blank' do
        it { expect(subject.call([])).to eq([]) }
      end

      context 'non blank' do
        let(:obj) { [1, '2', [], {}, [3], {'4' => 5}] }

        it { expect(subject.call(obj)).to eq(obj) }
      end
    end

    context 'hash' do
      context 'blank' do
        it { expect(subject.call({})).to eq({}) }
      end

      context 'non blank' do
        let(:obj) do
          {
            '1' => 2,
            '3' => [],
            '4' => {},
            '5' => [6],
            '7' => {'8' => 9}
          }
        end
        it { expect(subject.call(obj)).to eq(obj) }
      end
    end
  end
end
