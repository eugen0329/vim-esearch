# frozen_string_literal: true

require 'spec_helper'

describe 'Modifiable window mode motions', :window do
  include Helpers::FileSystem
  include VimlValue::SerializationHelpers
  include Helpers::Modifiable

  include_context 'setup modifiable testing'

  describe 'delete within single context' do
    context 'header context' do
      shared_examples 'recover header' do |motion|
        it 'recovers header line' do
          editor.locate_line! 1
          motion.call

          expect(output).to have_entries(entries)
        end
      end

      include_examples 'recover header', -> { editor.send_keys_separately 'Vc' }
      include_examples 'recover header', -> { editor.send_keys_separately 'Vlhc' }
      include_examples 'recover header', -> { editor.send_keys_separately 'dc' }
    end

    context 'file context' do
      context 'multiple lines delete' do
        shared_context 'multiple lines delete examples' do |context_index:|
          let(:i) { context_index }

          context 'entries 0..-1 using paragraph textobject' do
            let(:entry) { contexts[i].entries.sample }

            # TODO: write unit test as well
            shared_examples 'removes entries' do |motion|
              it 'removes entries 1..-1' do
                entry.locate!
                motion.call

                # pending 'TODO is actually multicontext' if i == -1

                expect(output)
                  .to have_entries(entries)
                  .except(contexts[i].entries[1..])
              end
            end

            context 'when cursor on non-blank line' do
              include_examples 'removes entries', -> { editor.send_keys_separately 'Vipc' }
              # include_examples 'removes entries', -> { editor.send_keys_separately 'Vapc' }
              include_examples 'removes entries', -> { editor.send_keys_separately 'cip' }
              # include_examples 'removes entries', -> { editor.send_keys_separately 'cap' }
            end

            # TODO is actually multiple
            xcontext 'when cursor on a blank line' do
              let(:entry) { contexts[i].entries.first }

              include_examples 'removes entries', -> { editor.send_keys_separately 'kkVapc' }
              include_examples 'removes entries', -> { editor.send_keys_separately 'kkcap' }
              include_examples 'removes entries', -> { editor.send_keys_separately 'kk', 'Vipc' }
              # Strangely enough, but normal mode textobject doesn't capture
              # paragraph below, while visual line mode does
              include_examples "doesn't have effect after motion", -> { editor.send_keys_separately 'kkcip' }
            end
          end

          # TODO actually multiline
          xcontext 'recover context name and a blank line before' do
            shared_examples 'recover context name after motion up' do |motion|
              it 'keeps entries' do
                expect {
                  editor.locate_line! contexts[i].entries[0].line_in_window - 1
                  motion.call
                }.not_to change { editor.lines.to_a }
              end
            end

            shared_examples 'recover context name after motion down' do |motion|
              it 'keeps entries' do
                expect {
                  editor.locate_line! contexts[i].entries[0].line_in_window - 2
                  motion.call
                }.not_to change { editor.lines.to_a }
              end
            end

            include_examples 'recover context name after motion down', -> { editor.send_keys_separately 'Vjc' }
            include_examples 'recover context name after motion down', -> { editor.send_keys_separately 'cj' }
            include_examples 'recover context name after motion up',   -> { editor.send_keys_separately 'Vkc' }
            include_examples 'recover context name after motion up',   -> { editor.send_keys_separately 'ck' }
          end

          context 'delete down' do
            context 'entries 0..1' do
              shared_examples 'removes entries' do |motion|
                let(:entry) { contexts[i].entries[0] }

                it 'removes entries 0..1' do
                  entry.locate!
                  motion.call

                  expect(output).to have_entries(entries).except([contexts[i].entries[1]])
                  expect(entry.line_content).to eq(entry.line_number_text)
                end
              end

              include_examples 'removes entries', -> { editor.send_keys_separately 'Vjc' }
              include_examples 'removes entries', -> { editor.send_keys_separately 'cj' }
            end

            context 'entries 0..2' do
              shared_examples 'removes entries' do |motion|
                let(:entry) { contexts[i].entries[0] }
                it 'removes entries 0..2' do
                  entry.locate!
                  motion.call

                  expect(output).to have_entries(entries).except(contexts[i].entries[1..2])
                  expect(output.reload(entry).line_content).to eq(entry.line_number_text)
                end
              end

              include_examples 'removes entries', -> { editor.send_keys_separately 'V2jc' }
              include_examples 'removes entries', -> { editor.send_keys_separately 'c2j' }
            end

            context 'entries -2..-1' do
              shared_examples 'removes entries' do |motion|
                let(:entry) { contexts[i].entries[-2] }

                it 'removes entries 0..2' do
                  entry.locate!
                  motion.call

                  expect(output).to have_entries(entries).except([contexts[i].entries[-1]])
                  expect(output.reload(entry).line_content).to eq(entry.line_number_text)
                end
              end

              include_examples 'removes entries', -> { editor.send_keys_separately 'Vjc' }
              include_examples 'removes entries', -> { editor.send_keys_separately 'cj' }
            end
          end

          context 'delete up' do
            context 'entries 0..1' do
              shared_examples 'removes entries' do |motion|
                let(:entry_up) { contexts[i].entries[0] }
                let(:entry) { contexts[i].entries[1] }

                it 'removes entries 0..1' do
                  entry.locate!
                  motion.call

                  expect(output).to have_entries(entries).except([entry])
                  expect(output.reload(entry_up).line_content)
                    .to eq(entry_up.line_number_text)
                end
              end

              include_examples 'removes entries', -> { editor.send_keys_separately 'Vkc' }
              include_examples 'removes entries', -> { editor.send_keys_separately 'ck' }
            end

            context 'entries 0..2' do
              shared_examples 'removes entries' do |motion|
                let(:entry_up) { contexts[i].entries[0] }
                let(:entry) { contexts[i].entries[2] }

                it 'removes entries 0..2' do
                  contexts[i].entries[2].locate!
                  motion.call

                  expect(output).to have_entries(entries).except(contexts[i].entries[1..2])
                  expect(output.reload(entry_up).line_content)
                    .to eq(entry_up.line_number_text)
                end
              end

              include_examples 'removes entries', -> { editor.send_keys_separately 'V2kc' }
              include_examples 'removes entries', -> { editor.send_keys_separately 'c2k' }
            end

            context 'entries -2..-1' do
              shared_examples 'removes entries' do |motion|
                let(:entry_up) { contexts[i].entries[-2] }
                let(:entry) { contexts[i].entries[-1] }

                it 'removes entries 0..2' do
                  contexts[i].entries[-1].locate!
                  motion.call

                  expect(output).to have_entries(entries).except([entry])
                  expect(output.reload(entry_up).line_content)
                    .to eq(entry_up.line_number_text)
                end
              end

              include_examples 'removes entries', -> { editor.send_keys_separately 'Vkc' }
              include_examples 'removes entries', -> { editor.send_keys_separately 'ck' }
            end

            context 'entries 0..-1 up to context name' do
              shared_examples 'removes entries' do |motion|
                it 'removes entries 0..2' do
                  contexts[i].entries[-1].locate!
                  motion.call(contexts[i].entries[0].line_in_window - 1)


                  expect(output).to have_entries(entries).except(contexts[i].entries[1..])
                  expect(contexts[i].entries[0].line_content)
                    .to eq(contexts[i].entries[0].line_number_text)
                end
              end

              include_examples 'removes entries', ->(line) { editor.send_keys_separately "V#{line}ggc" }
              include_examples 'removes entries', ->(line) { editor.send_keys_separately "c#{line}gg" }
            end
          end
        end

        # TODO
        xcontext 'the first context' do
          include_examples 'multiple lines delete examples', context_index: 0
        end

        # TODO
        xcontext 'a context between 2 others' do
          before { expect(contexts.count).to be > 2 } # verify the setup

          include_examples 'multiple lines delete examples', context_index: 1
        end

        # TODO
        xcontext 'the last context' do
          include_examples 'multiple lines delete examples', context_index: -1
        end
      end

      context 'single line delete' do
        shared_examples 'single line delete examples' do |context_index:|
          let(:i) { context_index }

          context 'entry 0' do
            shared_examples 'removes entries' do |motion|
              it 'removes entry 0' do
                contexts[i].entries[0].locate!
                motion.call

                expect(output).to have_entries(entries)
                expect(output.reload(contexts[i].entries[0]).line_content)
                  .to eq(contexts[i].entries[0].line_number_text)
              end
            end

            include_examples 'removes entries', -> { editor.send_keys_separately 'Vc' }
            include_examples 'removes entries', -> { editor.send_keys_separately 'Vlhc' }
            include_examples 'removes entries', -> { editor.send_keys_separately 'cc' }
          end

          context 'entry -1' do
            shared_examples 'removes entries' do |motion|
              it 'removes entry -1' do
                contexts[i].entries[-1].locate!
                motion.call


                expect(output).to have_entries(entries)
                expect(output.reload(contexts[i].entries[-1]).line_content)
                  .to eq(contexts[i].entries[-1].line_number_text)
              end
            end

            include_examples 'removes entries', -> { editor.send_keys_separately 'Vc' }
            include_examples 'removes entries', -> { editor.send_keys_separately 'Vlhc' }
            include_examples 'removes entries', -> { editor.send_keys_separately 'cc' }
          end

          context 'entry from range 1..-2' do
            shared_examples 'removes entries' do |motion|
              it 'removes entry from range 1..-2' do
                expect(contexts[i].entries.count).to be > 2 # verify the setup
                contexts[i].entries[1].locate!
                motion.call


                expect(output).to have_entries(entries)
                expect(output.reload(contexts[i].entries[1]).line_content)
                  .to eq(contexts[i].entries[1].line_number_text)
                # expect(esearch.output)
                #   .to  have_missing_entries([contexts[i].entries[1]])
                #   .and have_valid_entries(contexts[i].entries - [contexts[i].entries[1]])
                #   .and have_valid_entries((contexts - [contexts[i]]).map(&:entries).flatten)
              end
            end

            include_examples 'removes entries', -> { editor.send_keys_separately 'Vc' }
            include_examples 'removes entries', -> { editor.send_keys_separately 'Vlhc' }
            include_examples 'removes entries', -> { editor.send_keys_separately 'cc' }
          end

          context 'filename ' do
            shared_examples 'recover context name' do |motion|
              it 'keeps entries' do
                expect {
                    editor.locate_line! contexts[i].entries[0].line_in_window - 1
                    sleep 0.5
                    motion.call
                }.not_to change { editor.lines.to_a }
              end
            end

            include_examples 'recover context name', -> { editor.send_keys_separately 'Vc', :escape }
            include_examples 'recover context name', -> { editor.send_keys_separately 'Vjkc', :escape }
            include_examples 'recover context name', -> { editor.send_keys_separately 'cc', :escape }
          end

          context 'blank line before context' do
            shared_examples 'recover blank line before context' do |motion|
              it 'recovers blank line before context' do
                expect {
                  editor.locate_line! contexts[i].entries[0].line_in_window - 2
                  motion.call
                }.not_to change { editor.lines.to_a }
              end
            end

            include_examples 'recover blank line before context', -> { editor.send_keys_separately 'Vc' }
            include_examples 'recover blank line before context', -> { editor.send_keys_separately 'Vjkc' }
            include_examples 'recover blank line before context', -> { editor.send_keys_separately 'cc' }
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
