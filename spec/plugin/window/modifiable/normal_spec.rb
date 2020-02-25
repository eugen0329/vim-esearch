# frozen_string_literal: true

require 'spec_helper'

describe 'Normal mode', :window do
  include Helpers::FileSystem
  include VimlValue::SerializationHelpers
  include Helpers::Modifiable

  include_context 'setup modifiable testing'

  describe 'inline' do
    context 'restoring line numbers' do
      context 'when only virtual interface is affected' do
        it 'recovers virtual interface after deleting 1 char' do
          1.upto(line_number_text.length) do |column|
            entry.locate!
            editor.locate_column! column

            expect { editor.send_keys 'x' }.not_to change { editor.lines.to_a }
          end
        end

        it 'recovers virtual interface after motion left' do
          1.upto(line_number_text.length) do |column|
            entry.locate!
            editor.locate_column! column

            expect { editor.send_keys "#{line_number_text.length}dh" }
              .not_to change { editor.lines.to_a }
          end
        end

        it 'recovers virtual interface after motion right' do
          1.upto(line_number_text.length - 1) do |column|
            entry.locate!
            editor.locate_column! column

            expect { editor.send_keys "#{line_number_text.length - column}dl" }
              .not_to change { editor.lines.to_a }
          end
        end
      end

      context 'when only result text is affected' # TODO

      context 'when virtual interface and result text is affected' do
        context 'when virtual interface is deleted partially' do
          it 'recovers after deleting until the end' do
            entry.locate!
            editor.locate_column! 2

            expect { editor.send_keys 'D' }
              .not_to change { editor_lines_except(entry.line_in_window) }
            expect(editor.line(entry.line_in_window)).to eq(line_number_text)
          end

          it 'recovers after deleting with motion' do
            entry.locate!
            editor.locate_column! 2

            expect { editor.send_keys "#{line_number_text.length}dl" }
              .to change { esearch.output.reload(entry).line_content }
              .to([line_number_text, entry.result_text[1..]].join)
          end
        end

        context 'when virtual interface is deleted entirely' do
          it 'recovers after clearing the line from the start' do
            entry.locate!
            expect { editor.send_keys '0D' }
              .not_to change { editor_lines_except(entry.line_in_window) }
            expect(editor.line(entry.line_in_window)).to eq(line_number_text)
          end

          it 'recovers after clearing the line from the end' do
            entry.locate!

            expect { editor.send_keys '$d0' }
              .not_to change { editor_lines_except(entry.line_in_window) }
            expect(editor.line(entry.line_in_window)).to eq(line_number_text)
          end
        end
      end
    end
  end
end
