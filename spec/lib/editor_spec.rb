# frozen_string_literal: true

require 'spec_helper'

describe Editor, :editor do
  include Helpers::FileSystem
  include VimlValue::SerializationHelpers

  let(:test_lines) { %w[a b c d] }
  let(:test_file) { file(test_lines, 'file.txt') }
  let!(:test_directory) { directory([test_file]).persist! }
  let(:cache_enabled) { false }
  let(:editor) { described_class.new(method(:vim), cache_enabled: cache_enabled) }

  before { editor.edit! test_file.path }

  shared_examples 'it works with reader' do |reader_class|
    let(:reader) { reader_class.new(method(:vim), cache_enabled) }
    let(:editor) { described_class.new(method(:vim), reader: reader, cache_enabled: cache_enabled) }

    describe '#current_buffer_name' do
      it { expect(editor.current_buffer_name).to eq(test_file.path.to_s) }
    end

    describe '#matches_for' do
      before do
        editor.press! 'Opattern1'
        editor.command! <<~VIML
          hi Matchgroup1 ctermfg=red
          hi Matchgroup2 ctermfg=red
          call matchadd('Matchgroup1', 'pattern1')
          call matchadd('Matchgroup2', 'pattern2')
        VIML
      end
      after { editor.press! 'u' }

      it do
        expect(editor.matches_for('Matchgroup1')).to eq([[1, 1, 1 + 'pattern1'.length]])
        expect(editor.matches_for('Matchgroup2')).to be_empty
      end
    end

    describe '#lines' do
      context 'return value' do
        it { expect(editor.lines).to be_a(Enumerator) }
        it { expect(editor.lines {}).to be_nil        }
        it do
          expect { |yield_probe| editor.lines(&yield_probe) }
            .to yield_successive_args(*test_lines)
        end
      end

      context 'range argument' do
        it { expect(editor.lines(1..).to_a).to                     eq(test_lines)         }
        it { expect(editor.lines(1..1).to_a).to                    eq([test_lines.first]) }
        it { expect(editor.lines(1..test_lines.count).to_a).to     eq(test_lines)         }
        it { expect(editor.lines(2..test_lines.count).to_a).to     eq(test_lines[1..])    }
        it { expect(editor.lines(2..test_lines.count - 1).to_a).to eq(test_lines[1..-2])  }
        it { expect(editor.lines(test_lines.count + 1..).to_a).to  eq([])                 }
        it { expect(editor.lines(test_lines.count..).to_a).to      eq([test_lines.last])  }

        it { expect { editor.lines(0..0).to_a   }.to raise_error(ArgumentError) }
        it { expect { editor.lines(0..1).to_a   }.to raise_error(ArgumentError) }
        it { expect { editor.lines(1..0).to_a   }.to raise_error(ArgumentError) }
        it { expect { editor.lines(2..1).to_a   }.to raise_error(ArgumentError) }
        it { expect { editor.lines(-1..2).to_a  }.to raise_error(ArgumentError) }
        it { expect { editor.lines(-2..-1).to_a }.to raise_error(ArgumentError) }
      end
    end
  end

  shared_examples 'it optimizes #lines with prefetching in blocks' do
    context 'when prefetch_count: 1' do
      let(:prefetch_count) { 1 }

      it do
        expect(vim).to receive(:echo).exactly(test_lines.count).and_call_original
        expect(editor.lines(prefetch_count: prefetch_count).to_a).to eq(test_lines)
      end
    end

    context 'when prefetch_count: >1' do
      let(:prefetch_count) { 2 }

      subject { editor.lines(prefetch_count: prefetch_count) }
      before { expect(test_lines.count).to eq(prefetch_count * 2) } # verify the setup

      it 'yields each line using prefetching' do
        expect(vim).to receive(:echo).once.and_call_original
        expect(subject.next).to eq(test_lines[0])
        expect(subject.next).to eq(test_lines[1])

        expect(vim).to receive(:echo).once.and_call_original
        expect(subject.next).to eq(test_lines[2])
        expect(subject.next).to eq(test_lines[3])

        expect { subject.next }.to raise_error(StopIteration)
      end
    end

    context 'when lines.count is not a multiple of prefetch_count' do
      let(:prefetch_blocks_count) { 2 }
      let(:prefetch_count) { test_lines.count / prefetch_blocks_count + 1 }
      before { expect(test_lines.count / prefetch_count).not_to eq(0) } # verify the setup

      it do
        expect(vim)
          .to receive(:echo)
          .exactly((test_lines.count / prefetch_blocks_count).to_i)
          .and_call_original

        expect(editor.lines(prefetch_count: prefetch_count).to_a).to eq(test_lines)
      end
    end

    context 'invalid prefetch_count' do
      it { expect { editor.lines(prefetch_count: -1) }.to raise_error(ArgumentError) }
      it { expect { editor.lines(prefetch_count: 0) }.to  raise_error(ArgumentError) }
    end
  end

  context 'vim', :vim do
    context 'when reader == Editor::Read::Eager' do
      include_examples 'it works with reader', Editor::Read::Eager
    end

    context 'when reader == Editor::Read::Batched' do
      include_examples 'it works with reader', Editor::Read::Batched do
        it_behaves_like 'it optimizes #lines with prefetching in blocks'
      end
    end
  end

  context 'neovim', :neovim do
    around  { |e| use_nvim(&e) }

    context 'when reader == Editor::Read::Eager' do
      include_examples 'it works with reader', Editor::Read::Eager
    end

    context 'when reader == Editor::Read::Batched' do
      include_examples 'it works with reader', Editor::Read::Batched do
        it_behaves_like 'it optimizes #lines with prefetching in blocks'
      end
    end
  end
end
