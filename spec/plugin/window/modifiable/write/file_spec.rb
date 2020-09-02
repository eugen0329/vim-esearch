# frozen_string_literal: true

require 'spec_helper'

describe 'Writing in modifiable mode', :window do
  include Helpers::FileSystem
  include VimlValue::SerializationHelpers
  include Helpers::Modifiable
  Context ||= Helpers::Modifiable::Context

  include_context 'setup modifiable testing'

  let(:writer) { 'file' }
  let(:ctx) { Context.new('filename with whitespaces.txt', ['line 1', 'line 2']) }
  let(:untouched_ctx) { Context.new('untouched filename.txt', ['untouched line 1', 'untouched line 2']) }
  let(:contexts) { [ctx, untouched_ctx] }

  after do
    expect { editor.enter_buffer! untouched_ctx.file.path }
      .to raise_error(Editor::MissingBufferError)
  end

  describe 'write files deleted after search' do
    context 'when the file is deleted' do
      it 'fails wriing' do
        ctx.entries[0].locate!
        expect do
          ctx.file.unlink
          editor.send_keys_separately 'dd', ':write', :enter, 'y'
          expect(esearch).to have_output_message("Can't write changes")
        end.to change { ctx.file.path.exist? }
          .to(false)
          .and not_to_change { untouched_ctx.file.readlines }
      end
    end
  end

  describe 'write into files modified after search' do
    context 'when changed on modified lines' do
      let(:modified_file_lines) { ['modified'] * 10 }
      before { ctx.file.write_content(modified_file_lines) }

      context 'when deleting a ctx' do
        it 'modifies buffer' do
          ctx.entries[0].locate!
          expect do
            editor.send_keys_separately 'dip', ':write', :enter, 'y'
            expect(esearch).to have_output_message("Can't write changes")
          end.to not_change { ctx.file.readlines }
            .and not_to_change { untouched_ctx.file.readlines }
        end
      end

      context 'when deleting a line' do
        it 'modifies buffer' do
          ctx.entries[0].locate!
          expect do
            editor.send_keys_separately 'dd', ':write', :enter, 'y'
            expect(esearch).to have_output_message("Can't write changes")
          end.to not_change { ctx.file.readlines }
            .and not_to_change { untouched_ctx.file.readlines }
        end
      end

      context 'when changing a ctx' do
        it 'modifies buffer' do
          ctx.entries[0].locate!
          expect do
            editor.send_keys_separately 'Azzz', :escape, ':write', :enter, 'y'
            expect(esearch).to have_output_message("Can't write changes")
          end.to not_change { ctx.file.readlines }
            .and not_to_change { untouched_ctx.file.readlines }
        end
      end
    end

    context 'when changed anywhere except modified lines' do
      let(:added_lines) { ['modified'] * 10 }
      let!(:modified_file_lines) { ctx.content + added_lines }
      before { ctx.file.write_content(modified_file_lines) }

      context 'when deleting a ctx' do
        it 'modifies buffer' do
          ctx.entries[0].locate!
          expect do
            editor.send_keys_separately 'dip', ':write', :enter, 'y'
            expect(esearch).to have_output_message('Done')
          end.to change { ctx.file.readlines }
            .to(added_lines.map { |text| text + "\n" })
            .and not_to_change { untouched_ctx.file.readlines }
        end
      end

      context 'when deleting a line' do
        it 'modifies buffer' do
          ctx.entries[0].locate!
          expect do
            editor.send_keys_separately 'dd', ':write', :enter, 'y'
            expect(esearch).to have_output_message('Done')
          end.to change { ctx.file.readlines }
            .to(["line 2\n"] + added_lines.map { |text| text + "\n" })
            .and not_to_change { untouched_ctx.file.readlines }
        end
      end

      context 'when changing a ctx' do
        it 'modifies buffer' do
          ctx.entries[0].locate!
          expect do
            editor.send_keys_separately 'Azzz', :escape, ':write', :enter, 'y'
            expect(esearch).to have_output_message('Done')
          end.to change { ctx.file.readlines }
            .to(["line 1zzz\n", "line 2\n"] + added_lines.map { |text| text + "\n" })
            .and not_to_change { untouched_ctx.file.readlines }
        end
      end
    end
  end

  describe 'write into files without changes after search' do
    context 'when deleting a ctx' do
      it 'modifies buffer' do
        ctx.entries[0].locate!
        expect do
          editor.send_keys_separately 'dip', ':write', :enter, 'y'
          expect(esearch).to have_output_message('Done')
        end.to change { ctx.file.readlines }
          .to([])
          .and not_to_change { untouched_ctx.file.readlines }
      end
    end

    context 'when deleting a line' do
      it 'modifies buffer' do
        ctx.entries[0].locate!
        expect do
          editor.send_keys_separately 'dd', ':write', :enter, 'y'
          expect(esearch).to have_output_message('Done')
        end.to change { ctx.file.readlines }
          .to(["line 2\n"])
          .and not_to_change { untouched_ctx.file.readlines }
      end
    end

    context 'when changing a ctx' do
      it 'modifies buffer' do
        ctx.entries[0].locate!
        expect do
          editor.send_keys_separately 'Azzz', :escape, ':write', :enter, 'y'
          expect(esearch).to have_output_message('Done')
        end.to change { ctx.file.readlines }
          .to(["line 1zzz\n", "line 2\n"])
          .and not_to_change { untouched_ctx.file.readlines }
      end
    end
  end
end
