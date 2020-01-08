# frozen_string_literal: true

require 'spec_helper'

# TODO: split and refactor
describe API::Editor, :editor do
  include Helpers::FileSystem

  let(:editor) { API::Editor.new(method(:vim)) }

  describe 'batch echo' do
    context 'array' do
      let(:filename) { 'file.txt' }
      let!(:test_directory) { directory([file("a\nb", filename)]).persist! }
      before do
        editor.cd! test_directory
        editor.edit! filename
      end

      it do
        expect(vim).to receive(:echo).once.and_call_original
        expect(editor.echo { |e| [e.line(1), e.line(2)] }).to eq(%w[a b])
      end
    end

    context 'when caching' do
      # TODO: test for #with_ignore_cache and #cache_enabled
      context 'when enabled' do
        let(:filename) { 'file.txt' }
        let!(:test_directory) { directory([file("a\nb", filename)]).persist! }
        before do
          editor.cd! test_directory
          editor.edit! filename
        end

        it do
          expect(vim).to receive(:echo).once.and_call_original

          expect(editor.echo { |e| [e.line(1), e.line(2)] }).to eq(%w[a b])
          expect(editor.line(2)).to eq('b')
        end

        it do
          expect(vim).to receive(:echo).once.and_call_original

          expect(editor.echo { |e| [e.line(1), e.line(2)] }).to eq(%w[a b])
          expect(editor.echo { |e| [e.line(1), e.line(2)] }).to eq(%w[a b])
        end

        it do
          expect(vim).to receive(:echo).once.with('[getline(1)]').and_call_original
          expect(vim).to receive(:echo).once.with('[getline(2)]').and_call_original

          expect(editor.line(1)).to eq('a')
          expect(editor.echo { |e| [e.line(1), e.line(2)] }).to eq(%w[a b])
        end
      end
    end
  end

  def ph(index, id)
    API::Editor::Read::Batch::Placeholder.new(index, id)
  end

  def id(str)
    API::Editor::Serialization::Identifier.new(str)
  end

  describe API::Editor::Read::Batch do
    subject { described_class.new(editor, method(:vim), true) }
    let(:filename) { 'file.txt' }
    let!(:test_directory) { directory([file("a\nb", filename)]).persist! }
    let(:e) { editor }

    before do
      editor.cd! test_directory
      editor.edit! filename
    end

    let(:id1) { id(1) }
    let(:id2) { id(2) }
    let(:ph0) { ph(0, id1) }
    let(:ph1) { ph(1, id2) }
    context 'construct' do
      context 'scalar' do
        context 'var' do
          let(:result) { subject.construct(e.var(1)) }

          it { expect(result).to eq([ph0, [id1]]) }
        end

        context 'value' do
          let(:result) { subject.construct(4) }

          it { expect(result).to eq([4, []]) }
        end
      end

      context '1d array' do
        let(:result) { subject.construct([e.var(1), e.var(2), 3, '4']) }

        it { expect(result).to eq([[ph0, ph1, 3, '4'], [id1, id2]]) }
      end

      context 'nested array' do
        let(:result) { subject.construct([e.var(1), [e.var(2), 3, '4']]) }

        it { expect(result).to eq([[ph0, [ph1, 3, '4']], [id1, id2]]) }
      end

      context '1d hash' do
        let(:result) { subject.construct(a: e.var(1), b: e.var(2), c: 3, d: 4) }

        it { expect(result).to eq([{ a: ph0, b: ph1, c: 3, d: 4 }, [id1, id2]]) }
      end

      context 'nested hash' do
        let(:result) { subject.construct(a: e.var(1), b: { c: e.var(2), d: 3, e: 4 }) }

        it { expect(result).to eq([{ a: ph0, b: { c: ph1, d: 3, e: 4 } }, [id1, id2]]) }
      end
    end

    context 'reconstruct' do
      let(:result) { subject.reconstruct(shape, evaluated_batch) }
      let(:evaluated_batch) { [11, 22] }

      context 'nested hash' do
        let(:shape) { { a: ph0, b: { c: ph1, d: 3, e: 4 } } }

        it do
          expect(result).to eq(a: 11, b: { c: 22, d: 3, e: 4 })
        end
      end

      context 'nested array' do
        let(:shape) { [ph0, [ph1, 3, '4']] }

        it do
          expect(result).to eq([11, [22, 3, '4']])
        end
      end

      context 'scalar' do
        context 'var' do
          let(:evaluated_batch) { [11] }
          let(:shape) { ph0 }

          it { expect(result).to eq(11) }
        end

        context 'value' do
          let(:evaluated_batch) { [] }
          let(:shape) { nil }

          it { expect(result).to eq(result) }
        end
      end
    end
  end

  describe 'serialization' do
    let(:serializer) { API::Editor::Serialization::Serializer.new }
    let(:deserializer) { API::Editor::Serialization::Deserializer.new }

    subject do
      deserializer.deserialize(editor.raw_echo(serializer.serialize(original_object)))
    end

    context 'blank array' do
      let(:original_object) { [] }
      it { is_expected.to eq(original_object) }
    end

    context 'blank hash' do
      let(:original_object) { {} }
      it { is_expected.to eq(original_object) }
    end

    context 'nil' do
      let(:original_object) { nil }
      it { is_expected.to eq('') }
    end

    context 'blank_string' do
      let(:original_object) { '' }
      it { is_expected.to eq(original_object) }
    end

    context 'full array' do
      let(:original_object) { [1, '2', [], {}, [3], { '4' => 5 }] }
      it { is_expected.to eq(original_object) }
    end

    context 'full hash' do
      let(:original_object) do
        {
          '1' => 2,
          '3' => [],
          '4' => {},
          '5' => [6],
          '7' => {
            '8' => 9
          }
        }
      end
      it { is_expected.to eq(original_object) }
    end
  end
end
