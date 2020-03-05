# frozen_string_literal: true

require 'spec_helper'

describe 'Add newline' do
  include VimlValue::SerializationHelpers
  include Helpers::ReportEditorStateOnError
  include Helpers::Changes
  include Helpers::FileSystem

  include_context 'report editor messages on error'

  around do |e|
    editor.with_ignore_cache(&e)
    editor.cleanup!
    vim.normal
  end

  let(:event) { editor.echo(var('b:__events[-1]')) }
  let(:files) { [file("1111\n2222\n3333", 'insert_fixture.txt')] }
  let!(:search_directory) { directory(files).persist! }

  before do
    editor.edit! files.first
    editor.echo func('esearch#changes#listen_for_current_buffer')
  end

  describe 'leaving insert' do
    context 'when after change' do
      context 'when leaving with <C-c>' do
        it "doesn't emit insert leave event" do
          editor.locate_cursor! 1, 2
          editor.send_keys_separately '\\<C-v>'
          editor.locate_cursor! 3, 3
          editor.send_keys_separately 's', 'zz', '\\<C-c>'
          expect(editor.lines.to_a).to eq(%w[1zz1 2zz2 3zz3])
          expect(event['id']).not_to eq('insert-leave-blockwise-visual')
        end
      end

      context 'when leaving with escape' do
        it 'emits insert leave event' do
          editor.locate_cursor! 1, 2
          editor.send_keys_separately '\\<C-v>'
          editor.locate_cursor! 3, 3
          editor.send_keys_separately 's', 'zz', :escape
          expect(editor.lines.to_a).to eq(%w[1zz1 2zz2 3zz3])
          expect(event).to include_payload('insert-leave-blockwise-visual', 1..2, 3..3)
        end
      end
    end

    context 'when after starting insert without modification' do
      context 'when at the block begin (I)' do
        it 'emits insert leave event' do
          editor.locate_cursor! 1, 2
          editor.send_keys_separately '\\<C-v>'
          editor.locate_cursor! 3, 4
          editor.send_keys_separately 'I', 'zz', :escape
          expect(editor.lines.to_a).to eq(%w[1zz111 2zz222 3zz333])
          expect(event).to include_payload('insert-leave-blockwise-visual', 1..2, 3..4)
        end
      end

      context 'when at the lines end (A)' do
        it 'emits insert leave event' do
          editor.locate_cursor! 1, 2
          editor.send_keys_separately '\\<C-v>'
          editor.locate_cursor! 3, 4
          editor.send_keys_separately 'A', 'zz', :escape
          expect(editor.lines.to_a).to eq(%w[1111zz 2222zz 3333zz])
          expect(event).to include_payload('insert-leave-blockwise-visual', 1..2, 3..4)
        end
      end
    end
  end

  context 'delete' do
    context 'when moving down' do
      it 'emits with normalized coordinates' do
        editor.locate_cursor! 1, 4
        editor.send_keys_separately '\\<C-v>'
        editor.locate_cursor! 3, 2
        editor.send_keys_separately 'x'
        expect(editor.lines.to_a).to eq(%w[1 2 3])
        expect(event).to include_payload('blockwise-visual', 1..2, 3..4)
      end

      it 'emits with normalized coordinates' do
        editor.locate_cursor! 1, 2
        editor.send_keys_separately '\\<C-v>'
        editor.locate_cursor! 3, 4
        editor.send_keys_separately 'x'
        expect(editor.lines.to_a).to eq(%w[1 2 3])
        expect(event).to include_payload('blockwise-visual', 1..2, 3..4)
      end
    end

    context 'when moving up' do
      it 'emits with normalized coordinates' do
        editor.locate_cursor! 3, 4
        editor.send_keys_separately '\\<C-v>'
        editor.locate_cursor! 1, 2
        editor.send_keys_separately 'x'
        expect(editor.lines.to_a).to eq(%w[1 2 3])
        expect(event).to include_payload('blockwise-visual', 1..2, 3..4)
      end
    end
  end
end
