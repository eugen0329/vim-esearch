# frozen_string_literal: true

require 'spec_helper'

describe 'VISUAL LINE mode' do
  include VimlValue::SerializationHelpers
  include Helpers::ReportEditorStateOnError
  include Helpers::Changes
  include Helpers::FileSystem

  include_context 'report editor messages on error'

  around do |e|
    editor.with_ignore_cache(&e)
    editor.cleanup!
    editor.command! <<~RESET_VISUAL
      call setpos("'<", [0,0,0,0]) | call setpos("'>", [0,0,0,0])
    RESET_VISUAL
  end
  let(:event) { editor.echo(var('b:__changes[-1]')) }
  let(:files) { [file("11\n22\n33\n44", 'visual_line_fixuture.txt')] }
  let!(:search_directory) { directory(files).persist! }

  before do
    editor.edit! files.first
    editor.echo func('esearch#changes#listen_for_current_buffer')
  end

  context 'delete' do
    context 'moving down' do
      context 'from line 2' do
        it 'reports 1 line' do
          editor.locate_line! 2
          editor.press! 'Vx'
          expect(editor.lines.to_a).to eq(%w[11 33 44])
          expect(event)
            .to have_payload('n-motion-down2', 2.., 2..)
            .or have_payload('n-motion-up4', 2.., 2..)
        end

        # as required as far as we don't have VisualEnter hook
        it 'reports 1 line after movements (to record visual mode state)' do
          editor.locate_line! 2
          editor.press! 'Vjkx'
          expect(editor.lines.to_a).to eq(%w[11 33 44])
          expect(event).to have_payload('V-line-delete-up1', 2.., 2..)
        end

        it 'reports 2 lines' do
          editor.locate_line! 2
          editor.press! 'Vjx'
          expect(editor.lines.to_a).to eq(%w[11 44])
          expect(event).to have_payload('V-line-delete-down', 2.., 3..)
        end

        it 'reports 3 lines' do
          editor.locate_line! 2
          editor.press! 'Vjjx'
          expect(editor.lines.to_a).to eq(%w[11])
          expect(event).to have_payload('V-line-delete-up2', 2.., 4..)
        end
      end

      context 'from line 1' do
        it 'repots deleted in range 1..-1' do
          editor.locate_line! 1
          editor.press! 'VGx'
          expect(editor.lines.to_a).to eq([''])
          expect(event).to have_payload('V-line-delete-up2', 1.., 4..)
        end
      end
    end

    context 'moving up' do
      context 'from line 1' do
        it 'reports 1 line' do
          editor.locate_line! 1
          editor.press! 'Vx'
          expect(editor.lines.to_a).to eq(%w[22 33 44])
          expect(event).to have_payload('n-motion-down2', 1.., 1..)
        end

        # as required as far as we don't have VisualEnter hook
        it 'reports 1 line after movements (to record visual mode state)' do
          editor.locate_line! 1
          editor.press! 'Vjkx'
          expect(editor.lines.to_a).to eq(%w[22 33 44])
          expect(event).to have_payload('V-line-delete-up1', 1.., 1..)
        end
      end

      context 'from line -1' do
        it 'reports 3 lines' do
          editor.locate_line! 4
          editor.press! 'Vkkx'
          expect(editor.lines.to_a).to eq(%w[11])
          expect(event).to have_payload('V-line-delete-up2', 2.., 4..)
        end

        it 'reports 2 lines' do
          editor.locate_line! 4
          editor.send_keys('Vkx')
          expect(editor.lines.to_a).to eq(%w[11 22])
          expect(event).to have_payload('V-line-delete-down', 3.., 4..)
        end

        it 'rports lines 1..-1' do
          editor.locate_line! 4
          editor.press! 'Vggx'
          expect(editor.lines.to_a).to eq([''])
          expect(event).to have_payload('V-line-delete-up1', 1.., 4..)
        end
      end

      context 'from line -2' do
        it 'reports 2 lines' do
          editor.locate_line! 3
          editor.press! 'Vkx'
          expect(editor.lines.to_a).to eq(%w[11 44])
          expect(event).to have_payload('V-line-delete-up1', 2.., 3..)
        end
      end
    end
  end

  context 'paste' do
    context 'with reducing lines count' do
      context 'when moving down' do
        it 'from 1:, lines 1-2, insert 1 line' do
          editor.clipboard = 'c\n'
          editor.locate_line! 1
          editor.send_keys_separately 'V', 'jp'
          expect(editor.lines.to_a).to eq(%w[c 33 44])
          expect(event).to have_payload('V-line-reducing-paste-down', 1.., 2..)
        end
      end

      context 'when moving up' do
        context 'from line 3' do
          it 'reports 2 lines' do
            editor.clipboard = 'c\n'
            editor.locate_line! 3
            editor.press! 'Vkp'
            expect(editor.lines.to_a).to eq(%w[11 c 44])
            expect(event).to have_payload('V-line-reducing-paste-up1', 2.., 3..)
          end
        end

        context 'from line -1' do
          it 'reports 3 lines' do
            editor.clipboard = 'c\n'
            editor.locate_line! 4
            editor.press! 'Vkkp'
            expect(editor.lines.to_a).to eq(%w[11 c])
            expect(event).to have_payload('V-line-reducing-paste-up1', 2.., 4..)
          end
        end
      end
    end

    context 'replacing with the same lines count' do
      context 'when moving down' do
        context 'from line 2' do
          it 'reports 1 line' do
            editor.clipboard = 'c\n'
            editor.locate_line! 2
            editor.press! 'Vp'
            expect(editor.lines.to_a).to eq(%w[11 c 33 44])
            expect(event).to have_payload('n-inline6', 2.., 2..)
          end

          it 'reports 1 line' do
            editor.clipboard = 'c\n'
            editor.locate_line! 2
            editor.press! 'Vkjp'
            expect(editor.lines.to_a).to eq(%w[11 c 33 44])
            expect(event).to have_payload('V-line-paste-up', 2.., unknown..)
          end

          it 'reports 2 lines' do
            editor.clipboard = 'c\nd\n'
            editor.locate_line! 2
            editor.press! 'Vjp'
            expect(editor.lines.to_a).to eq(%w[11 c d 44])
            expect(event).to have_payload('V-line-paste-down', 2.., 3..)
          end
        end
      end

      context 'when moving up' do
        context 'from line 3' do
          it 'from 3:, lines 3-2, insert 2 lines' do
            editor.clipboard = 'c\nd\n'
            editor.locate_line! 3
            editor.send_keys_separately 'V', 'kp'

            expect(editor.lines.to_a).to eq(%w[11 c d 44])
            expect(event).to have_payload('V-line-paste-up', 2.., 3..)
          end
        end
      end
    end

    context 'when replacing with more lines count than was' do
      context 'when moving down' do
        context 'from line 2' do
          it 'reports 2 lines' do
            editor.clipboard = 'c\nd\ne\n'
            editor.locate_line! 2
            editor.press! 'Vjp'
            expect(editor.lines.to_a).to eq(%w[11 c d e 44])
            expect(event).to have_payload('V-line-extending-paste-down', 2.., 3..)
          end

          it 'reports 1 line' do
            editor.clipboard = 'c\nd\n'
            editor.locate_line! 2
            editor.press! 'Vp'
            expect(editor.lines.to_a).to eq(%w[11 c d 33 44])
            expect(event).to have_payload('n-paste-back', 2.., 2..)
          end

          # as required as far as we don't have VisualEnter hook
          it 'reports 1 line after movements (to record visual mode state)' do
            editor.clipboard = 'c\nd\n'
            editor.locate_line! 2
            editor.press! 'Vkjp'
            expect(editor.lines.to_a).to eq(%w[11 c d 33 44])
            expect(event).to have_payload('V-line-extending-paste-up', 2.., 2..)
          end
        end
      end

      context 'context when moving up' do
        context 'from line 3' do
          it 'reports 2 lines' do
            editor.clipboard = 'c\nd\ne\n'
            editor.locate_line! 3
            editor.press! 'Vkp'
            expect(editor.lines.to_a).to eq(%w[11 c d e 44])
            expect(event).to have_payload('V-line-extending-paste-up', 2.., 3..)
          end
        end
      end
    end
  end
end
