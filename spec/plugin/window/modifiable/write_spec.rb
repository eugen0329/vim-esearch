# frozen_string_literal: true

require 'spec_helper'

describe 'Writing in modifiable mode', :window do
  include Helpers::FileSystem
  include VimlValue::SerializationHelpers
  include Helpers::Modifiable
  include Helpers::Modifiable::Write
  Context ||= Helpers::Modifiable::Context

  include_context 'setup modifiable testing'

  let(:ctx) { Context.new('file1.txt', ['line 1', 'line 2']) }
  let(:untouched_ctx) { Context.new('file2.txt', ['untouched line 1', 'untouched line 2']) }
  let(:contexts) { [ctx, untouched_ctx] }

  after do
    expect { editor.locate_buffer! untouched_ctx.file.path }
      .to raise_error(Editor::MissingBufferError)
  end

  describe 'write files deleted after search' do
    context 'when the file is deleted' do
      it 'fails wriing' do
        ctx.entries[0].locate!
        editor.send_keys 'dd'
        ctx.file.unlink
        editor.bwipeout(ctx.file.path.to_s)
        expect { write_with_confirmation }
          .to not_change { untouched_ctx.file.readlines }
        expect(File.exist?(ctx.file.path)).not_to eq(true)
      end
    end
  end

  describe 'write into files modified after search' do
    context 'when changed on modified lines' do
      shared_examples "it doesn't write changes" do |motion:|
        let(:modified_file_lines) { ['modified'] * 10 }

        it "opens, but doesn't modify buffer" do
          ctx.entries[0].locate!
          motion.call
          ctx.file.write_content(modified_file_lines)
          expect { write_with_confirmation }
            .to not_change { untouched_ctx.file.readlines }

          editor.locate_buffer! ctx.file.path
          expect(editor.lines.to_a).to eq(modified_file_lines)
          expect(editor).not_to be_modified
        end
      end

      context 'when deleting a ctx' do
        it_behaves_like "it doesn't write changes",
          motion: -> { editor.send_keys 'dip' }
      end

      context 'when deleting a line' do
        it_behaves_like "it doesn't write changes",
          motion: -> { editor.send_keys 'dd' }

      end

      context 'when changing a ctx' do
        it_behaves_like "it doesn't write changes",
          motion: -> { editor.send_keys 'Azzz', :escape }
      end
    end

    context 'when changed anywhere except modified lines' do
      shared_examples 'it modifies buffer' do |motion:, expected_lines:|
        let(:added_lines) { ['modified'] * 10 }
        let!(:modified_file_lines) { ctx.content + added_lines }

        it 'modifies buffer' do
          ctx.entries[0].locate!
          motion.call
          ctx.file.write_content(modified_file_lines)
          expect { write_with_confirmation }
            .to not_change { untouched_ctx.file.readlines }

          editor.locate_buffer! ctx.file.path
          expect(editor.lines.to_a).to eq(instance_exec(&expected_lines))
          expect(editor).to be_modified
        end
      end

      context 'when deleting a ctx' do
        it_behaves_like 'it modifies buffer',
          motion:         -> { editor.send_keys 'dip' },
          expected_lines: -> { added_lines }
      end

      context 'when deleting a line' do
        it_behaves_like 'it modifies buffer',
          motion:         -> { editor.send_keys 'dd' },
          expected_lines: -> { ctx.content[1..] + added_lines }

      end

      context 'when changing a ctx' do
        it_behaves_like 'it modifies buffer',
          motion:         -> { editor.send_keys 'Azzz', :escape },
          expected_lines: -> { [ctx.content[0] + 'zzz'] + ctx.content[1..] + added_lines }
      end
    end
  end

  describe 'write into files without changes after search' do
    shared_examples 'it modifies buffer' do |motion:, expected_lines:|
      it 'modifies buffer' do
        ctx.entries[0].locate!
        motion.call
        expect { write_with_confirmation }
          .to not_change { untouched_ctx.file.readlines }

        editor.locate_buffer! ctx.file.path
        expect(editor.lines.to_a).to eq(instance_exec(&expected_lines))
        expect(editor).to be_modified
      end
    end

    context 'when deleting a ctx' do
      it_behaves_like 'it modifies buffer',
        motion:         -> { editor.send_keys 'dip' },
        expected_lines: -> { [''] }
    end

    context 'when deleting a line' do
      it_behaves_like 'it modifies buffer',
        motion:         -> { editor.send_keys 'dd' },
        expected_lines: -> { ctx.content[1..] }

    end

    context 'when changing a ctx' do
      it_behaves_like 'it modifies buffer',
        motion:         -> { editor.send_keys 'Azzz', :escape },
        expected_lines: -> { [ctx.content[0] + 'zzz'] + ctx.content[1..] }
    end
  end
end
