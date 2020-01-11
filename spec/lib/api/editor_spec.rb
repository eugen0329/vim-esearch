# frozen_string_literal: true

require 'spec_helper'

describe API::Editor, :editor do
  include Helpers::FileSystem

  describe 'reading with echo' do
    let(:editor) { API::Editor.new(method(:vim), cache_enabled: true) }
    let(:filename) { 'file.txt' }
    let!(:test_directory) { directory([file("a\nb", filename)]).persist! }

    before do
      editor.cd! test_directory
      editor.edit! filename
    end

    context 'array' do
      it do
        expect(vim).to receive(:echo).once.and_call_original
        expect([editor.line(1), editor.line(2)]).to eq(%w[a b])
      end
    end

    context 'when caching is enabled' do
      context 'when batches are identical' do
        it 'fetches values once' do
          expect(vim).to receive(:echo).once.and_call_original

          expect([editor.line(1), editor.line(2)]).to eq(%w[a b])
          expect([editor.line(1), editor.line(2)]).to eq(%w[a b])
        end
      end

      context 'when the last batch is smaller' do
        it 'fetches values once' do
          expect(vim).to receive(:echo).once.and_call_original

          expect([editor.line(1), editor.line(2)]).to eq(%w[a b])
          expect(editor.line(2)).to eq('b')
        end
      end

      context 'when the first batch is smaller' do
        it 'fetches only missing values' do
          expect(vim).to receive(:echo).once.with('[getline(1)]').and_call_original
          expect(editor.line(1)).to eq('a')

          expect(vim).to receive(:echo).once.with('[getline(2)]').and_call_original
          expect([editor.line(1), editor.line(2)]).to eq(%w[a b])
        end
      end
    end

    context 'when caching is disabled' do
      let(:editor) { API::Editor.new(method(:vim), cache_enabled: false) }

      before do
        editor.cd! test_directory
        editor.edit! filename
      end

      context 'when batches are identical' do
        it 'fetches ignoring caching' do
          expect(vim).to receive(:echo).twice.with('[getline(1),getline(2)]').and_call_original

          expect([editor.line(1), editor.line(2)]).to eq(%w[a b])
          expect([editor.line(1), editor.line(2)]).to eq(%w[a b])
        end
      end

      context 'when the last batch is smaller' do
        it 'fetches ignoring caching' do
          expect(vim).to receive(:echo).once.with('[getline(1),getline(2)]').and_call_original
          expect([editor.line(1), editor.line(2)]).to eq(%w[a b])

          expect(vim).to receive(:echo).once.with('[getline(2)]').and_call_original
          expect(editor.line(2)).to eq('b')
        end
      end

      context 'when the first batch is smaller' do
        it 'fetches ignoring caching' do
          expect(vim).to receive(:echo).once.with('[getline(1)]').and_call_original
          expect(editor.line(1)).to eq('a')

          expect(vim).to receive(:echo).once.with('[getline(1),getline(2)]').and_call_original
          expect([editor.line(1), editor.line(2)]).to eq(%w[a b])
        end
      end
    end
  end
end
