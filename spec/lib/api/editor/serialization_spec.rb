# frozen_string_literal: true

require 'spec_helper'

describe API::Editor::Serialization do
  ToplevelUnquotedStrError = API::Editor::Serialization::YAMLDeserializer::ToplevelUnquotedStrError

  let(:editor) { API::Editor.new(method(:vim)) }
  let(:serializer) { API::Editor::Serialization::Serializer.new }
  let(:deserializer) { API::Editor::Serialization::YAMLDeserializer.new }

  describe 'Serialization, or There and Back Again' do
    let(:allow_toplevel_unquoted_strings) { false }

    def serialize_eval_deserialize(obj)
      obj
        .then { |ruby_object| serializer.serialize(ruby_object)   }
        .then { |serialized|  editor.raw_echo(serialized)         }
        .then { |evaluated|   deserializer.deserialize(evaluated, allow_toplevel_unquoted_strings) }
    end

    shared_context 'it works when unquoted toplevel str allowed' do
      let(:allow_toplevel_unquoted_strings) { true }
    end
    shared_context 'it !work when unquoted toplevel str !allowed' do
      let(:allow_toplevel_unquoted_strings) { false }
    end
    shared_context 'it works when unquoted toplevel str !allowed' do
      let(:allow_toplevel_unquoted_strings) { false }
    end
    shared_examples 'obj == obj.serialize.eval.deserialize' do |obj:|
      it { expect(serialize_eval_deserialize(obj)).to eq(obj) }
    end
    shared_examples 'obj.serialize.eval.deserialize RAISES err' do |obj:, err:|
      it { expect { serialize_eval_deserialize(obj) }.to raise_error(err) }
    end

    context 'literals' do
      context 'integer' do
        it_behaves_like 'it works when unquoted toplevel str allowed' do
          it_behaves_like 'obj == obj.serialize.eval.deserialize', obj: 1
        end

        it_behaves_like 'it works when unquoted toplevel str !allowed' do
          it_behaves_like 'obj == obj.serialize.eval.deserialize', obj: 1
        end
      end

      context 'float' do
        context 'regular' do
          it_behaves_like 'it works when unquoted toplevel str allowed' do
            it_behaves_like 'obj == obj.serialize.eval.deserialize', obj: 1.2
          end

          it_behaves_like 'it works when unquoted toplevel str !allowed' do
            it_behaves_like 'obj == obj.serialize.eval.deserialize', obj: 1.2
          end
        end

        context 'tiny' do
          it_behaves_like 'it works when unquoted toplevel str allowed' do
            it_behaves_like 'obj == obj.serialize.eval.deserialize', obj: 1e-20
          end

          it_behaves_like 'it works when unquoted toplevel str !allowed' do
            it_behaves_like 'obj == obj.serialize.eval.deserialize', obj: 1e-20
          end
        end

        context 'huge' do
          before { pending 'YAML.safe_load cannot handle "1.0e10"' }

          it_behaves_like 'it works when unquoted toplevel str allowed' do
            it_behaves_like 'obj == obj.serialize.eval.deserialize', obj: 1e+20
          end

          it_behaves_like 'it works when unquoted toplevel str !allowed' do
            it_behaves_like 'obj == obj.serialize.eval.deserialize', obj: 1e+20
          end
        end
      end

      context 'string' do
        context 'top level' do
          it_behaves_like 'it works when unquoted toplevel str allowed' do
            it_behaves_like 'obj == obj.serialize.eval.deserialize', obj: ''
            it_behaves_like 'obj == obj.serialize.eval.deserialize', obj: 'non-blank string'
          end

          it_behaves_like 'it !work when unquoted toplevel str !allowed' do
            it_behaves_like 'obj.serialize.eval.deserialize RAISES err',
              obj: '',
              err: ToplevelUnquotedStrError
            it_behaves_like 'obj.serialize.eval.deserialize RAISES err',
              obj: 'non-blank string',
              err: ToplevelUnquotedStrError
          end
        end

        context "wrapped with array (like [''])" do
          it_behaves_like 'it works when unquoted toplevel str allowed' do
            it_behaves_like 'obj == obj.serialize.eval.deserialize', obj: ['']
            it_behaves_like 'obj == obj.serialize.eval.deserialize', obj: ['non-blank string']
          end

          it_behaves_like 'it works when unquoted toplevel str !allowed' do
            it_behaves_like 'obj == obj.serialize.eval.deserialize', obj: ['']
            it_behaves_like 'obj == obj.serialize.eval.deserialize', obj: ['non-blank string']
          end
        end
      end

      context 'nil' do
        it_behaves_like 'it works when unquoted toplevel str allowed' do
          it { expect(serialize_eval_deserialize(nil)).to eq('') }
        end

        it_behaves_like 'it !work when unquoted toplevel str !allowed' do
          it_behaves_like 'obj.serialize.eval.deserialize RAISES err',
            obj: nil,
            err: ToplevelUnquotedStrError
        end
      end
    end

    # non-scalars are pretty stable, no need to test wrapped/unwrapped
    context 'array' do
      context 'blank' do
        it_behaves_like 'obj == obj.serialize.eval.deserialize', obj: []
      end

      context 'non blank' do
        it_behaves_like 'obj == obj.serialize.eval.deserialize', obj: [1, '2', [], {}, [3], {'4' => 5}]
      end
    end

    context 'hash' do
      context 'blank' do
        it_behaves_like 'obj == obj.serialize.eval.deserialize', obj: {}
      end

      context 'non blank' do
        it_behaves_like 'obj == obj.serialize.eval.deserialize', obj: {
          '1' => 2,
          '3' => [],
          '4' => {},
          '5' => [6],
          '7' => {'8' => 9}
        }
      end
    end
  end
end
