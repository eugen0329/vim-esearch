# frozen_string_literal: true

require 'spec_helper'

describe 'Modifiable window :substitute', :window do
  include Helpers::Modifiable
  include Helpers::Modifiable::Commandline
  Context ||= Helpers::Modifiable::Context

  include_context 'setup modifiable testing'

  let(:contexts) do
    [Context.new('aaaaaa', ('x'..'z').map { |letter| "aaa#{letter}" }),
     Context.new('bbbbbb', ('x'..'z').map { |letter| "bbb#{letter}" }),
     Context.new('cccccc', ('x'..'z').map { |letter| "ccc#{letter}" })]
  end

  around { |e| editor.with_ignore_cache(&e) }

  describe '[count]' do
    context 'when  given' do
      context 'when the value is enough' do
        let(:count) { entry.line_in_window }

        it 'removes [count] lines down after the range end' do
          expect  { editor.send_command("1s/#{entry.result_text}/changed/g #{count}") }
            .to change_entries_content([entry]).to(['changed'])
        end

        it 'handles without flags' do
          expect  { editor.send_command("1s/#{entry.result_text}/changed/ #{count}") }
            .to change_entries_content([entry]).to(['changed'])
        end

        it 'handles without replacement string' do
          expect  { editor.send_command("1s/#{entry.result_text}// #{count}") }
            .to change_entries_content([entry]).to([''])
        end
      end

      context "when the value isn't enough" do
        let(:count) { entry.line_in_window - 1 }

        it "doesn't substitute anything" do
          expect  { editor.send_command("1s/#{entry.result_text}/changed/ #{count}") }
            .not_to change_entries_content(entries)
        end
      end
    end

    context 'when empty' do
      it 'handles trailing spaces' do
        expect  { editor.send_command("%s/#{entry.result_text}/changed/ ") }
          .to change_entries_content([entry]).to(['changed'])
      end

      it 'handles empty flags' do
        expect  {
          editor.send_command("%s/#{entry.result_text}/changed/")
        }.to change_entries_content([entry]).to(['changed'])
      end

      it 'handles with no separating slash given' do
        expect {
          editor.send_command("%s/#{entry.result_text}/changed")
        }.to change_entries_content([entry]).to(['changed'])
      end
    end

    describe '[flags]' do
      context 'when are given' do
        context 'when [c] (confirm each substitution) is given' do
          let(:sample_context) { contexts.sample }
          let(:entries_count) { sample_context.entries.count }
          let(:confirmations_count) { entries_count + 1 } # plus matched filename
          let(:not_affected_entries) { (contexts - [sample_context]).map(&:entries).flatten }
          let(:pattern) { "#{sample_context.name[0..2]}\\w" }

          it "doesn't ask confirmation on rerun" do
            expect  {
              editor.send_command("%s/#{pattern}/changed/gc")
              editor.press! 'y' * confirmations_count + '<Esc>'
            }.to change_entries_content(sample_context.entries)
              .to(['changed'] * entries_count)
              .and not_to_change_entries_content(not_affected_entries)
          end
        end

        context 'when [n] (Report the number of matches) is given' do
          it "doesn't substitute" do
            expect { editor.send_command('%s/./changed/gn') }
              .to not_to_change_entries_content(entries)
          end
        end
      end
    end

    describe '[string]' do
      context 'when is empty' do
        it 'handles empty [string]' do
          expect  { editor.send_command("%s/#{entry.result_text}//") }
            .to change_entries_content([entry]).to([''])
        end

        it 'handles with no closing slash given' do
          expect  { editor.send_command("%s/#{entry.result_text}/") }
            .to change_entries_content([entry]).to([''])
        end

        it 'handles with no separating slash given' do
          expect  { editor.send_command("%s/#{entry.result_text}") }
            .to change_entries_content([entry]).to([''])
        end
      end
    end

    describe '[pattern]' do
      context 'when is empty' do
        before do
          editor.send_command("%s/#{entry.result_text}/changed/")
          editor.command! 'undo 0'
        end

        it 'reuses previous pattern' do
          expect { editor.send_command('%s//changed_after_undo/') }
            .to change_entries_content([entry])
            .to(['changed_after_undo'])
            .and not_to_change_entries_content(entries - [entry])
        end
      end
    end

    describe 'multiline substitution'
    it 'recovers on removing newlines' do
      expect { editor.send_command('%s/\\_.//') }
        .not_to change { editor.lines.to_a }
    end

    it 'recovers on adding newlines' do
      expect { editor.send_command('%s/\\r//') }
        .not_to change { editor.lines.to_a }
    end
  end

  describe '[range]' do
    context 'when backwards given' do
      it 'handles swapping after confirmation' do
        expect  {
          editor.send_command("$,1s/#{entry.result_text}/changed/")
          editor.press! 'y<Esc>'
        }.to change_entries_content([entry]).to(['changed'])
      end

      it 'handles swapping cancellation' do
        expect {
          editor.send_command("$,1s/#{entry.result_text}/changed/")
          editor.press! 'n<Esc>'
        }.not_to change_entries_content(entries)
      end
    end
  end

  describe 'virtual interface recovery' do
    context 'when line numbers are matched' do
      it 'recovers line numbers' do
        expect { editor.send_command("%s/#{entry.line_in_window}/changed/") }
          .not_to change { editor.lines.to_a }
      end
    end

    context 'when the header is matched' do
      it 'recovers the header' do
        expect { editor.send_command('%s/Matches/changed/') }
          .not_to change { editor.lines.to_a }
      end
    end

    context 'when a separator is matched' do
      it 'recovers separators' do
        expect { editor.send_command('%s/^$/changed/') }
          .not_to change { editor.lines.to_a }
      end
    end

    context 'when a filename is matched' do
      it 'recovers filenames' do
        expect { editor.send_command("%s/#{contexts.sample.name}/changed/") }
          .not_to change { editor.lines.to_a }
      end

      it 'changes only entries text' do
        expect { editor.send_command('%s/aaa/changed/') }
          .to change_entries_content(contexts[0].entries)
          .and not_to_change_entries_content(entries - contexts[0].entries)
      end
    end
  end
end
