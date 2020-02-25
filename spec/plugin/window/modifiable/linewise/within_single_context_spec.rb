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
          5.times do
            editor.locate_line! 1
            instance_exec(&motion)
          end

          expect(esearch.output).to have_valid_entries(contexts.map(&:entries).flatten)
        end
      end

      include_examples 'recover header', -> { editor.send_keys_separately 'Vd' }
      include_examples 'recover header', -> { editor.send_keys_separately 'Vddd' }
      include_examples 'recover header', -> { editor.send_keys_separately 'Vlhd' }
      include_examples 'recover header', -> { editor.send_keys_separately 'dd' }
      include_examples 'recover header', -> { editor.send_keys_separately 'ddVd' }
    end

    context 'file context' do
      context 'multiple lines delete' do
        shared_context 'multiple lines delete examples' do |context_index:|
          let(:i) { context_index }

          context 'entries 0..-1 using paragraph textobject' do
            let(:entry) { contexts[i].entries.sample }

            # TODO: write unit test as well
            shared_examples 'removes entries' do |motion|
              it 'removes entries 0..-1' do
                entry.locate!
                instance_exec(&motion)

                expect(esearch.output)
                  .to  have_missing_entries(contexts[i].entries)
                  .and have_valid_entries((contexts - [contexts[i]]).map(&:entries).flatten)
              end
            end

            context 'when cursor on non-blank line' do
              include_examples 'removes entries', -> { editor.send_keys_separately 'Vipd' }
              include_examples 'removes entries', -> { editor.send_keys_separately 'Vapd' }
              include_examples 'removes entries', -> { editor.send_keys_separately 'dip' }
              include_examples 'removes entries', -> { editor.send_keys_separately 'dap' }
            end

            context 'when cursor on a blank line' do
              let(:entry) { contexts[i].entries.first }

              include_examples 'removes entries', -> { editor.send_keys_separately 'kkVapd' }
              include_examples 'removes entries', -> { editor.send_keys_separately 'kkdap' }
              include_examples 'removes entries', -> { editor.send_keys_separately 'kk', 'Vipd' }
              # Strangely enough, but normal mode textobject doesn't capture
              # paragraph below, while visual line mode does
              include_examples "doesn't have effect after motion", -> { editor.send_keys_separately 'kkdip' }
            end
          end

          context 'recover context name and a blank line before' do
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

            include_examples 'recover context name after motion down', -> { editor.send_keys_separately 'Vjd' }
            include_examples 'recover context name after motion down', -> { editor.send_keys_separately 'dj' }
            include_examples 'recover context name after motion up',   -> { editor.send_keys_separately 'Vkd' }
            include_examples 'recover context name after motion up',   -> { editor.send_keys_separately 'dk' }
          end

          context 'delete down' do
            context 'entries 0..1' do
              shared_examples 'removes entries' do |motion|
                it 'removes entries 0..1' do
                  contexts[i].entries[0].locate!
                  instance_exec(&motion)

                  expect(esearch.output)
                    .to  have_missing_entries(contexts[i].entries[..1])
                    .and have_valid_entries(contexts[i].entries[2..])
                    .and have_valid_entries((contexts - [contexts[i]]).map(&:entries).flatten)
                end
              end

              include_examples 'removes entries', -> { editor.send_keys_separately 'Vjd' }
              include_examples 'removes entries', -> { editor.send_keys_separately 'dj' }
            end

            context 'entries 0..2' do
              shared_examples 'removes entries' do |motion|
                it 'removes entries 0..2' do
                  contexts[i].entries[0].locate!
                  instance_exec(&motion)

                  expect(esearch.output)
                    .to  have_missing_entries(contexts[i].entries[..2])
                    .and have_valid_entries(contexts[i].entries[3..])
                    .and have_valid_entries((contexts - [contexts[i]]).map(&:entries).flatten)
                end
              end

              include_examples 'removes entries', -> { editor.send_keys_separately 'V2jd' }
              include_examples 'removes entries', -> { editor.send_keys_separately 'd2j' }
            end

            context 'entries -2..-1' do
              shared_examples 'removes entries' do |motion|
                it 'removes entries 0..2' do
                  contexts[i].entries[-2].locate!
                  instance_exec(&motion)

                  expect(esearch.output)
                    .to  have_missing_entries(contexts[i].entries[-2..])
                    .and have_valid_entries(contexts[i].entries[..-3])
                    .and have_valid_entries((contexts - [contexts[i]]).map(&:entries).flatten)
                end
              end

              include_examples 'removes entries', -> { editor.send_keys_separately 'Vjd' }
              include_examples 'removes entries', -> { editor.send_keys_separately 'dj' }
            end
          end

          context 'delete up' do
            context 'entries 0..1' do
              shared_examples 'removes entries' do |motion|
                it 'removes entries 0..1' do
                  contexts[i].entries[1].locate!
                  instance_exec(&motion)

                  expect(esearch.output)
                    .to  have_missing_entries(contexts[i].entries[..1])
                    .and have_valid_entries(contexts[i].entries[2..])
                    .and have_valid_entries((contexts - [contexts[i]]).map(&:entries).flatten)
                end
              end

              include_examples 'removes entries', -> { editor.send_keys_separately 'Vkd' }
              include_examples 'removes entries', -> { editor.send_keys_separately 'dk' }
            end

            context 'entries 0..2' do
              shared_examples 'removes entries' do |motion|
                it 'removes entries 0..2' do
                  contexts[i].entries[2].locate!
                  instance_exec(&motion)

                  expect(esearch.output)
                    .to  have_missing_entries(contexts[i].entries[..2])
                    .and have_valid_entries(contexts[i].entries[3..])
                    .and have_valid_entries((contexts - [contexts[i]]).map(&:entries).flatten)
                end
              end

              include_examples 'removes entries', -> { editor.send_keys_separately 'V2kd' }
              include_examples 'removes entries', -> { editor.send_keys_separately 'd2k' }
            end

            context 'entries -2..-1' do
              shared_examples 'removes entries' do |motion|
                it 'removes entries 0..2' do
                  contexts[i].entries[-1].locate!
                  instance_exec(&motion)

                  expect(esearch.output)
                    .to  have_missing_entries(contexts[i].entries[-2..])
                    .and have_valid_entries(contexts[i].entries[..-3])
                    .and have_valid_entries((contexts - [contexts[i]]).map(&:entries).flatten)
                end
              end

              include_examples 'removes entries', -> { editor.send_keys_separately 'Vkd' }
              include_examples 'removes entries', -> { editor.send_keys_separately 'dk' }
            end

            context 'entries 0..-1 up to context name' do
              shared_examples 'removes entries' do |motion|
                it 'removes entries 0..2' do
                  contexts[i].entries[-1].locate!
                  motion.call(contexts[i].entries[0].line_in_window - 1)

                  expect(esearch.output)
                    .to  have_missing_entries(contexts[i].entries)
                    .and have_valid_entries((contexts - [contexts[i]]).map(&:entries).flatten)
                end
              end

              include_examples 'removes entries', ->(line) { editor.send_keys_separately "V#{line}ggd" }
              include_examples 'removes entries', ->(line) { editor.send_keys_separately "d#{line}gg" }
            end
          end
        end

        context 'the first context' do
          include_examples 'multiple lines delete examples', context_index: 0
        end

        context 'a context between 2 others' do
          before { expect(contexts.count).to be > 2 } # verify the setup

          include_examples 'multiple lines delete examples', context_index: 1
        end

        context 'the last context' do
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
                instance_exec(&motion)

                expect(esearch.output)
                  .to  have_missing_entries(contexts[i].entries[..0])
                  .and have_valid_entries(contexts[i].entries[1..])
                  .and have_valid_entries((contexts - [contexts[i]]).map(&:entries).flatten)
              end
            end

            include_examples 'removes entries', -> { editor.send_keys_separately 'Vd' }
            include_examples 'removes entries', -> { editor.send_keys_separately 'Vlhd' }
            include_examples 'removes entries', -> { editor.send_keys_separately 'dd' }
          end

          context 'entry -1' do
            shared_examples 'removes entries' do |motion|
              it 'removes entry -1' do
                contexts[i].entries[-1].locate!
                instance_exec(&motion)

                expect(esearch.output)
                  .to  have_missing_entries(contexts[i].entries[-1..])
                  .and have_valid_entries(contexts[i].entries[..-2])
                  .and have_valid_entries((contexts - [contexts[i]]).map(&:entries).flatten)
              end
            end

            include_examples 'removes entries', -> { editor.send_keys_separately 'Vd' }
            include_examples 'removes entries', -> { editor.send_keys_separately 'Vlhd' }
            include_examples 'removes entries', -> { editor.send_keys_separately 'dd' }
          end

          context 'entry from range 1..-2' do
            shared_examples 'removes entries' do |motion|
              it 'removes entry from range 1..-2' do
                expect(contexts[i].entries.count).to be > 2 # verify the setup
                contexts[i].entries[1].locate!
                instance_exec(&motion)

                expect(esearch.output)
                  .to  have_missing_entries([contexts[i].entries[1]])
                  .and have_valid_entries(contexts[i].entries - [contexts[i].entries[1]])
                  .and have_valid_entries((contexts - [contexts[i]]).map(&:entries).flatten)
              end
            end

            include_examples 'removes entries', -> { editor.send_keys_separately 'Vd' }
            include_examples 'removes entries', -> { editor.send_keys_separately 'Vlhd' }
            include_examples 'removes entries', -> { editor.send_keys_separately 'dd' }
          end

          context 'filename ' do
            shared_examples 'recover context name' do |motion|
              it 'keeps entries' do
                expect {
                  5.times do
                    editor.locate_line! contexts[i].entries[0].line_in_window - 1
                    instance_exec(&motion)
                  end
                }.not_to change { editor.lines.to_a }
              end
            end

            include_examples 'recover context name', -> { editor.send_keys_separately 'Vd' }
            include_examples 'recover context name', -> { editor.send_keys_separately 'dd' }
          end

          context 'blank line before context' do
            shared_examples 'recover blank line before context' do |motion|
              it 'recovers blank line before context' do
                expect {
                  5.times do
                    editor.locate_line! contexts[i].entries[0].line_in_window - 2
                    instance_exec(&motion)
                  end
                }.not_to change { editor.lines.to_a }
              end
            end

            include_examples 'recover blank line before context', -> { editor.send_keys_separately 'Vd' }
            include_examples 'recover blank line before context', -> { editor.send_keys_separately 'dd' }
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
