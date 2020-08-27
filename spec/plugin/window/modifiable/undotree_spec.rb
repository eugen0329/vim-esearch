# frozen_string_literal: true

require 'spec_helper'

describe 'Undoing in modifiable mode', :window do
  include Helpers::FileSystem
  include VimlValue::SerializationHelpers
  include Helpers::Modifiable
  include Helpers::Undotree

  include_context 'setup modifiable testing'

  # NOTES
  # - undo is represented as a tree structure
  # - each undo block can be checkouted (seq_last - last change block
  #   number, seq_cur - currently checkouted block)

  # as undotree().items doesn't contain the first block
  let!(:root_node) { editor.changenr }
  # this entry isn't listed as well, but seq_cur and changenr() are showing it
  let(:root_node_alias) { 0 }

  shared_context 'undotree is completely synchronized' do
    after do
      expect(undotree_nodes | [root_node, root_node_alias])
        .to match_array(esearch_undotree_nodes)
    end
  end

  describe 'plain undo' do
    include_context 'undotree is completely synchronized'

    context '1 block back' do
      it 'handles undo of a deleted line' do
        entries.each do |entry|
          entry.locate!
          editor.send_keys_separately 'dd'
          expect(output).to have_missing_entries([entry]) # fail fast

          expect { editor.send_keys_separately 'u' }
            .to change { output.entries.to_a }
            .to(have_valid_entries(entries.compact + [entry]))
        end
      end
    end

    context 'n > 1 tree entries back' do
      it 'handles undo of deleted lines' do
        entries.combination(2).to_a.sample(3).each do |entry1, entry2|
          entry1.locate!
          editor.send_keys_separately 'dd'
          output.reload(entry2).locate!
          editor.send_keys_separately 'dd'
          expect(output).to have_missing_entries([entry1, entry2])  # fail fast

          expect { editor.send_keys_separately 'u' }
            .to change { output.entries.to_a }
            .to(have_missing_entries([entry1]) & have_valid_entries(entries - [entry1]))

          expect { editor.send_keys_separately 'u' }
            .to change { output.entries.to_a }
            .to(have_valid_entries(entries))
        end
      end
    end

    context 'until block 0' do
      it 'handles undo of until the first state' do
        entries.combination(2).to_a.sample(3).each do |entry1, entry2|
          entry1.locate!
          editor.send_keys_separately 'dd'
          output.reload(entry2).locate!
          editor.send_keys_separately 'dd'
          expect(output).to have_missing_entries([entry1, entry2])  # fail fast

          # blocks order is: 0 n0 n0+1 n0+2 (n0 >= 1, n0+2 is the last)
          editor.send_keys_separately 'u' * 100

          expect(output).to have_valid_entries(entries)
        end
      end
    end
  end

  describe 'plain redo' do
    include_context 'undotree is completely synchronized'

    context '1 block forward' do
      it do
        entries.each do |entry|
          entry.locate!
          editor.send_keys_separately 'dd'
          editor.send_keys_separately 'u'
          expect(editor).to have_valid_entries(entries) # fail fast

          expect { editor.send_keys_separately '\\<C-r>' }
            .to change { output.entries.to_a }
            .to(have_missing_entries([entry]))

          editor.command! 'undo | undo'
        end
      end
    end

    context 'n > 1 tree entries forward' do
      it do
        entries.combination(2).to_a.sample(3).each do |entry1, entry2|
          entry1.locate!
          editor.send_keys_separately 'dd'
          output.reload(entry2).locate!
          editor.send_keys_separately 'dd'
          editor.send_keys_separately 'uu'
          expect(editor).to have_valid_entries(entries) # fail fast

          expect { editor.send_keys_separately '\\<C-r>' }
            .to change { output.entries.to_a }
            .to(have_missing_entries([entry1]) & have_valid_entries(entries - [entry1]))

          expect { editor.send_keys_separately '\\<C-r>' }
            .to change { output.entries.to_a }
            .to(have_missing_entries([entry1, entry2]))

          editor.command! 'undo | undo'
        end
      end
    end

    context 'until seq_last' do
      it do
        entry.locate!
        editor.send_keys_separately 'dd'
        editor.send_keys_separately 'u'
        expect(editor).to have_valid_entries(entries) # fail fast

        editor.send_keys_separately '\\<C-r>' * 100
        expect(output).to have_missing_entries([entry])
      end
    end
  end

  describe 'branching' do
    include_context 'undotree is completely synchronized'

    let(:entry0)  { entries[0] }
    let(:entry1)  { entries[1] }
    let(:entry2)  { entries[2] }

    # Undo branches will look like (actions 1-5 are listed in braces):
    # *   5. dd over entry 3
    # | * 3. dd over entry 2
    # | * 2. dd over entry 1
    # |/
    # *   1. entry1.locate!; 4. descend back to this block with uu
    before do
      entry1.locate!
      editor.send_keys_separately 'dd'
      output.reload(entry2).locate!
      editor.send_keys_separately 'dd'
      expect(output).to have_missing_entries([entry1, entry2]) # fail fast
      editor.send_keys_separately 'uu'
      expect(output).to have_valid_entries(entries) # fail fast
    end

    it 'handles new branch creation' do
      output.reload(entry2).locate!
      expect { editor.send_keys_separately 'dd' }
        .to change { output.entries.to_a }
        .to(have_missing_entries([entry2]) & have_valid_entries(entries - [entry2]))
    end
  end

  describe 'rewinding' do
    let!(:original_changenr) { editor.changenr }

    before do
      expect { editor.send_command("%s/#{entry.result_text}//") }
        .to change { editor.changenr }
        .from(original_changenr)
      expect((undotree_nodes | [root_node, root_node_alias]).size)
        .to eq(esearch_undotree_nodes.size + 1)
      expect(editor.changenr - 1).not_to eq(original_changenr)
    end

    context 'when :undo to a not synchronized block' do
      # *   3. replaying substitute here
      # | * 2. silent undo back; 4. undo #{editor.changenr-1} to this block
      # |/
      # *   1. substitute/...//; 5. auto-rewinding back from the corrupted block

      it 'rewinds to the first synchronized block' do
        expect { editor.send_command("undo #{editor.changenr - 1}") }
          .to change { editor.changenr }
          .to(original_changenr)
      end
    end

    context 'when redo to not synchronized' do
      before { editor.send_command("undo #{editor.changenr - 1}") }
      # *   3. replaying substitute here
      # | * 2. silent undo back; 4. undo #{editor.changenr-1} to this block
      # |/
      # *   1. substitute/...//; 5. auto-rewinding happened, trying :redo

      it 'rewinds to the first synchronized block' do
        expect { editor.send_command('redo') }
          .not_to change { editor.changenr }
          .from(original_changenr)
      end
    end
  end

  describe 'undefined actions' do
    include_context 'undotree is completely synchronized'

    let!(:changenr_was) { editor.changenr }

    before do
      # Undefined actions are handled via :undo which cause changenr() to remain
      # the same, while last undo block number is incremented.
      # Here is the setup verification to have feedback when it will become outdated
      expect { editor.send_keys_separately 'J' }
        .to change { editor.echo(var('undotree().seq_last')) }
        .to(be > changenr_was)
        .and not_to_change { editor.changenr }
    end

    context 'when an entry is affected' do
      let(:entry) { entries.sample }

      it 'works after unknown action recovery' do
        entry.locate!
        expect { editor.send_keys_separately 'dd' }
          .to change { output.entries.to_a }
          .to(have_missing_entries([entry]) & have_valid_entries(entries - [entry]))
        expect { editor.send_keys_separately 'u' }
          .to change { output.entries.to_a }
          .to(have_valid_entries(entries))
      end
    end

    context 'when virtual ui is affected' do
      after do
        # one undotree() block with no changes stored inside is left and we
        # have nothing to do with it
        expect { editor.send_keys_separately 'u' }
          .not_to change { editor.lines.to_a }
      end

      context 'context filename' do
        let(:entry) { contexts.sample.entries[0] }

        it 'works after unknown action recovery' do
          editor.locate_line! entry.line_in_window - 1
          expect { editor.send_keys_separately 'dd' }
            .not_to change { editor.lines.to_a }
        end
      end

      context 'blank line between contexts' do
        let(:entry) { contexts.sample.entries[0] }

        it 'works after unknown action recovery' do
          editor.locate_line! entry.line_in_window - 2
          expect { editor.send_keys_separately 'dd' }
            .not_to change { editor.lines.to_a }
        end
      end
    end
  end

  describe 'INSERT mode' do
    include_context 'undotree is completely synchronized'

    context 'breaking undo blocks' do
      it 'works after unknown action recovery' do
        entry.locate!
        editor.send_keys_separately 'i', 'xxx', '\\<C-g>u', 'zzz', :escape

        expect { editor.send_keys_separately 'u' }
          .to change { output.reload(entry).result_text }
          .from(start_with('xxxzzz'))
          .to(start_with('xxx'))
      end
    end
  end
end
