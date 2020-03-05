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
  let(:files) { [file("1111\n2222", 'insert_fixture.txt')] }
  let!(:search_directory) { directory(files).persist! }

  before do
    editor.edit! files.first
    editor.echo func('esearch#changes#listen_for_current_buffer')
  end

  describe 'add below' do
    context 'when inserting single' do
      it do
        editor.locate_line! 1
        editor.send_keys_separately 'o'
        expect(editor.lines.to_a).to eq(['1111', '', '2222'])
        expect(event).to include_payload('insert-enter-o', 2.., 2..)
      end
    end

    context 'when inserting multiple' do
      it do
        editor.locate_line! 1
        editor.send_keys_separately '2o', 'zz'
        expect(editor.lines.to_a).to eq(%w[1111 zz 2222])
        editor.send_keys_separately :escape
        expect(editor.lines.to_a).to eq(%w[1111 zz zz 2222])
        expect(event).to include_payload('insert-leave-o', 2.., 3..)
      end
    end
  end

  describe 'add above' do
    context 'when inserting single' do
      it do
        editor.locate_line! 1
        editor.send_keys_separately 'O'
        expect(editor.lines.to_a).to eq(['', '1111', '2222'])
        expect(event).to include_payload('insert-enter-o', 1.., 1..)
      end
    end

    context 'when inserting multiple' do
      it do
        editor.locate_line! 1
        editor.send_keys_separately '2O', 'zz'
        expect(editor.lines.to_a).to eq(%w[zz 1111 2222])
        editor.send_keys_separately :escape
        expect(editor.lines.to_a).to eq(%w[zz zz 1111 2222])
        expect(event).to include_payload('insert-leave-o', 1.., 2..)
      end
    end
  end
end
