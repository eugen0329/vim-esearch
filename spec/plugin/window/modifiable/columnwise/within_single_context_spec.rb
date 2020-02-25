# frozen_string_literal: true

require 'spec_helper'

describe 'within single context', :window do
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
  let(:contexts) do
    [context0, context1, context2]
  end

  describe 'delete' do
    context 'within header' do
      it do
        editor.locate_cursor! 1, 5
        expect { editor.press! 'd}' }.not_to change { editor.lines.to_a }
      end
    end

    context 'within regular file context' do
      context 'linewise end' do
        shared_examples 'single line delete examples' do |context_index:|
          let(:i) { context_index }

          context 'entry -1 from entry -2' do
            let(:entry) { contexts[i].entries[-2] }
            let(:anchor) { anchors[-2] }
            let(:expected_text) { entry.line_content.partition(anchor).first }

            it 'removes entry -1 and clears text after col1' do
              entry.locate!
              editor.press! "f#{anchor}"

              expect { editor.press! 'd}' }
                .to change { output.reload(entry).line_content }
                .to(expected_text)
              expect(esearch.output)
                .to have_entries(entries).except([contexts[i].entries[-1]])
            end
          end

          context 'filename' do
            let(:entry) { contexts[i].entries[0] }
            let(:anchor) { anchors[0] }
            let(:expected_text) { entry.line_content.partition(anchor).last }

            it do
              editor.locate_cursor! entry.line_in_window - 1, 5
              editor.press! 'd}'
              expect(output)
                .to have_entries(entries).except(contexts[i].entries)
            end

            it do
              editor.locate_cursor! entry.line_in_window - 1, 5
              editor.press! 'd{'
              expect(output).to have_entries(entries)
            end

            it do
              editor.locate_cursor! entry.line_in_window - 1, 1
              editor.press! 'd{'
              expect(output).to have_entries(entries)
            end
          end

        end

        shared_examples 'down from separator before context' do |context_index:|
          let(:i) { context_index }
          context 'separator after context' do
            let(:entry) { contexts[i].entries[0] }
            let(:anchor) { anchors[0] }
            let(:expected_text) { entry.line_content.partition(anchor).last }

            it 'recovers blank line before context' do
              editor.locate_cursor! entry.line_in_window - 2, 5
              editor.press! 'd}'

              expect(output)
                .to have_entries(entries).except(contexts[i].entries)
            end
          end
        end

        shared_examples 'up from separator after context' do |context_index:|
          let(:i) { context_index }
          context 'separator after context' do
            let(:entry) { contexts[i].entries[0] }
            let(:anchor) { anchors[0] }
            let(:expected_text) { entry.line_content.partition(anchor).last }

            it 'recovers blank line before context' do
              editor.locate_cursor! contexts[i].entries[-1].line_in_window + 1, 1
              editor.press! 'd{'

              expect(output).to have_entries(entries).except(contexts[i].entries)
            end
          end
        end

        context 'the first context' do
          include_examples 'single line delete examples', context_index: 0
          include_examples 'up from separator after context', context_index: 0
          include_examples 'down from separator before context', context_index: 0
        end

        context 'a context between 2 others' do
          before { expect(contexts.count).to be > 2 } # verify the setup

          include_examples 'single line delete examples', context_index: 1
          include_examples 'up from separator after context', context_index: 1
          include_examples 'down from separator before context', context_index: 1
        end

        context 'the last context' do
          include_examples 'single line delete examples', context_index: -1
          include_examples 'down from separator before context', context_index: -1

          context 'up from entry -1' do
            # TODO: test for all contexts

            context 'from column in the middle' do
              let(:entry1) { contexts[-1].entries[-1] }
              let(:anchor1) { anchors[-1] }
              let!(:expected_text) do
                entry1.line_number_text + anchor1 + entry1.line_content.partition(anchor1).last
              end

              it do
                entry1.locate!
                editor.press! "f#{anchor1}"

                expect { editor.send_keys 'd{' }
                  .to change { output.reload(entry1).line_content }
                  .to(expected_text)

                expect(esearch.output)
                  .to have_entries(entries).except(contexts[-1].entries[..-2])
              end
            end

            context 'from last column' do
              let(:entry1) { contexts[-1].entries[-1] }
              let(:anchor1) { anchors[-1] }
              let!(:expected_text) do
                entry1.line_number_text +
                  entry1.line_content.chars.last
              end

              it do
                entry1.locate!
                editor.locate_column! entry1.line_content.length

                expect { editor.send_keys 'd{' }
                  .to change { output.reload(entry1).line_content }
                  .to(expected_text)

                expect(esearch.output)
                  .to have_entries(entries).except(contexts[-1].entries[..-2])
              end
            end

            context 'from virtual column ($ + 1)' do
              let(:entry1) { contexts[-1].entries[-1] }
              let(:anchor1) { anchors[-1] }

              include_context 'set options', {virtualedit: 'onemore'}

              it do
                entry1.locate!
                editor.locate_column! entry1.line_content.length + 1

                editor.send_keys_separately 'd{'

                expect(esearch.output).to have_entries(entries).except(contexts[-1].entries)
              end
            end
          end
        end
      end

      context 'columnwise end' do
        shared_examples 'single line delete examples' do |context_index:|
          let(:i) { context_index }

          context 'from entry n to entry n+1' do
            let(:entry1) { contexts[i].entries[-2] }
            let(:entry2) { contexts[i].entries[-1] }

            context 'using visual selection' do
              shared_examples 'replacing 1st entry text with 2nd entry' do
                let(:expected_text) { entry1.line_number_text + entry2.result_text }

                it do
                  columns_testing_matrix.each do |column1, column2|
                    editor.locate_cursor! entry1.line_in_window, column1
                    editor.send_keys_separately 'v'
                    editor.locate_cursor! entry2.line_in_window, column2

                    expect { editor.send_keys 'x' }
                      .to change { output.reload(entry1).line_content }
                      .to(expected_text)
                    expect(esearch.output)
                      .to have_entries(entries).except([contexts[i].entries[-1]])

                    editor.command 'undo 0 | undo'
                  end
                end
              end

              context 'from within line number virtual interface' do
                context 'while moving down' do
                  include_examples 'replacing 1st entry text with 2nd entry' do
                    let(:columns_testing_matrix) do
                      1.upto(entry1.line_number_text.length - 1) .to_a
                       .product(1.upto(entry2.line_number_text.length - 1).to_a)
                    end
                  end
                end

                context 'while moving up' do
                  include_examples 'replacing 1st entry text with 2nd entry' do
                    let(:columns_testing_matrix) do
                      1.upto(entry2.line_number_text.length - 1).to_a
                       .product(1.upto(entry1.line_number_text.length - 1).to_a)
                    end
                  end
                end
              end

              context 'from within results text start' do
                context 'while moving down' do
                  include_examples 'replacing 1st entry text with 2nd entry' do
                    let(:columns_testing_matrix) do
                      [entry1.line_number_text.length, entry2.line_number_text.length]
                    end
                  end
                end

                context 'while moving up' do
                  include_examples 'replacing 1st entry text with 2nd entry' do
                    let(:columns_testing_matrix) do
                      [entry2.line_number_text.length, entry1.line_number_text.length]
                    end
                  end
                end
              end
            end

            context 'using f{char}' do
              let(:anchor1) { anchors[-2] }
              let(:anchor2) { anchors[-1] }

              context 'from within line number virtual interface' do
                let(:expected_text) do
                  entry1.line_number_text +
                    entry2.line_content.partition(anchor2).last
                end

                it 'keeps 1st entry line number 2nd entry text after anchor' do
                  1.upto(entry1.line_number_text.length) do |column|
                    editor.locate_cursor! entry1.line_in_window, column

                    expect { editor.send_keys "df#{anchor2}" }
                      .to change { output.reload(entry1).line_content }
                      .to(expected_text)
                    expect(esearch.output)
                      .to have_entries(entries).except([contexts[i].entries[-1]])

                    editor.command 'undo 0 | undo'
                  end
                end
              end

              context 'col1 on result text first column' do
                let(:expected_text) do
                  entry1.line_number_text +
                    entry2.line_content.partition(anchor2).last
                end

                it 'keeps 1st entry line number 2nd entry text after anchor' do
                  entry1.locate!
                  editor.locate_column! entry1.line_number_text.length

                  expect { editor.send_keys "df#{anchor2}" }
                    .to change { output.reload(entry1).line_content }
                    .to(expected_text)
                  expect(esearch.output)
                    .to have_entries(entries).except([contexts[i].entries[-1]])
                end
              end

              context 'col1 is within the result text' do
                let(:expected_text) do
                  entry1.line_content.partition(anchor1).first +
                    entry2.line_content.partition(anchor2).last
                end

                it do
                  entry1.locate!
                  editor.press! "f#{anchor1}"

                  expect { editor.send_keys "df#{anchor2}" }
                    .to change { output.reload(entry1).line_content }
                    .to(expected_text)
                  expect(esearch.output)
                    .to have_entries(entries).except([contexts[i].entries[-1]])
                end
              end
            end
          end

          context 'from header' do
            context 'using f{char}' do
              context 'to entry' do
                let(:entry) { contexts[0].entries[0] }
                let(:anchor) { anchors[0] }
                let(:expected_text) do
                  entry.line_number_text + entry.line_content.partition(anchor).last
                end

                it do
                  editor.locate_cursor! 1, 5
                  expect { editor.send_keys "df#{anchor}" }
                    .to change { output.reload(entry).line_content }
                    .to(expected_text)
                  expect(output).to have_entries(entries)
                end
              end

              context 'to entry name' do
                let(:entry) { contexts[0].entries[0] }
                let(:anchor) { anchors[0] }
                let(:expected_text) do
                  entry.line_number_text + entry.line_content.partition(anchor).last
                end

                it do
                  editor.locate_cursor! 1, 5
                  expect { editor.send_keys 'dfa' }
                    .not_to change { editor.lines.to_a }
                  expect(output).to have_entries(entries)
                end
              end
            end
          end

          context 'from filename' do
            context 'using f{char}' do
              context 'to entry 0' do
                let(:entry) { contexts[i].entries[0] }
                let(:anchor) { anchors[0] }
                let(:expected_text) { entry.line_number_text + entry.line_content.partition(anchor).last }

                it do
                  editor.locate_cursor! entry.line_in_window - 1, 5

                  expect { editor.send_keys "df#{anchor}" }
                    .to change { output.reload(entry).line_content }
                    .to(expected_text)
                  expect(output).to have_entries(entries)
                end
              end

              context 'to entry n > 0 ' do
                let(:entry) { contexts[i].entries[2] }
                let(:anchor) { anchors[2] }
                let(:expected_text) { entry.line_number_text + entry.line_content.partition(anchor).last }

                it do
                  editor.locate_cursor! contexts[i].entries.first.line_in_window - 1, 5

                  expect { editor.send_keys "df#{anchor}" }
                    .to change { output.reload(entry)&.line_content }
                    .to(expected_text)
                  expect(output)
                    .to have_entries(entries).except(contexts[i].entries[...2])
                end
              end
            end
          end

          context 'from separator before a context' do # move to multicontext tests?
            context 'f{char}' do
              context 'to entry 3' do
                let(:entry) { contexts[i].entries[2] }
                let(:anchor) { anchors[2] }
                let(:expected_text) { entry.line_number_text + entry.line_content.partition(anchor).last }

                it do
                  editor.locate_line! contexts[i].entries.first.line_in_window - 2

                  expect { editor.send_keys "df#{anchor}" }
                    .to change { output.reload(entry)&.line_content }
                    .to(expected_text)
                  expect(output)
                    .to have_entries(entries).except(contexts[i].entries[...2])
                end
              end
            end
          end
        end

        context 'the first context' do
          include_examples 'single line delete examples', context_index: 0
        end

        context 'a context between 2 others' do
          before { expect(contexts.count).to be > 2 } # verify the setup

          include_examples 'single line delete examples', context_index: 1
        end

        context 'the last context' do
          include_examples 'single line delete examples', context_index: -1
        end
      end
    end
  end
end
