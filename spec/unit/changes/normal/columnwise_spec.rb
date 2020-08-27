# frozen_string_literal: true

require 'spec_helper'

describe 'changes reporting in NORMAL mode' do
  include Helpers::Vim
  include VimlValue::SerializationHelpers
  include Helpers::ReportEditorStateOnError
  include Helpers::Changes

  include_context 'report editor messages on error'

  around do |e|
    editor.with_ignore_cache(&e)
    editor.command! 'undo 1 | undo'
  end

  let(:event) { editor.echo(var('b:__events[-1]')) }

  shared_context 'setup multiline testing' do
    before do
      vim.insert "aa bb cc\ndd ee ff\n\ngg hh ii"
      vim.normal
      editor.echo func('esearch#changes#listen_for_current_buffer')
    end
  end

  # TODO: testing with autoindent
  # TODO rework pasting coordinates detection

  context 'delete' do
    include_context 'setup multiline testing'

    context 'columnwise start' do
      context 'columwise end (F{char} motion)' do
        include_context 'setup clever-f testing'

        context 'line2 < $' do
          it 'col1 == col2' do
            editor.locate_cursor! 2, 5

            editor.send_keys_separately 'dFb'
            expect(editor.lines.to_a).to eq(['aa be ff', '', 'gg hh ii'])
            expect(event).to include_payload('n-motion-up-columnwise-left1', 1..5, 2..5)
          end

          it 'col1 < col2' do
            editor.locate_cursor! 2, 5

            editor.send_keys_separately 'dFa'
            expect(editor.lines.to_a).to eq(['ae ff', '', 'gg hh ii'])
            expect(event).to include_payload('n-motion-up-columnwise-left1', 1..2, 2..5)
          end

          it 'col1 > col2' do
            editor.locate_cursor! 2, 5

            editor.send_keys_separately 'dFc'
            expect(editor.lines.to_a).to eq(['aa bb ce ff', '', 'gg hh ii'])
            expect(event).to include_payload('n-motion-up-columnwise-left1', 1..8, 2..5)
          end
        end

        context 'line2 == $' do
          it 'col1 == col2' do
            editor.locate_cursor! 4, 5

            editor.send_keys_separately 'dFb'
            expect(editor.lines.to_a).to eq(['aa bh ii'])
            expect(event).to include_payload('n-motion-up-columnwise-left2', 1..5, 4..5)
          end

          it 'col1 < col2' do
            editor.locate_cursor! 4, 5

            editor.send_keys_separately 'dFa'
            expect(editor.lines.to_a).to eq(['ah ii'])
            expect(event).to include_payload('n-motion-up-columnwise-left2', 1..2, 4..5)
          end

          it 'col1 > col2' do
            editor.locate_cursor! 4, 5

            editor.send_keys_separately 'dFc'
            expect(editor.lines.to_a).to eq(['aa bb ch ii'])
            expect(event).to include_payload('n-motion-up-columnwise-left2', 1..8, 4..5)
          end
        end

      end
    end

    context 'columnwise start' do
      context 'linewise end (paragraph textobject)' do
        shared_context 'paragraph examples' do |**options|
          include_context 'set options', **options

          it '1 < col1 < $' do
            editor.locate_cursor! 1, 5
            editor.send_keys_separately 'd}'
            expect(editor.lines.to_a).to eq(['aa b', '', 'gg hh ii'])
            expect(event).to include_payload('n-motion-down-columnwise-right1', 1..5, 2..)
          end

          it 'col1 == $' do
            editor.locate_cursor! 1, '$'
            editor.send_keys_separately 'd}'
            expect(editor.lines.to_a).to eq(['aa bb c', '', 'gg hh ii'])
            expect(event).to include_payload('n-motion-down-columnwise-right1', 1..8, 2..)
          end

          it 'col1 == 1' do
            editor.locate_cursor! 1, 1
            editor.send_keys_separately 'd}'
            expect(editor.lines.to_a).to eq(['', 'gg hh ii'])
            expect(event).to include_payload('n-motion-down4', 1.., 2..)
          end
        end

        include_context 'paragraph examples', {virtualedit: 'onemore'}
        include_context 'paragraph examples', {virtualedit: ''}
      end

      context 'columnwise end (multiline f{char})' do
        include_context 'setup clever-f testing'

        shared_examples 'multiline f{char} examples' do |**options|
          include_context 'set options', **options

          it 'col1 == 1' do
            editor.locate_cursor! 1, 1
            editor.send_keys_separately 'dff'
            expect(editor.lines.to_a).to eq(['f', '', 'gg hh ii'])
            expect(event).to include_payload('n-motion-down-columnwise-right2', 1..1, 2..7)
          end

          it 'col1 == col2' do
            editor.locate_cursor! 1, 5
            editor.send_keys_separately 'dfe'
            expect(editor.lines.to_a).to eq(['aa be ff', '', 'gg hh ii'])
            expect(event).to include_payload('n-motion-down-columnwise-right2', 1..5, 2..4)
          end

          it 'col1 < col2' do
            editor.locate_cursor! 1, 5
            editor.send_keys_separately 'dff'
            expect(editor.lines.to_a).to eq(['aa bf', '', 'gg hh ii'])
            expect(event).to include_payload('n-motion-down-columnwise-right2', 1..5, 2..7)
          end

          it 'col1 > col2' do
            editor.locate_cursor! 1, 5
            editor.send_keys_separately 'dfd'
            expect(editor.lines.to_a).to eq(['aa bd ee ff', '', 'gg hh ii'])
            expect(event).to include_payload('n-motion-down-columnwise-right2', 1..5, 2..1)
          end

        end

        context 'when virtualedit == onemore' do
          include_context 'multiline f{char} examples', {virtualedit: 'onemore'}
        end

        context 'when virtualedit is disabled' do
          include_context 'multiline f{char} examples', {virtualedit: ''}
        end
      end
    end
  end
end
