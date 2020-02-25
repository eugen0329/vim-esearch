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

      context 'columnwise end (visual selection)' do
        context 'from context 0' do
          context 'col1 within line number' do
            context 'to context 1' do
              context 'to an entry' do
                shared_examples 'recovering with splitting text from different contexts' do
                  let(:entry1) { contexts[0].entries[-2] }
                  let(:entry2) { contexts[1].entries[0] }
                  let(:expected_text2) do
                    entry2.line_number_text +
                      entry2.line_content.partition(anchor2).last
                  end

                  it 'recovers 1st ctx linenr and 2nd ctx linenr with remained text' do
                    columns_testing_matrix.each do |column1, column2|
                      editor.locate_cursor! entry1.line_in_window, column1
                      editor.send_keys_separately 'v'
                      editor.locate_cursor! entry2.line_in_window, column2

                      expect { editor.send_keys 'x' }
                        .to change { output.reload(entry1).line_content }
                        .to(entry1.line_number_text)
                        .and not_to_change { output.reload(entry2).line_content }
                      expect(esearch.output)
                        .to have_entries(entries).except([contexts[0].entries[-1]])

                      editor.command 'undo 0 | undo'
                    end
                  end
                end

                context 'from within line number virtual interface' do
                  context 'while moving down' do
                    include_examples 'recovering with splitting text from different contexts' do
                      let(:columns_testing_matrix) do
                        1.upto(entry1.line_number_text.length - 1) .to_a
                         .product(1.upto(entry2.line_number_text.length - 1).to_a)
                      end
                    end
                  end

                  context 'while moving up' do
                    include_examples 'recovering with splitting text from different contexts' do
                      let(:columns_testing_matrix) do
                        1.upto(entry2.line_number_text.length - 1).to_a
                         .product(1.upto(entry1.line_number_text.length - 1).to_a)
                      end
                    end
                  end
                end

                context 'from within results text start' do
                  context 'while moving down' do
                    include_examples 'recovering with splitting text from different contexts' do
                      let(:columns_testing_matrix) do
                        [entry1.line_number_text.length, entry2.line_number_text.length]
                      end
                    end
                  end

                  context 'while moving up' do
                    include_examples 'recovering with splitting text from different contexts' do
                      let(:columns_testing_matrix) do
                        [entry2.line_number_text.length, entry1.line_number_text.length]
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end

      context 'columnwise end (f{char})' do
        context 'from context 0' do
          context 'col1 within line number' do
            context 'to context 1' do
              context 'to an entry' do
                let(:entry1) { contexts[0].entries[-2] }
                let(:entry2) { contexts[1].entries[0] }
                let(:anchor1) { anchors[-2] }
                let(:anchor2) { anchors[0] }
                let(:expected_text2) do
                  entry2.line_number_text +
                    entry2.line_content.partition(anchor2).last
                end

                it do
                  entry1.line_number_text.length.times do |column|
                    entry1.locate!
                    editor.locate_column! column

                    expect { editor.send_keys_separately "df#{anchor2}" }
                      .to change { output.reload(entry1)&.line_content }
                      .to(entry1.line_number_text)
                      .and change { output.reload(entry2)&.line_content }
                      .to(expected_text2)
                    expect(output)
                      .to have_entries(entries).except([contexts[0].entries[-1]])
                    editor.command! 'undo 0 | undo'
                  end
                end
              end

              context 'to filename' do
                let(:entry1) { contexts[0].entries[-2] }
                let(:entry2) { contexts[1].entries[0] }
                let(:anchor1) { anchors[-2] }
                let(:expected_text1) { entry1.line_content.partition(anchor1).first }

                it do
                  entry1.line_number_text.length.times do |column|
                    entry1.locate!
                    editor.locate_column! column + 1
                    expect { editor.send_keys_separately 'dfb' }
                      .not_to change { output.reload(entry2)&.line_content }
                    expect(output).to have_entries(entries).except([contexts[0].entries[-1]])
                    editor.command! 'undo 0 | undo'
                  end
                end
              end
            end

            context 'to context 2' do
              context 'to an entry' do
                let(:context1) { Context.new('bbbbbbbb', 0.upto(4).map { |i| "bb#{i}bb" }) }
                let(:entry1) { contexts[0].entries[-2] }
                let(:entry2) { contexts[2].entries[0] }
                let(:anchor1) { anchors[-2] }
                let(:anchor2) { anchors[0] }
                let(:expected_text2) do
                  entry2.line_number_text +
                    entry2.line_content.partition(anchor2).last
                end

                it do
                  entry1.line_number_text.length.times do |column|
                    entry1.locate!
                    editor.locate_column! column

                    expect { editor.send_keys_separately "df#{anchor2}" }
                      .to change { output.reload(entry1)&.line_content }
                      .to(entry1.line_number_text)
                      .and change { output.reload(entry2)&.line_content }
                      .to(expected_text2)
                    expect(output)
                      .to have_entries(entries)
                      .except([contexts[0].entries[-1]] + contexts[1].entries)
                    editor.command! 'undo 0 | undo'
                  end
                end
              end

              context 'to filename' do
                let(:entry1) { contexts[0].entries[-2] }
                let(:entry2) { contexts[2].entries[0] }
                let(:anchor1) { anchors[-2] }
                let(:expected_text1) { entry1.line_content.partition(anchor1).first }

                it do
                  entry1.line_number_text.length.times do |column|
                    entry1.locate!
                    editor.locate_column! column + 1
                    expect { editor.send_keys_separately 'dfc' }
                      .not_to change { output.reload(entry2)&.line_content }
                    expect(output)
                      .to have_entries(entries)
                      .except([contexts[0].entries[-1]] + contexts[1].entries)
                    editor.command! 'undo 0 | undo'
                  end
                end
              end
            end
          end

          context 'col1 at the start of editable area' do
            context 'to context 1' do
              context 'to an entry' do
                let(:entry1) { contexts[0].entries[-2] }
                let(:entry2) { contexts[1].entries[0] }
                let(:anchor1) { anchors[-2] }
                let(:anchor2) { anchors[0] }
                let(:expected_text1) { entry1.line_content.partition(anchor1).first }
                let(:expected_text2) { entry2.line_number_text + entry2.line_content.partition(anchor2).last }

                it do
                  entry1.locate!

                  expect { editor.send_keys_separately "df#{anchor2}" }
                    .to change { output.reload(entry1)&.line_content }
                    .to(entry1.line_number_text)
                    .and change { output.reload(entry2)&.line_content }
                    .to(expected_text2)
                  expect(output)
                    .to have_entries(entries).except([contexts[0].entries[-1]])
                end
              end

              context 'to filename' do
                let(:entry1) { contexts[0].entries[-2] }
                let(:anchor1) { anchors[-2] }
                let(:expected_text1) { entry1.line_content.partition(anchor1).first }

                it do
                  entry1.locate!

                  expect { editor.send_keys_separately 'dfb' }
                    .to change { output.reload(entry1)&.line_content }
                    .to(entry1.line_number_text)
                  expect(output)
                    .to have_entries(entries).except([contexts[0].entries[-1]])
                end
              end
            end

            context 'to context 2' do
              context 'to an entry' do
                let(:context1) { Context.new('bbbbbbbb', 0.upto(4).map { |i| "bb#{i}bb" }) }
                let(:entry1) { contexts[0].entries[-2] }
                let(:entry2) { contexts[2].entries[0] }
                let(:anchor1) { anchors[-2] }
                let(:anchor2) { anchors[0] }
                let(:expected_text2) do
                  entry2.line_number_text +
                    entry2.line_content.partition(anchor2).last
                end

                it do
                  entry1.locate!

                  expect { editor.send_keys_separately "df#{anchor2}" }
                    .to change { output.reload(entry1)&.line_content }
                    .to(entry1.line_number_text)
                    .and change { output.reload(entry2)&.line_content }
                    .to(expected_text2)
                  expect(output)
                    .to have_entries(entries)
                    .except([contexts[0].entries[-1]] + contexts[1].entries)
                end
              end

              context 'to filename' do
                let(:entry1) { contexts[0].entries[-2] }
                let(:entry2) { contexts[2].entries[0] }
                let(:anchor1) { anchors[-2] }
                let(:expected_text1) { entry1.line_content.partition(anchor1).first }

                it do
                  entry1.locate!
                  expect { editor.send_keys_separately 'dfc' }
                    .not_to change { output.reload(entry2)&.line_content }
                  expect(output)
                    .to have_entries(entries)
                    .except([contexts[0].entries[-1]] + contexts[1].entries)
                end
              end
            end
          end

          context 'col1 within result text' do
            context 'to context 1' do
              context 'to an entry' do
                let(:entry1) { contexts[0].entries[-2] }
                let(:entry2) { contexts[1].entries[0] }
                let(:anchor1) { anchors[-2] }
                let(:anchor2) { anchors[0] }
                let(:expected_text1) { entry1.line_content.partition(anchor1).first }
                let(:expected_text2) { entry2.line_number_text + entry2.line_content.partition(anchor2).last }

                it do
                  entry1.locate!
                  editor.press! "f#{anchor1}"

                  expect { editor.send_keys_separately "df#{anchor2}" }
                    .to change { output.reload(entry1)&.line_content }
                    .to(expected_text1)
                    .and change { output.reload(entry2)&.line_content }
                    .to(expected_text2)
                  expect(output)
                    .to have_entries(entries).except([contexts[0].entries[-1]])
                end
              end

              context 'to filename' do
                let(:entry1) { contexts[0].entries[-2] }
                let(:anchor1) { anchors[-2] }
                let(:expected_text1) { entry1.line_content.partition(anchor1).first }

                it do
                  entry1.locate!
                  editor.press! "f#{anchor1}"

                  expect { editor.send_keys_separately 'dfb' }
                    .to change { output.reload(entry1)&.line_content }
                    .to(expected_text1)
                  expect(output)
                    .to have_entries(entries).except([contexts[0].entries[-1]])
                end
              end
            end
          end
        end
      end
    end
  end
end
