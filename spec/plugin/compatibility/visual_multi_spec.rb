# frozen_string_literal: true

require 'spec_helper'

describe 'vim-visual-multi compatibility', :window do
  include Helpers::FileSystem
  include Helpers::Modifiable
  include Helpers::Modifiable::Columnwise
  include Helpers::VisualMulti

  include_context 'setup modifiable testing'
  include_context 'setup columnwise testing contexts'

  let(:fillers_alphabet) { [' '] }

  let(:ctx) { build_context(alphabet, fillers_alphabet, anchored_word_width: 2) }
  let(:contexts) { [ctx] }
  let(:anchor) { :middle }

  # NOTES:
  #   - Regions in NORMAL mode are epproximately equal to Cursors in INSERT mode
  #   - EXTEND is VISUAL mode, but when multiple cursors are added

  describe 'operations supported with restrictions' do
    shared_examples 'disable motion when all cursors overlaps virtual ui' do |motion|
      it 'disables motion when all cursors overlaps virtual ui' do
        editor.locate_cursor! ctx.begin_line, 1
        editor.send_keys_separately '\\<c-down>' * ctx.entries.count
        expect { motion.call }.not_to change { editor.lines.to_a }
        expect(visual_multi.regions.count)
          .to eq(ctx.entries.count + 1)
      end
    end

    shared_examples 'delete cursors overlapping virtual ui' do |motion|
      it 'deletes regions overlapping virtual ui' do
        editor.locate_cursor! ctx.begin_line, 1
        editor.send_keys_separately '\\<c-down>'
        locate_anchor({ctx: 0, entry: 1}, anchor)
        editor.send_keys_separately '\\<c-down>' * ((ctx.entries.count - 1) - 1)

        expect { motion.call }
          .to change { visual_multi.regions.count }
          .by(-2)
          .and change { ctx.entries[1..].map(&:line_content) }
          .and not_to_change { ctx.entries.first(1).map(&:line_content) }
      end
    end

    shared_examples 'it handles motions overlappin virtual ui' do |motion|
      include_examples 'disable motion when all cursors overlaps virtual ui', motion
      include_examples 'delete cursors overlapping virtual ui', motion
    end

    describe 'changing text in INSERT mode' do
      context 'when adding text in INSERT mode' do
        let(:anchor) { :begin }

        it 'deletes cursors which change virtual ui' do
          locate_anchor({ctx: 0, entry: 0}, anchor)
          editor.send_keys_separately '\\<c-down>' * (ctx.entries.count - 1)

          expect { editor.send_keys_separately 'i', '\\<up>', 'zzz' }
            .to change { visual_multi.regions.count }
            .by(-1)
            .and change { ctx.entries[..-2].map(&:line_content) }
            .and not_to_change { ctx.entries.last.line_content }
        end
      end

      context 'when deleting text in insert mode' do
        let(:anchor) { :begin }
        let(:regions) { visual_multi.regions }

        before do
          locate_anchor({ctx: 0, entry: 0}, anchor)
          editor.send_keys_separately '\\<c-down>' * (ctx.entries.count - 1)
        end

        context 'when within result text' do
          let(:anchor) { :middle }

          it 'deletes text with DEL' do
            expect { editor.send_keys_separately 'i', :delete, :delete }
              .to change { ctx.entries.map(&:result_text) }
              .and not_to_change { visual_multi.regions.count }
          end

          it 'deletes text with BS' do
            expect { editor.send_keys_separately 'i', :backspace, :backspace }
              .to change { ctx.entries.map(&:result_text) }
              .and not_to_change { visual_multi.regions.count }
          end

          it 'deletes text with CONTROL-w' do
            expect { editor.send_keys_separately 'i', '\\<c-w>', '\\<c-w>' }
              .to change { ctx.entries.map(&:result_text) }
              .and not_to_change { visual_multi.regions.count }
          end

          it 'prevents from inserting newlines' do
            expect { editor.send_keys_separately 'i', :enter, :enter }
              .to not_change { ctx.entries.map(&:result_text) }
              .and not_to_change { visual_multi.regions.count }
          end
        end

        context 'when in the beginning' do
          let(:anchor) { :begin }

          context 'when leading spaces given' do
            it "doesn't delete virtual ui with BS" do
              expect { editor.send_keys_separately 'i', '  ', :backspace, :backspace }
                .to not_change { ctx.entries.map(&:result_text) }
                .and not_to_change { visual_multi.regions.count }
            end

            it "doesn't delete virtual ui with CONTROL-W" do
              expect { editor.send_keys_separately 'i', '\\<c-w>', '\\<c-w>' }
                .to not_change { ctx.entries.map(&:result_text) }
                .and not_to_change { visual_multi.regions.count }
            end
          end

          context 'when not leading spaces' do
            it "doesn't delete virtual ui with BS" do
              expect { editor.send_keys_separately 'i', :backspace, :backspace }
                .to not_change { ctx.entries.map(&:result_text) }
                .and not_to_change { visual_multi.regions.count }
            end

            # Is a subject to improve. If leading spaces before result text are
            # given, CONTROL-W deletes them along with LineNr, thus if only
            # leading spaces before the result text - deletion doesn't happen
            it "doesn't delete leading spaces with CONTROL-W" do
              expect { editor.send_keys_separately 'i', '  ', '\\<c-w>', '\\<c-w>' }
                .to change { ctx.entries.map(&:result_text) }
                .to(all(start_with('  ')))
                .and not_to_change { visual_multi.regions.count }
            end
          end
        end

        context 'when in the end' do
          it "doesn't delete newlines with DEL" do
            expect { editor.send_keys_separately 'A', :delete, :delete }
              .to not_change { editor.lines.to_a.count }
              .and not_to_change { visual_multi.regions.count }
          end
        end
      end

      # There are still some problems when active cursor is within virtual
      # interface caused by inability to switch to the closest when the active
      # is deleted
      include_examples 'delete cursors overlapping virtual ui', -> { editor.send_keys_separately 'i', 'zzz' }
      include_examples 'delete cursors overlapping virtual ui', -> { editor.send_keys_separately 'a', 'zzz' }
    end

    describe 'changing text in NORMAL mode' do
      describe 'motions overlapping virtual ui' do
        it_behaves_like 'it handles motions overlappin virtual ui', -> { editor.send_keys_separately 'd$' }
        it_behaves_like 'it handles motions overlappin virtual ui', -> { editor.send_keys_separately 'dw' }
        it_behaves_like 'it handles motions overlappin virtual ui', -> { editor.send_keys_separately 'de' }
        it_behaves_like 'it handles motions overlappin virtual ui', -> { editor.send_keys_separately 'daw' }
        it_behaves_like 'it handles motions overlappin virtual ui', -> { editor.send_keys_separately 'diw' }

        it_behaves_like 'it handles motions overlappin virtual ui', -> { editor.send_keys_separately 'c$' }
        it_behaves_like 'it handles motions overlappin virtual ui', -> { editor.send_keys_separately 'cw' }
        it_behaves_like 'it handles motions overlappin virtual ui', -> { editor.send_keys_separately 'ce' }
        it_behaves_like 'it handles motions overlappin virtual ui', -> { editor.send_keys_separately 'caw' }
        it_behaves_like 'it handles motions overlappin virtual ui', -> { editor.send_keys_separately 'ciw' }

        it_behaves_like 'it handles motions overlappin virtual ui', -> { editor.send_keys_separately 'D' }
        it_behaves_like 'it handles motions overlappin virtual ui', -> { editor.send_keys_separately 'x' }
        it_behaves_like 'it handles motions overlappin virtual ui', -> { editor.send_keys_separately '~' }
        it_behaves_like 'it handles motions overlappin virtual ui', -> { editor.send_keys_separately :delete }
        it_behaves_like 'it handles motions overlappin virtual ui', -> { editor.send_keys_separately 'r', 'z' }
      end

      describe 'textobjects' do
        describe 'word textobject' do
          context 'when {motion} (i)nner word is given' do
            it_behaves_like 'delete word', -> { editor.send_keys_separately 'diw' }
            it_behaves_like 'delete word', -> { editor.send_keys_separately 'ciw' }
          end

          context 'when {motion} (a) word is given' do
            it_behaves_like 'delete word and whitespaces after',
              -> { editor.send_keys_separately 'daw' }
            it_behaves_like 'delete word and whitespaces after',
              -> { editor.send_keys_separately 'caw', :escape }
          end

          context 'when until word boundaries' do
            it_behaves_like 'delete word and whitespaces after',
              -> { editor.send_keys_separately 'dw' }
            it_behaves_like 'delete word', -> { editor.send_keys_separately 'cw' }
            it_behaves_like 'delete word', -> { editor.send_keys_separately 'de' }
            it_behaves_like 'delete word', -> { editor.send_keys_separately 'ce' }
          end
        end

        describe 'paragraph textobject' do
          it_behaves_like 'it disallows NORMAL mode motion', -> { editor.send_keys_separately 'dip' }
          it_behaves_like 'it disallows NORMAL mode motion', -> { editor.send_keys_separately 'dap' }
          it_behaves_like 'it disallows NORMAL mode motion', -> { editor.send_keys_separately 'cip' }
          it_behaves_like 'it disallows NORMAL mode motion', -> { editor.send_keys_separately 'cap' }
        end
      end

      describe 'sides motions' do
        it_behaves_like 'it disallows NORMAL mode motion', -> { editor.send_keys_separately 'dj' }
        it_behaves_like 'it disallows NORMAL mode motion', -> { editor.send_keys_separately 'dk' }
        it_behaves_like 'it disallows NORMAL mode motion', -> { editor.send_keys_separately 'dd' }
        it_behaves_like 'it disallows NORMAL mode motion', -> { editor.send_keys_separately 'dh' }
        it_behaves_like 'it disallows NORMAL mode motion', -> { editor.send_keys_separately 'dl' }

        it_behaves_like 'it disallows NORMAL mode motion', -> { editor.send_keys_separately 'cj' }
        it_behaves_like 'it disallows NORMAL mode motion', -> { editor.send_keys_separately 'ck' }
        it_behaves_like 'it disallows NORMAL mode motion', -> { editor.send_keys_separately 'cd' }
        it_behaves_like 'it disallows NORMAL mode motion', -> { editor.send_keys_separately 'ch' }
        it_behaves_like 'it disallows NORMAL mode motion', -> { editor.send_keys_separately 'cl' }
      end
    end
  end

  describe 'unsupported operations' do
    # Operations that:
    # - too hard to implement
    # - doesn't make sense (like joining lines with J operator or inserting newlines with O)
    describe 'J operator (join lines)' do
      it_behaves_like 'it disallows non-INSERT motion',
        -> { editor.send_keys_separately 'J' }
    end

    describe '. operator (repeat)' do
      it_behaves_like 'it disallows non-INSERT motion',
        -> { editor.send_keys_separately 'x', 'u', '.' }
    end

    describe 'starting INSERT' do
      it_behaves_like 'it disallows non-INSERT motion',
        -> { editor.send_keys_separately 'I' }
      it_behaves_like 'it disallows non-INSERT motion',
        -> { editor.send_keys_separately "#{API::VisualMulti::LEADER}o" }
      it_behaves_like 'it disallows non-INSERT motion',
        -> { editor.send_keys_separately "#{API::VisualMulti::LEADER}O" }
      it_behaves_like 'it disallows non-INSERT motion',
        -> { editor.send_keys_separately 'gcl' }
      it_behaves_like 'it disallows non-INSERT motion',
        -> { editor.send_keys_separately 'C' }
    end

    describe 'replace' do
      it_behaves_like 'it disallows non-INSERT motion',
        -> { editor.send_keys_separately '\\<plug>(VM-Replace)', 'zzz' }
    end

    describe '<plug>(VM-Transform-Regions) map' do
      # Can be moved to supported with restrictions in future as it seems too useful
      it_behaves_like 'it disallows non-INSERT motion',
        -> { editor.send_keys_separately "#{API::VisualMulti::LEADER}e", 'zzz', :enter }
    end

    describe 'pasting' do
      it_behaves_like 'it disallows non-INSERT motion',
        -> { editor.send_keys_separately 'x', 'u', '\\<plug>(VM-Transform-Regions)' }
      it_behaves_like 'it disallows non-INSERT motion',
        -> { editor.send_keys_separately 'x', 'u', '\\<plug>(VM-p-Paste-Regions)' }
      it_behaves_like 'it disallows non-INSERT motion',
        -> { editor.send_keys_separately 'x', 'u', '\\<plug>(VM-P-Paste-Regions)' }
      it_behaves_like 'it disallows non-INSERT motion',
        -> { editor.send_keys_separately 'x', 'u', '\\<plug>(VM-p-Paste-Vimreg)' }
      it_behaves_like 'it disallows non-INSERT motion',
        -> { editor.send_keys_separately 'x', 'u', '\\<plug>(VM-P-Paste-Vimreg)' }
      # <c-v> is mapped to <plug>(VM-I-paste)
      it_behaves_like 'it disallows INSERT mode motion',
        -> { editor.send_keys_separately 'x', 'u', 'i', '\\<c-v>' }
    end
  end
end
