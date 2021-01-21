# frozen_string_literal: true

require 'spec_helper'

describe ':[range]s[ubstitute]/{pattern}/{string}/[flags] [count] within window', :window do
  include Helpers::Modifiable
  include Helpers::Modifiable::Commandline
  Context ||= Helpers::Modifiable::Context

  include_context 'setup modifiable testing', default_mappings: 1

  let(:context1) { Context.new('aaaaaa', ('x'..'z').map { |letter| "aaa#{letter}" }) }
  let(:context2) { Context.new('bbbbbb', ('x'..'z').map { |letter| "bbb#{letter}" }) }
  let(:context3) { Context.new('cccccc', ('x'..'z').map { |letter| "ccc#{letter}" }) }
  let(:contexts) { [context1, context2, context3] }

  around { |e| editor.with_ignore_cache(&e) }

  describe '[count]' do
    let(:pattern) { entry.result_text }

    context 'when given' do
      context 'when the value is enough' do
        let(:count) { entry.line_in_window }

        context 'when [flags] are given' do
          let(:flags) { 'g' }

          it 'substitutes in [count] lines down after the range end' do
            expect  { editor.send_command("1s/#{pattern}/changed/#{flags} #{count}") }
              .to change_entries_text([entry]).to(['changed'])
          end
        end

        context 'when [flags] are missing' do
          it 'substitutes in [count] lines down after the range end' do
            expect  { editor.send_command("1s/#{pattern}/changed/ #{count}") }
              .to change_entries_text([entry]).to(['changed'])
          end
        end

        context 'when [string] is missing' do
          it 'removes matched text in [count] lines down after the range end' do
            expect  { editor.send_command("1s/#{pattern}// #{count}") }
              .to change_entries_text([entry]).to([''])
          end
        end
      end

      context "when the value isn't enough" do
        let(:count) { entry.line_in_window - 1 }

        it "doesn't substitute" do
          expect  { editor.send_command("1s/#{pattern}/changed/ #{count}") }
            .not_to change_entries_text(entries)
        end
      end
    end

    context 'when empty' do
      context 'when trailing spaces are given' do
        it 'substitutes matched text' do
          expect  { editor.send_command("%s/#{pattern}/changed/ ") }
            .to change_entries_text([entry]).to(['changed'])
        end
      end

      context 'when closing slash is missing' do
        it 'substitutes matched text' do
          expect  { editor.send_command("%s/#{pattern}/changed/") }
            .to change_entries_text([entry]).to(['changed'])
        end
      end

      context 'when separating slash is missing' do
        it 'substitutes matched text' do
          expect { editor.send_command("%s/#{pattern}/changed") }
            .to change_entries_text([entry]).to(['changed'])
        end
      end
    end
  end

  describe '[flags]' do
    context 'when are given' do
      context 'when [c] (confirm each substitution) is given' do
        let(:sample_context) { contexts.sample }
        let(:entries_count) { sample_context.entries.count }
        let(:confirmations_count) { entries_count + 1 } # plus matched filename
        let(:pattern) { "#{sample_context.name[0..2]}\\w" }
        let(:modified_entries) { sample_context.entries }

        describe "confirmation of everythnig with 'y'" do
          let(:flags) { 'gc' }

          it 'substitutes matched text' do
            expect do
              editor.send_command("%s/#{pattern}/changed/#{flags}")
              editor.raw_send_keys 'y' * confirmations_count
            end.to change_entries_text(modified_entries)
              .to(['changed'] * modified_entries.count)
              .and not_to_change_entries_text(entries - modified_entries)
          end
        end

        describe 'ambigous substitution matches' do
          let(:flags) { 'gc' }

          context 'when line number virtual ui is affected' do
            let(:contexts) { [context1] }
            let(:context1) { Context.new('context1.txt', %w[aaaa bbbb]) }
            let(:entry1) { context1.entries.first }
            let(:entry2) { context1.entries.last }

            context 'when only 1 match in a line' do
              let(:pattern) do
                "\\(^\\s*#{entry1.line_in_file}\\|#{entry2.result_text}\\)"
              end
              let(:matched_line_numbers_count) { 1 }
              let(:matched_result_texts_count) { 1 }
              let(:confirmations_count) { matched_result_texts_count + matched_line_numbers_count }

              it 'substitutes matched text' do
                expect do
                  editor.send_command("%s/#{pattern}/changed/#{flags}")
                  editor.send_keys 'a'
                end.to change_entries_text([entry2])
                  .to(['changed'])
                  .and not_to_change_entries_text([entry1])
              end
            end
          end
        end

        describe "substitution confirmation with 'a' (all remaining matches)" do
          let(:flags) { 'c' }

          context "when only 'a' is pressed" do
            it 'substitutes all matches' do
              expect do
                editor.send_command("%s/#{pattern}/changed/#{flags}")
                editor.send_keys 'a'
              end.to change_entries_text(modified_entries)
                .to(['changed'] * modified_entries.count)
                .and not_to_change_entries_text(entries - modified_entries)
            end
          end

          context "when 'a' is pressed after substituting with the 1st match 'y'" do
            it 'substitutes all matches' do
              expect do
                editor.send_command("%s/#{pattern}/changed/#{flags}")
                editor.send_keys 'yya'
              end.to change_entries_text(modified_entries)
                .to(['changed'] * modified_entries.count)
                .and not_to_change_entries_text(entries - modified_entries)
            end
          end

          context "when 'a' is pressed after skipping with the 1st match 'n'" do
            let(:modified_entries) { sample_context.entries[1..] }

            context 'when matches on different lines' do
              it 'substitutes all matches but 1st' do
                expect do
                  editor.send_command("%s/#{pattern}/changed/#{flags}")
                  editor.raw_send_keys 'na'
                end.to change_entries_text(modified_entries)
                  .to(['changed'] * modified_entries.count)
                  .and not_to_change_entries_text(entries - modified_entries)
              end
            end

            context 'when skipped 1st match is on the same line with substituted 2nd' do
              let(:contexts) { [context1] }
              let(:flags) { 'gc' }
              let(:pattern) { 'aa' }
              let(:context1) do
                Context.new('context1.txt', ["#{pattern}#{pattern}", "#{pattern} bb"])
              end

              it 'substitutes all matches but 1st' do
                expect do
                  editor.send_command("%s/#{pattern}/changed/#{flags}")
                  editor.send_keys 'na'
                end.to change_entries_text(context1.entries)
                  .to(['aachanged', 'changed bb'])
              end
            end
          end
        end
      end

      context 'when [n] (report the number of matches) is given' do
        let(:flags) { 'gn' } #  'g' is added to prevent matches only within LineNr

        it "doesn't substitute" do
          expect { editor.send_command("%s/./changed/#{flags}") }
            .to not_to_change_entries_text(entries)
        end
      end
    end
  end

  describe '[string]' do
    context 'when is empty' do
      let(:pattern) { entry.result_text }

      context 'when closing slash given' do
        it 'removes matched text' do
          expect  { editor.send_command("%s/#{pattern}//") }
            .to change_entries_text([entry]).to([''])
        end
      end

      context 'when closing slash is missing' do
        it 'removes matched text' do
          expect  { editor.send_command("%s/#{pattern}/") }
            .to change_entries_text([entry]).to([''])
        end
      end

      context 'when separating slash is missing' do
        it 'removes matched text' do
          expect  { editor.send_command("%s/#{pattern}") }
            .to change_entries_text([entry]).to([''])
        end
      end
    end
  end

  describe '[pattern]' do
    context 'when is empty' do
      let(:pattern) { entry.result_text }
      let(:original_text) { entry.result_text }

      before do
        editor.send_command("%s/#{pattern}/changed/")
        expect { editor.send_command 'undo 0' }
          .to change_entries_text([entry])
      end

      it 'reuses previous pattern' do
        expect { editor.send_command('%s//changed_after_undo/') }
          .to change_entries_text(entry)
          .to(['changed_after_undo'])
          .and not_to_change_entries_text(entries - [entry])
      end
    end
  end

  describe 'multiline substitution' do
    context 'when removing newlines' do
      it 'prevents from \_.' do
        expect { editor.send_command('%s/\\_.//') }
          .not_to change { editor.lines.to_a }
      end

      it 'prevents from \n' do
        expect { editor.send_command('%s/\\_.//') }
          .not_to change { editor.lines.to_a }
      end
    end

    context 'when adding newlines' do
      it 'prevents from adding \r' do
        expect { editor.send_command('%s/\\r//') }
          .not_to change { editor.lines.to_a }
      end
    end
  end

  describe '[range]' do
    let(:pattern) { entry.result_text }

    context 'when backwards range is given' do
      it 'substitutes with auto-swap region confirmation' do
        expect do
          editor.send_command("$,1s/#{pattern}/changed/")
          editor.send_keys 'y'
        end.to change_entries_text([entry]).to(['changed'])
      end

      it 'substitutes with auto-swap region cancellation' do
        expect do
          editor.send_command("$,1s/#{pattern}/changed/")
          editor.send_keys 'n'
        end.not_to change { editor.lines.to_a }
      end
    end
  end

  describe 'virtual ui recovery' do
    context 'when line numbers are matched' do
      let(:pattern) { entry.line_in_window }

      it 'recovers line numbers' do
        expect { editor.send_command("%s/#{pattern}/changed/") }
          .not_to change { editor.lines.to_a }
      end
    end

    context 'when the header is matched' do
      let(:pattern) { '^Matches' }

      it 'recovers the header' do
        expect { editor.send_command("%s/#{pattern}/changed/") }
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
      let(:context_name) { 'context_name' }
      let(:pattern) { context_name }
      let(:context1) { Context.new("#{context_name}.txt", context_lines) }
      let(:context_lines) { ['_'] * 3 }

      context "when entries aren't matched" do
        let(:context_lines) { ['_'] * 3 }

        it 'recovers filenames' do
          expect { editor.send_command("%s/#{pattern}/changed/") }
            .not_to change { editor.lines.to_a }
        end
      end

      context 'when entries matched' do
        let(:context_lines) { [context_name] * 3 }

        it 'changes only entries text' do
          expect { editor.send_command("%s/#{pattern}/changed/") }
            .to change_entries_text(context1.entries)
            .and not_to_change_entries_text(entries - context1.entries)
        end
      end
    end
  end
end
