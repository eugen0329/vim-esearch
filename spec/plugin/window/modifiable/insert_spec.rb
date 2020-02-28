# frozen_string_literal: true

require 'spec_helper'

describe 'Insert mode', :window do
  include Helpers::FileSystem
  include VimlValue::SerializationHelpers
  include Helpers::Modifiable
  Context ||= Helpers::Modifiable::Context

  include_context 'setup modifiable testing'

  describe 'recovering line numbers virtual interface' do
    context 'when only virtual interface is affected' do
      context 'when adding chars' do
        it 'cuts and pastes 1 char after a line number' do
          1.upto(entry.line_number_text.length) do |column|
            editor.locate_cursor! entry.line_in_window, 1
            editor.locate_column! column
            expect { editor.send_keys_separately 'i', 'z', :escape }
              .to change { esearch.output.reload(entry).line_content }
              .to eq([entry.line_number_text, 'z', entry.result_text].join)

            editor.command 'undo 0'
          end
        end

        it 'cuts and pastes n > 1 chars after a line number' do
          1.upto(entry.line_number_text.length) do |column|
            editor.locate_cursor! entry.line_in_window, 1
            editor.locate_column! column
            expect { editor.send_keys_separately 'i', 'zz', :escape }
              .to change { esearch.output.reload(entry).line_content }
              .to eq([entry.line_number_text, 'zz', entry.result_text].join)

            editor.command 'undo 0'
          end
        end
      end

      context 'when deleting chars' do
        context 'inside line number column' do
          # ...length + 1 is required because removing left doesn't affect current
          # character
          it 'recovers virtual interface after pressing BS' do
            1.upto(entry.line_number_text.length + 1) do |column|
              editor.locate_cursor! entry.line_in_window, 1
              editor.locate_column! column

              expect { editor.send_keys_separately 'i', :backspace, :escape }
                .not_to change { esearch.output.reload(entry).line_content }
            end
          end

          it 'recovers virtual interface after pressing CONTROL-w' do
            # starts from 2 to prevent removing newline
            2.upto(line_number_text.length + 1) do |column|
              editor.locate_cursor! entry.line_in_window, 1
              editor.locate_column! column

              expect { editor.send_keys 'i', '\\<C-w>', :escape }
                .not_to change { esearch.output.reload(entry).line_content }
            end
          end

          it 'recovers virtual interface after pressing DEL' do
            1.upto(line_number_text.length) do |column|
              editor.locate_cursor! entry.line_in_window, 1
              editor.locate_column! column

              expect { editor.send_keys 'i', :delete, :escape }
                .not_to change { esearch.output.reload(entry).line_content }
            end
          end
        end
      end
    end

    context 'when only result text is affected' do
      context 'when adding chars' do
        context 'before result text' do
          it "doesn't recover after adding chars" do
            editor.locate_cursor! entry.line_in_window, 1
            editor.locate_column! entry.line_number_text.length + 1
            editor.send_keys 'i'

            expect {
              editor.send_keys_separately 'zzz'
            }.to change { esearch.output.reload(entry).line_content }
              .to([entry.line_number_text, 'zzz', entry.result_text].join)
          end
        end

        context 'after result text' do
          it "doesn't recover after adding chars" do
            editor.locate_cursor! entry.line_in_window, 1
            editor.send_keys 'A'

            expect {
              editor.send_keys_separately 'zzz'
            }.to change { esearch.output.reload(entry).line_content }
              .to([entry.line_number_text, entry.result_text, 'zzz'].join)
          end
        end
      end

      context 'when deleting chars' do
        context 'before result text' do
          it "doesn't recover after adding chars" do
            editor.locate_cursor! entry.line_in_window, 1
            editor.locate_column! entry.line_number_text.length + 1
            editor.send_keys 'i'

            expect {
              editor.send_keys_separately :delete
            }.to change { esearch.output.reload(entry).line_content }
              .to([entry.line_number_text, entry.result_text[1..]].join)
          end
        end

        context 'after result text' do
          it "doesn't recover after adding chars" do
            editor.locate_cursor! entry.line_in_window, 1
            editor.send_keys 'A'

            expect {
              editor.send_keys_separately :backspace
            }.to change { esearch.output.reload(entry).line_content }
              .to([entry.line_number_text, entry.result_text[..-2]].join)
          end
        end
      end
    end

    context 'when virtual interface and result text are both affected' do
      context 'when virtual interface is deleted partially' do
        context 'when 1st char from result text is deleted' do
          it 'recovers after pressing BS' do
            editor.locate_cursor! entry.line_in_window, 1
            editor.locate_column! entry.line_number_text.length + 2 # first char of the text
            editor.send_keys 'i'

            expect {
              5.times { editor.send_keys_separately :backspace }
            }.to change { esearch.output.reload(entry).line_content }
              .to([entry.line_number_text, entry.result_text[1..]].join)
          end
        end

        context 'when 1st \s char from result text is deleted', :regression do
          let(:contexts) { [Context.new('context1.txt', [' line with a whitespace'])] }

          it 'recovers after pressing CTRL-W' do
            editor.locate_cursor! entry.line_in_window, 1
            editor.locate_column! entry.line_number_text.length + 2 # first char of the text
            editor.send_keys 'i'

            expect {
              5.times { editor.send_keys_separately '\\<C-w>' }
            }.to change { esearch.output.reload(entry).line_content }
              .to([entry.line_number_text, entry.result_text[1..]].join)
          end
        end
      end

      context 'when virtual interface is deleted entirely' do
        it 'recovers after clearing line with cc' do
          editor.locate_cursor! entry.line_in_window, 1

          expect { editor.send_keys 'cc', :escape }
            .to change { esearch.output.reload(entry).line_content }
            .to(entry.line_number_text)
        end

        it 'recovers after clearing line with S' do
          editor.locate_cursor! entry.line_in_window, 1

          expect { editor.send_keys  'S', :escape }
            .to change { esearch.output.reload(entry).line_content }
            .to(entry.line_number_text)
        end
      end
    end
  end

  describe 'recovering blank lines between contexts' do
    let(:entry) { contexts[-2].entries.last }

    context 'when deleting' do
      it 'recovers blank line after deleting left BS' do
        editor.locate_cursor! entry.line_in_window, 1
        editor.send_keys_separately 'j', 'i'

        expect {
          5.times { editor.send_keys :backspace }
        }.not_to change { editor.lines.first(3) }
      end

      it 'recovers blank line after deleting right DEL' do
        editor.locate_cursor! entry.line_in_window, 1
        editor.send_keys_separately 'j', 'i'

        5.times  do
          expect { editor.send_keys_separately :delete }
            .not_to change { editor.lines.to_a }
        end
      end
    end

    context 'when adding' do
      it 'recovers blank line after adding chars' do
        editor.locate_cursor! entry.line_in_window, 1
        editor.send_keys 'j'

        expect { editor.send_keys_separately 'i', 'zzz' }
          .not_to change { editor.lines.to_a }
      end
    end
  end

  describe 'recovering filenames' do
    let(:sample_line_number) { sample_context.line_numbers.first }

    context 'after delete' do
      context 'left' do
        it 'recovers after BS' do
          editor.locate_cursor! entry.line_in_window, 1
          editor.send_keys 'i'

          expect {
            5.times { editor.send_keys_separately :backspace }
          }.not_to change { editor.lines.to_a }
        end
      end

      context 'right' do
        it 'recovers after DEL' do
          5.times {
            editor.locate_cursor! entry.line_in_window, 1
            editor.send_keys 'i'
            expect { editor.send_keys_separately :delete, :escape } .not_to change { editor.lines.to_a }
          }
        end

        it 'recovers after DEL at the last column (line deletion)' do
          editor.locate_cursor! 1, 4
          editor.send_keys 'A'

          expect {
            5.times { editor.send_keys_separately :delete }
          }.not_to change { editor.lines.to_a }
        end
      end

      context 'after clearing the entire line' do
        it 'recovers filename after clearing line with cc' do
          editor.locate_cursor! entry.line_in_window, 1
          editor.send_keys 'k'

          expect { editor.send_keys 'cc' }
            .not_to change { editor.lines.to_a }
        end
      end
    end

    context 'after add' do
      it 'recovers filename after adding characters' do
        editor.locate_cursor! entry.line_in_window, 1
        editor.send_keys 'k'

        expect { editor.send_keys_separately 'i', 'zzz' }
          .not_to change { editor.lines.to_a }
      end
    end
  end

  describe 'recovering header' do
    context 'after delete' do
      context 'left' do
        it 'recovers after BS' do
          editor.locate_cursor! 1, 5
          editor.send_keys 'i'

          expect {
            5.times { editor.send_keys_separately :backspace }
          }.not_to change { editor.lines.to_a }
        end
      end

      context 'right' do
        it 'recovers after DEL' do
          editor.locate_cursor! 1, 5
          editor.send_keys_separately 'i'

          expect {
            5.times { editor.send_keys_separately :delete }
          } .not_to change { editor.lines.to_a }
        end

        it 'recovers after DEL at the last column (line deletion)' do
          editor.locate_cursor! 1, 4
          editor.send_keys 'A'

          expect {
            5.times { editor.send_keys_separately :delete }
          }.not_to change { editor.lines.to_a }
        end
      end

      context 'after clearing the entire line' do
        it 'recovers after clearing line with cc' do
          editor.locate_cursor! 1, 5

          expect {
            editor.send_keys 'cc'
          }.not_to change { editor.lines.to_a }
        end
      end
    end

    context 'after add' do
      it 'recovers after adding characters' do
        editor.locate_cursor! 1, 5
        editor.send_keys 'i'

        expect {
          5.times { editor.send_keys_separately 'zzz' }
        }.not_to change { editor.lines.to_a }
      end
    end
  end

  describe 'recovering blank line after header' do
    context 'after delete' do
      context 'left' do
        it 'recovers after deleting newling left with BS' do
          editor.locate_line! 2
          editor.send_keys 'i'

          expect {
            5.times { editor.send_keys_separately :backspace }
          }.not_to change { editor.lines.to_a }
        end
      end

      context 'right' do
        it 'recovers after deleting newline right with DEL' do
          5.times do
            editor.locate_line! 2
            editor.send_keys 'A'
            expect { editor.send_keys_separately :delete }
              .not_to change { editor.lines.to_a }
          end
        end
      end

      context 'after clearing the entire line' do
        it 'recovers after clearing line with cc' do
          editor.locate_line! 2

          expect {
            editor.send_keys 'cc'
          }.not_to change { editor.lines.to_a }
        end
      end
    end

    context 'after add' do
      it 'recovers after adding characters' do
        editor.locate_line! 2
        editor.send_keys 'i'

        expect {
          editor.send_keys_separately 'zzz'
        }.not_to change { editor.lines.to_a }
      end
    end
  end

  describe 'recover after inserting newlines' do
    before { editor.locate_line! rand(1..editor.lines_count) }

    context 'when inserting a single newline' do
      it 'recovers current line' do
        editor.send_keys 'i'

        expect { editor.send_keys_separately "\n" }
          .not_to change { editor.lines.to_a }
      end
    end

    context 'when pasting large text with newlines' do
      let(:pasted_text) { (['a' * 100] * 100).join("\n") }

      it 'recovers current line' do
        editor.send_keys 'i'

        expect { editor.send_keys_separately pasted_text }
          .not_to change { editor.lines.to_a }
      end
    end
  end
end
