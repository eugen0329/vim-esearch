# frozen_string_literal: true

require 'spec_helper'

describe 'INSERT mode' do
  include VimlValue::SerializationHelpers
  include Helpers::ReportEditorStateOnError
  include Helpers::Changes
  include Helpers::FileSystem

  include_context 'report editor messages on error'

  around do |e|
    editor.with_ignore_cache(&e)
    editor.cleanup!
  end

  let(:event) { editor.echo(var('b:__changes[-1]')) }
  let(:files) { [file("1\naa bc dd", 'inser_fixture.txt')] }
  let!(:search_directory) { directory(files).persist! }

  before do
    editor.edit! files.first
    editor.echo func('esearch#changes#listen_for_current_buffer')
    editor.command! 'set backspace=indent,eol,start'
  end

  context '1 char' do
    context 'add' do
      it 'reports adding a single char' do
        editor.locate_cursor! 2, 4
        editor.send_keys_separately 'i', 'g'
        expect(editor.lines.to_a).to eq(['1', 'aa gbc dd'])
        expect(event).to include_payload('i-inline-add', 2..4, 2..4)
      end
    end

    context 'delete' do
      it 'reports char delete right' do
        editor.locate_cursor! 2, 4
        editor.send_keys_separately 'i', '\\<Del>'
        expect(editor.lines.to_a).to eq(['1', 'aa c dd'])
        expect(event).to include_payload('i-inline-delete1', 2..4, 2..4)
      end

      it 'reports char delete left' do
        editor.locate_cursor! 2, 4
        editor.send_keys_separately 'i', '\\<BS>'
        expect(editor.lines.to_a).to eq(['1', 'aabc dd'])
        expect(event).to include_payload('i-inline-delete1', 2..3, 2..3)
      end
    end
  end

  context 'n > 1 chars' do
    context 'add' do
      it 'reports adding a multiple char with paste' do
        editor.locate_cursor! 2, 4
        editor.clipboard = 'gg'
        editor.send_keys_separately 'i', :paste
        expect(editor.lines.to_a).to eq(['1', 'aa ggbc dd'])
        expect(event).to include_payload('i-inline-add', 2..4, 2..5)
      end

      it 'reports adding a multiple char by a script' do
        editor.locate_cursor! 2, 4
        editor.send_keys_separately 'i', 'gg'
        expect(editor.lines.to_a).to eq(['1', 'aa ggbc dd'])
        expect(event).to include_payload('i-inline-add', 2..4, 2..5)
      end
    end

    context 'delete' do
      it 'reports deleted with CONTROL-W' do
        editor.locate_cursor! 2, 6
        editor.send_keys_separately 'i', '\\<C-w>'
        expect(editor.lines.to_a).to eq(['1', 'aa  dd'])
        expect(event).to include_payload('i-inline-delete1', 2..4, 2..5)
      end
    end
  end

  context 'newlines' do
    it 'add new line' do
      editor.locate_cursor! 2, 5
      editor.send_keys_separately 'i', :enter
      expect(editor.lines.to_a).to eq(['1', 'aa b', 'c dd'])
      expect(event).to include_payload('i-add-newline', 2..5, 3..1)
    end

    context 'delete new line left' do
      context 'previous is empty' do
        # TODO
      end

      context 'previous is nonempty' do
        it do
          editor.locate_cursor! 2, 1
          editor.send_keys_separately 'i', :backspace
          expect(editor.lines.to_a).to eq(['1aa bc dd'])
          expect(event).to include_payload('i-delete-newline', 1..2, 2..1)
        end
      end
    end

    context 'delete new line right' do
      context 'current is empty' do
        # TODO
      end

      context "current is nonempty" do
        it do
          editor.locate_cursor! 1, 1
          editor.send_keys_separately 'A', :delete
          expect(editor.lines.to_a).to eq(['1aa bc dd'])
          expect(event).to include_payload('i-delete-newline-right', 1..2, 1..2)
        end
      end
    end
  end
end
