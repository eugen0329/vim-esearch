# frozen_string_literal: true

require 'spec_helper'

describe 'changes reporting in NORMAL mode' do
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
      vim.insert "11\n22\n33\n44"
      vim.normal
      editor.echo func('esearch#changes#listen_for_current_buffer')
    end
  end

  # TODO: testing with autoindent
  # TODO rework pasting coordinates detection

  context 'delete' do
    context 'with motion down' do
      include_context 'setup multiline testing'

      context 'from line 1' do
        it 'reports 4 lines' do
          editor.locate_line! 1
          editor.send_keys_separately '4dj'
          expect(editor.lines.to_a).to eq([''])
          expect(event).to include_payload('n-motion-down2', 1.., 4..)
        end
      end

      context 'from line 2' do
        it 'reports 2 lines' do
          editor.locate_line! 2
          editor.send_keys_separately '1dj'
          expect(editor.lines.to_a).to eq(%w[11 44])
          expect(event).to include_payload('n-motion-down2', 2.., 3..)
        end

        it 'reports 3 lines' do
          editor.locate_line! 2
          editor.send_keys_separately '2dj'
          expect(editor.lines.to_a).to eq(%w[11])
          expect(event).to include_payload('n-motion-up2', 2.., 4..)
        end
      end

      context 'from line -2' do
        it 'reports 2 lines' do
          editor.locate_line! 3
          editor.send_keys_separately '1dj'
          expect(editor.lines.to_a).to eq(%w[11 22])
          expect(event).to include_payload('n-motion-up2', 3.., 4..)
        end
      end
    end

    context 'with motion up' do
      include_context 'setup multiline testing'

      context 'from line -1' do
        it 'reports 3 lines' do
          editor.locate_line! 4
          editor.send_keys_separately '2dk'
          expect(editor.lines.to_a).to eq(%w[11])
          expect(event).to include_payload('n-motion-up2', 2.., 4..)
        end

        it 'reports 2 lines' do
          editor.locate_line! 4
          editor.send_keys_separately '1dk'
          expect(editor.lines.to_a).to eq(%w[11 22])
          expect(event).to include_payload('n-motion-up2', 3.., 4..)
        end

        it 'reports 4 lines' do
          editor.locate_line! 4
          editor.send_keys_separately '4dk'
          expect(editor.lines.to_a).to eq([''])
          expect(event).to include_payload('n-motion-up1', 1.., 4..)
        end
      end

      context 'from line -2' do
        it 'reports 3 lines' do
          editor.locate_line! 3
          editor.send_keys_separately '1dk'
          expect(editor.lines.to_a).to eq(%w[11 44])
          expect(event).to include_payload('n-motion-up1', 2.., 3..)
        end
      end
    end
  end

  context 'inline changes' do
    let(:content) { "11\naaa bbb ccc ddd" }

    before do
      vim.insert content
      vim.normal
      editor.echo func('esearch#changes#listen_for_current_buffer')
      editor.command 'set virtualedit=onemore'
    end

    context 'delete' do
      context 'with textobject' do
        it 'in the beginning of a word' do
          editor.locate_cursor! 2, 5
          editor.send_keys_separately 'daw'
          expect(editor.lines.to_a).to eq(['11', 'aaa ccc ddd'])
          expect(event).to include_payload('n-inline6', 2..5, 2..8)
        end

        it 'in the middle of a word' do
          editor.locate_cursor! 2, 6
          editor.send_keys_separately 'daw'
          expect(editor.lines.to_a).to eq(['11', 'aaa ccc ddd'])
          expect(event).to include_payload('n-inline4', 2..5, 2..8)
        end
      end

      context 'with find chnar (f and F)' do
        it 'reports deleted with f' do
          editor.locate_cursor! 2, 5
          editor.send_keys_separately 'dfc'
          expect(editor.lines.to_a).to eq(['11', 'aaa cc ddd'])
          expect(event).to include_payload('n-inline6', 2..5, 2..9)
        end

        it 'reports deleted with F' do
          editor.locate_cursor! 2, 5
          editor.send_keys_separately 'dFa'
          expect(editor.lines.to_a).to eq(['11', 'aabbb ccc ddd'])
          expect(event).to include_payload('n-inline4', 2..3, 2..4)
        end
      end

      context 'motion' do
        it 'reports deleted motion back' do
          editor.locate_cursor! 2, 5
          editor.send_keys_separately '2dh'
          expect(editor.lines.to_a).to eq(['11', 'aabbb ccc ddd'])
          expect(event).to include_payload('n-inline4', 2..3, 2..4)
        end

        it 'reports deleted with motion forward' do
          editor.locate_cursor! 2, 5
          editor.send_keys_separately '2dl'
          expect(editor.lines.to_a).to eq(['11', 'aaa b ccc ddd'])
          expect(event).to include_payload('n-inline6', 2..5, 2..6)
        end

        it 'reports motion to the end with D' do
          editor.locate_cursor! 2, 2
          editor.send_keys_separately 'D'
          expect(editor.lines.to_a).to eq(%w[11 a])
          expect(event).to include_payload('n-inline6', 2..2, 2..15)
        end

        it 'reports motion to the beggining with d0' do
          editor.locate_cursor! 2, 5
          editor.send_keys_separately 'd0'
          expect(editor.lines.to_a).to eq(['11', 'bbb ccc ddd'])
          expect(event).to include_payload('n-inline4', 2..1, 2..4)
        end
      end

      context 'char under the cursor' do
        it 'delete char' do
          editor.locate_cursor! 2, 5
          editor.send_keys_separately 'x'
          expect(editor.lines.to_a).to eq(['11', 'aaa bb ccc ddd'])
          expect(event).to include_payload('n-inline6', 2..5, 2..5)
        end
      end

      context 'clear line' do
        context 'with motion' do
          it 'reports motion to the beggining with d0' do
            editor.locate_cursor! 2, 16
            editor.send_keys_separately 'd0'
            expect(editor.lines.to_a).to eq(['11', ''])
            expect(event).to include_payload('n-inline2', 2..1, 2..15)
          end
        end

        context 'with goung to insert mode' do
          it 'reports deleted with S' do
            editor.locate_cursor! 2, 2
            editor.send_keys_separately 'S'
            expect(editor.lines.to_a).to eq(['11', ''])
            expect(event).to include_payload('n-inline2', 2..1, 2..15)
          end

          it 'reports deleted with cc' do
            editor.locate_cursor! 2, 2
            editor.send_keys_separately 'S'
            expect(editor.lines.to_a).to eq(['11', ''])
            expect(event).to include_payload('n-inline2', 2..1, 2..15)
          end
        end
      end
    end
  end

  context 'cgn motion repeat' do
    before do
      vim.insert "11\n22\n11\n44"
      vim.normal
      editor.echo func('esearch#changes#listen_for_current_buffer')
    end

    context 'backward' do
      it 'reports changed region' do
        editor.locate_cursor! 1, 1
        editor.send_keys_separately '*', 'cgn', 'zz', :escape
        expect { editor.send_keys_separately '.' }
          .to change { editor.lines.to_a }
          .from(%w[11 22 zz 44])
          .to(%w[zz 22 zz 44])
        expect(event).to include_payload('n-inline-repeat-gn-up', 1..1, 1..3)
      end
    end

    context 'forward' do
      it 'reports changed region' do
        editor.locate_cursor! 1, 1
        editor.send_keys_separately '**', 'cgn', 'zz', :escape
        expect { editor.send_keys_separately '.' }
          .to change { editor.lines.to_a }
          .from(%w[zz 22 11 44])
          .to(%w[zz 22 zz 44])
        expect(event).to include_payload('n-inline-repeat-gn-down', 3..1, 3..3)
      end
    end
  end

  context 'paste' do
    include_context 'setup multiline testing'

    context 'forward' do

      context 'from line -1' do
        it 'reports 1 line' do
          editor.locate_line! 4
          editor.clipboard = 'd\\n'
          editor.send_keys_separately 'p'
          expect(editor.lines.to_a).to eq(%w[11 22 33 44 d])
          expect(event).to include_payload('n-paste-forward', 5.., 5..)
        end

        it 'reports 2 lines' do
          editor.locate_line! 4
          editor.clipboard = 'c\\nd\\n'
          editor.send_keys_separately 'p'
          expect(editor.lines.to_a).to eq(%w[11 22 33 44 c d])
          expect(event).to include_payload('n-paste-forward', 5.., 6..)
        end
      end

      context 'from line 1' do
        it 'reports 1 line' do
          editor.clipboard = 'd\\n'
          editor.locate_line! 1
          editor.send_keys_separately 'p'
          expect(editor.lines.to_a).to eq(%w[11 d 22 33 44])
          expect(event).to include_payload('n-paste-forward', 2.., 2..)
        end
      end
    end

    context 'back' do
      context 'from line -1' do
        it 'reports 1 line' do
          editor.locate_line! 4
          editor.clipboard = 'd\\n'
          editor.send_keys_separately 'P'
          expect(editor.lines.to_a).to eq(%w[11 22 33 d 44])
          expect(event).to include_payload('n-paste-back', 4.., 4..)
        end

        it 'report 2 lines' do
          editor.locate_line! 4
          editor.clipboard = 'c\\nd\\n'
          editor.send_keys_separately 'P'
          expect(editor.lines.to_a).to eq(%w[11 22 33 c d 44])
          expect(event).to include_payload('n-paste-back', 4.., 5..)
        end
      end

      context 'from line 1' do
        it 'reports  2 lines' do
          editor.locate_line! 1
          editor.clipboard = 'a\\nb\\n'
          editor.send_keys_separately 'P'
          expect(editor.lines.to_a).to eq(%w[a b 11 22 33 44])
          expect(event).to include_payload('n-paste-back', 1.., 2..)
        end
      end
    end
  end
end
