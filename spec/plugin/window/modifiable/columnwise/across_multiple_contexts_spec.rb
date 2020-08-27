# frozen_string_literal: true

require 'spec_helper'

describe 'Modifiable across multiple contexts', :window do
  include Helpers::FileSystem
  include VimlValue::SerializationHelpers
  include Helpers::Modifiable
  include Helpers::Vim
  Context ||= Helpers::Modifiable::Context

  include_context 'setup modifiable testing'

  let(:anchors) do
    ('a'..'z').to_a.last(5)
  end
  let(:context0) { Context.new('aaaaaaaa', 0.upto(4).map { |i| "aa#{i}#{anchors[i]}aa" }) }
  let(:context1) { Context.new('bbbbbbbb', 0.upto(4).map { |i| "bb#{i}#{anchors[i]}bb" }) }
  let(:context2) { Context.new('cccccccc', 0.upto(4).map { |i| "cc#{i}#{anchors[i]}cc" }) }
  let(:contexts) { [context0, context1, context2] }

  describe 'delete' do
    context 'columnwise start' do
      context 'linewise end (paragraph textobject)' do
        context 'from header' # TODO

        context 'from context 1' do
          context 'to context 0 start' do
            context 'col1 within linenr' do

              context 'from entry 0' do
                let(:entry1) { contexts[1].entries[0] }

                it 'removes context 0' do
                  entry1.line_number_text.length.times do |column|
                    editor.locate_cursor! entry1.line_in_window, column

                    expect { editor.send_keys_separately 'd2{' }
                      .not_to change { output.reload(entry1)&.line_content }
                    expect(output)
                      .to have_entries(entries)
                      .except(contexts[0].entries)
                    editor.command! 'undo 0 | undo'
                  end
                end
              end

              context 'from entry n > 0' do
                let(:entry1) { contexts[1].entries[-2] }

                it 'removes entries n > 0' do
                  entry1.line_number_text.length.times do |column|
                    editor.locate_cursor! entry1.line_in_window, column

                    expect { editor.send_keys_separately 'd2{' }
                      .not_to change { output.reload(entry1)&.line_content }
                    expect(output)
                      .to have_entries(entries)
                      .except(contexts[0].entries + contexts[1].entries[..-3])
                    editor.command! 'undo 0 | undo'
                  end
                end
              end
            end

            context 'col1 at the start of editable area' do
              context 'from entry 0' do
                let(:entry1) { contexts[1].entries[0] }
                let(:entry2) { contexts[1].entries[0] }
                let(:anchor1) { anchors[0] }
                let(:expected_text1) { entry1.line_content.partition(anchor1).first }

                it 'keeps the entry' do
                  entry1.locate!

                  expect { editor.send_keys_separately 'd2{' }
                    .not_to change { output.reload(entry1)&.line_content }
                  expect(output)
                    .to have_entries(entries)
                    .except(contexts[0].entries)
                end
              end

              context 'from entry n > 0' do
                let(:entry1) { contexts[1].entries[-2] }
                let(:entry2) { contexts[1].entries[0] }
                let(:anchor1) { anchors[-2] }
                let(:expected_text1) { entry1.line_content.partition(anchor1).first }

                it 'keeps the entry' do
                  entry1.locate!

                  expect { editor.send_keys_separately 'd2{' }
                    .not_to change { output.reload(entry1)&.line_content }
                  expect(output)
                    .to have_entries(entries)
                    .except(contexts[0].entries + contexts[1].entries[..-3])
                end
              end
            end

            context 'col1 within results text' do
              let(:entry1) { contexts[1].entries[0] }
              let(:expected_text1) do
                entry1.line_number_text +
                  anchor1 +
                  entry1.line_content.partition(anchor1).last
              end
              let(:anchor1) { anchors[0] }

              it 'removes context 0 and part of the entry' do
                entry1.locate!
                editor.press! "f#{anchor1}"

                expect { editor.send_keys_separately 'd2{' }
                  .to change { output.reload(entry1)&.line_content }
                  .to(expected_text1)

                expect(output)
                  .to have_entries(entries)
                  .except(contexts[0].entries)
              end
            end
          end
        end

        context 'from context -1' do
          context 'to context 0 start' do
            context 'col1 at the end' do
              context 'from entry -1' do
                include_context 'set options', virtualedit: 'onemore'

                let(:entry1) { contexts[-1].entries[-1] }

                it 'removes context 0 and part of the entry' do
                  editor.locate_cursor! entry1.line_in_window, '$'
                  editor.send_keys_separately 'd{'
                  expect(output)
                    .to have_entries(entries)
                    .except(contexts[-1].entries)
                end
              end
            end
          end
        end

        context 'from context 0' do
          context 'to context 1 end' do
            context 'col1 within linenr' do
              context 'from entry 0' do
                let(:entry1) { contexts[0].entries[0] }

                it 'removes context 0' do
                  entry1.line_number_text.length.times do |column|
                    editor.locate_cursor! entry1.line_in_window, column

                    editor.send_keys_separately 'd2}'
                    expect(output)
                      .to have_entries(entries)
                      .except(contexts[0].entries + contexts[1].entries)
                    editor.command! 'undo 0 | undo'
                  end
                end
              end

              context 'from entry n > 0' do
                let(:entry1) { contexts[0].entries[-2] }

                it 'removes entries n > 0' do
                  entry1.line_number_text.length.times do |column|
                    editor.locate_cursor! entry1.line_in_window, column

                    editor.send_keys_separately 'd2}'
                    expect(output)
                      .to have_entries(entries)
                      .except(contexts[0].entries[-2..-1] + contexts[1].entries)
                    editor.command! 'undo 0 | undo'
                  end
                end
              end
            end

            context 'col1 at the start of editable area' do
              context 'from entry 0' do
                let(:entry1) { contexts[0].entries[0] }
                let(:entry2) { contexts[1].entries[0] }
                let(:anchor1) { anchors[0] }
                let(:expected_text1) { entry1.line_content.partition(anchor1).first }

                it 'keeps the entry' do
                  entry1.locate!

                  # TODO: inconsistency with deletion within a single context
                  editor.send_keys_separately 'd2}'
                  expect(output)
                    .to have_entries(entries)
                    .except(contexts[0].entries + contexts[1].entries)
                end
              end

              context 'from entry n > 0' do
                let(:entry1) { contexts[0].entries[-2] }
                let(:entry2) { contexts[1].entries[0] }
                let(:anchor1) { anchors[-2] }
                let(:expected_text1) { entry1.line_content.partition(anchor1).first }

                it 'keeps the entry' do
                  entry1.locate!

                  # TODO: inconsistency with deletion within a single context
                  expect { editor.send_keys_separately 'd2}' }
                    .to change { output.reload(entry1).line_content }
                    .to(entry1.line_number_text)
                  expect(output)
                    .to have_entries(entries)
                    .except(contexts[0].entries.last(1) + contexts[1].entries)
                end
              end
            end

            context 'col1 within result text' do
              context 'from entry 0' do
                let(:entry1) { contexts[0].entries[0] }
                let(:entry2) { contexts[1].entries[0] }
                let(:anchor1) { anchors[0] }
                let(:expected_text1) { entry1.line_content.partition(anchor1).first }

                it 'keeps the entry' do
                  editor.locate_cursor! entry1.line_in_window, entry1.line_number_text.length
                  editor.press! "f#{anchor1}"

                  editor.send_keys_separately 'd2}'
                  expect(output)
                    .to have_entries(entries)
                    .except(contexts[0].entries[1..-1] + contexts[1].entries)
                end
              end

              context 'from entry n > 0' do
                let(:entry1) { contexts[0].entries[-2] }
                let(:entry2) { contexts[1].entries[0] }
                let(:anchor1) { anchors[-2] }
                let(:expected_text1) { entry1.line_content.partition(anchor1).first }

                it 'keeps the entry' do
                  editor.locate_cursor! entry1.line_in_window, entry1.line_number_text.length
                  editor.press! "f#{anchor1}"

                  editor.send_keys_separately 'd2}'
                  expect(output)
                    .to have_entries(entries)
                    .except(contexts[0].entries[-1..-1] + contexts[1].entries)

                  expect(output.reload(entry1).line_content).to eq(expected_text1)
                end
              end
            end
          end
        end
      end
    end
  end
end
