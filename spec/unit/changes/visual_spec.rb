# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#ftdetect' do
  include VimlValue::SerializationHelpers
  include Helpers::ReportEditorStateOnError
  include Helpers::Changes

  include_context 'report editor messages on error'

  around do |e|
    editor.with_ignore_cache(&e)
    editor.command! 'undo 1 | undo'
  end

  let(:event) { editor.echo(var('b:__changes[-1]')) }

  context 'visual block' do
    before do
      vim.insert <<~TEXT.chomp
        aa bb
        cc dd
        ee ff
      TEXT
      vim.normal
      editor.echo func('esearch#changes#listen_for_current_buffer')
    end

    describe 'delete' do
      context 'moving down' do
        context 'when col1 > col2' do
          it 'reports deleted region' do
            editor.send_keys '1gg4|v2gg2|x'
            expect(editor.lines.to_a).to eq(['aa  dd', 'ee ff'])

            expect(event).to have_payload('v-delete-down', 1..4, 2..2)
          end
        end

        context 'when col1 < col2' do
          context 'delete until a char in the middle' do
            it 'reports deleted region' do
              editor.press! '2gg3|v3gg4|x'
              expect(editor.lines.to_a).to eq(['aa bb', 'ccf'])

              expect(event).to have_payload('v-delete-up', 2..3, 3..4)
            end
          end

          context 'when delete until the end of the buffer' do
            it 'reports deleted region' do
              editor.press! '2gg4|vG$x'
              expect(editor.lines.to_a).to eq(['aa bb', 'cc '])

              expect(event).to have_payload('v-delete-up', 2..4, 3..6)
            end
          end
        end

        context 'when col1 == col2' do
          it 'reports deleted region' do
            editor.press! '2gg4|v3gg4|x'
            expect(editor.lines.to_a).to eq(['aa bb', 'cc f'])

            expect(event).to have_payload('v-delete-up', 2..4, 3..4)
          end
        end

        context 'when deleting entire buffer' do
          it 'reports deleted region' do
            editor.press! '1gg1|vG$x'
            expect(editor.lines.to_a).to eq([''])

            expect(event).to have_payload('v-delete-up', 1..1, 3..6)
          end
        end
      end

      context 'moving up' do
        context 'when col1 < col2' do
          it 'reports deleted region' do
            editor.press! '3gg3|v1gg2|x'
            expect(editor.lines.to_a).to eq(['aff'])

            expect(event).to have_payload('v-delete-up', 1..2, 3..3)
          end
        end

        context 'when entire buffer is deleted' do
          it 'reports deleted region' do
            editor.press! 'G$vggx'
            expect(editor.lines.to_a).to eq([''])
            expect(event).to have_payload('v-delete-up', 1..1, 3..5)
          end
        end
      end

      context 'within a inline' do
        context 'moving forward' do
          it 'reports deleted region' do
            editor.press! '2gg2|'
            editor.send_keys_separately 'v', '3|x'
            expect(editor.lines.to_a).to eq(['aa bb', 'cdd', 'ee ff'])

            expect(event).to have_payload('v-inline', 2..2, 2..3)
          end
        end

        context 'when backward' do
          context 'from col1 == -2' do
            it 'reports deleted region' do
              editor.press! '2gg4|v2|x'
              expect(editor.lines.to_a).to eq(['aa bb', 'cd', 'ee ff'])

              expect(event).to have_payload('v-inline', 2..2, 2..4)
            end
          end

          context 'from col1 == -1' do
            it 'reports deleted region' do
              editor.press! '2gg$v3|x'
              expect(editor.lines.to_a).to eq(['aa bb', 'cc', 'ee ff'])
              expect(event).to have_payload('v-inline', 2..3, 2..5)
            end
          end
        end
      end
    end

    describe 'paste without changing lines count' do
      context 'moving backward' do
        context 'when col1 < col2' do
          it 'reports replaced region' do
            editor.clipboard = '11 22\n3'
            editor.press! '3gg2|v2gg1|p'
            expect(editor.lines.to_a).to eq(['aa bb', '11 22', '3 ff'])
            expect(event).to have_payload('v-paste-up', 2..1, 3..unknown)
          end
        end

        context 'when col1 > col2' do
          it 'reports replaced region' do
            editor.clipboard = '11 22\n3'
            editor.press! '3gg2|v2gg5|p'
            expect(editor.lines.to_a).to eq(['aa bb', 'cc d11 22', '3 ff'])

            expect(event).to have_payload('v-paste-up', 2..5, 3..unknown)
          end
        end

        context 'when col1 == col2' do
          it 'reports replaced region' do
            editor.clipboard = '11 22\n3'
            editor.press! '3gg2|v2gg2|p'
            expect(editor.lines.to_a).to eq(['aa bb', 'c11 22', '3 ff'])

            expect(event).to have_payload('v-paste-up', 2..2, 3..unknown)
          end
        end
      end

      context 'moving forward' do

        context 'when col1 > col2' do
          it 'reports replaced region' do
            editor.clipboard = '11 22\n3'
            editor.press! '2gg4|v3gg2|p'
            expect(editor.lines.to_a).to eq(['aa bb', 'cc 11 22', '3 ff'])

            expect(event).to have_payload('v-paste-forward', 2..4, 3..2)
          end
        end

        context 'when col1 < col2' do
          it 'reports replaced region' do
            editor.clipboard = '11 22\n3'
            editor.press! '2gg4|v3gg5|p'
            expect(editor.lines.to_a).to eq(['aa bb', 'cc 11 22', '3'])

            expect(event).to have_payload('v-paste-forward', 2..4, 3..5)
          end
        end

        context 'when col1 == col2' do
          it 'reports replaced region' do
            editor.clipboard = '11 22\n3'
            editor.press! '2gg4|v3gg4|p'
            expect(editor.lines.to_a).to eq(['aa bb', 'cc 11 22', '3f'])

            expect(event).to have_payload('v-paste-forward', 2..4, 3..4)
          end
        end
      end
    end

    describe 'paste with changing lines count' do
      context 'moving backward' do
        context 'when  col1 < col2' do
          it 'reports replaced region' do
            editor.clipboard = '11 22\n3'
            editor.press! '3gg2|v1gg1|p'
            expect(editor.lines.to_a).to eq(['11 22', '3 ff'])

            expect(event).to have_payload('v-paste-back-size-changing', 1..1, 3..unknown)
          end
        end

        context 'when col1 > col2' do
          it 'reports replaced region' do
            editor.clipboard = '11 22\n3'
            editor.press! '3gg2|v1gg5|p'
            expect(editor.lines.to_a).to eq(['aa b11 22', '3 ff'])

            expect(event).to have_payload('v-paste-back-size-changing', 1..5, 3..unknown)
          end
        end

        context 'when col1 == col2' do
          it 'reports replaced region' do
            editor.clipboard = '11 22\n3'
            editor.press! '3gg2|v1gg2|p'
            expect(editor.lines.to_a).to eq(['a11 22', '3 ff'])

            expect(event).to have_payload('v-paste-back-size-changing', 1..2, 3..unknown)
          end
        end
      end

      context 'moving forward' do
        context 'when col1 > col2' do
          it 'reports replaced region' do
            editor.clipboard = '11 22\n3'
            editor.press! '1gg4|v3gg2|p'
            expect(editor.lines.to_a).to eq(['aa 11 22', '3 ff'])

            expect(event).to have_payload('v-paste-forward-size-changing', 1..4, 3..2)
          end
        end

        context 'when col1 < col2' do
          it 'reports replaced region' do
            editor.clipboard = '11 22\n3'
            editor.press! '1gg4|v3gg5|p'
            expect(editor.lines.to_a).to eq(['aa 11 22', '3'])

            expect(event).to have_payload('v-paste-forward-size-changing', 1..4, 3..5)
          end
        end

        context 'COL1 = COL2' do
          it 'reports replaced region' do
            editor.clipboard = '11 22\n3'
            editor.press! '1gg4|v3gg4|p'
            expect(editor.lines.to_a).to eq(['aa 11 22', '3f'])

            expect(event).to have_payload('v-paste-forward-size-changing', 1..4, 3..4)
          end
        end
      end
    end
  end
end
