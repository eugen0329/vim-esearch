# frozen_string_literal: true

require 'spec_helper'

describe Editor, :editor do
  include Helpers::FileSystem
  include VimlValue::SerializationHelpers

  let(:cache_enabled) { false }
  let(:reader) { Editor::Read::Batched.new(method(:vim), cache_enabled) }

  describe '#echo' do
    def abs(numeric)
      reader.echo func('abs', numeric)
    end

    context 'when cache_enabled: true' do
      let(:cache_enabled) { true }

      context 'when batches are identical' do
        it 'fetches values once' do
          expect(vim).to receive(:echo).once.and_call_original

          expect([abs(-1), abs(-2)]).to eq([1, 2])
          expect([abs(-1), abs(-2)]).to eq([1, 2])
        end
      end

      context 'when the last batch is smaller' do
        it 'fetches values once' do
          expect(vim).to receive(:echo).once.and_call_original

          expect([abs(-1), abs(-2)]).to eq([1, 2])
          expect(abs(-2)).to eq(2)
        end
      end

      context 'when the first batch is smaller' do
        it 'fetches only missing values' do
          expect(vim).to receive(:echo).once.with('[abs(-1)]').and_call_original
          expect(abs(-1)).to eq(1)

          expect(vim).to receive(:echo).once.with('[abs(-2)]').and_call_original
          expect([abs(-1), abs(-2)]).to eq([1, 2])
        end
      end
    end

    context 'when cache_enabled: false' do
      let(:cache_enabled) { false }

      context 'when batches are identical' do
        it 'fetches ignoring caching' do
          expect(vim).to receive(:echo).twice.with('[abs(-1),abs(-2)]').and_call_original

          expect([abs(-1), abs(-2)]).to eq([1, 2])
          expect([abs(-1), abs(-2)]).to eq([1, 2])
        end
      end

      context 'when the last batch is smaller' do
        it 'fetches ignoring caching' do
          expect(vim).to receive(:echo).once.with('[abs(-1),abs(-2)]').and_call_original
          expect([abs(-1), abs(-2)]).to eq([1, 2])

          expect(vim).to receive(:echo).once.with('[abs(-2)]').and_call_original
          expect(abs(-2)).to eq(2)
        end
      end

      context 'when the first batch is smaller' do
        it 'fetches ignoring caching' do
          expect(vim).to receive(:echo).once.with('[abs(-1)]').and_call_original
          expect(abs(-1)).to eq(1)

          expect(vim).to receive(:echo).once.with('[abs(-1),abs(-2)]').and_call_original
          expect([abs(-1), abs(-2)]).to eq([1, 2])
        end
      end
    end

    describe 'errors' do
      it { expect { reader.echo(func('undefined')).to_s }.to raise_error(Editor::Read::Base::ReadError) }
      it { expect { reader.echo(func('Undefined')).to_s }.to raise_error(Editor::Read::Base::ReadError) }
      it { expect { reader.echo(var('undefined')).to_s }.to  raise_error(Editor::Read::Base::ReadError) }
    end
  end
end
