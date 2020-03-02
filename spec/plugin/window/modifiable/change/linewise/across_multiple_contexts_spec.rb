# frozen_string_literal: true

require 'spec_helper'

describe 'Modifiable window mode motions', :window do
  include Helpers::FileSystem
  include VimlValue::SerializationHelpers
  include Helpers::Modifiable

  include_context 'setup modifiable testing'

  describe 'delete across multiple contexts' do
    context 'from context 0' do
      xcontext 'up until header' do
        include_examples 'delete everything up until', line_above: 1, context_index: 0
      end

      xcontext 'up until blank line before header' do
        include_examples 'delete everything up until', line_above: 2, context_index: 0
      end
    end

    context 'context between two contexts' do
      xcontext 'up until header' do
        include_examples 'delete everything up until', line_above: 1, context_index: 1
      end

      xcontext 'up until blank line before header' do
        include_examples 'delete everything up until', line_above: 2, context_index: 1
      end

      context 'from the header' do
        before { editor.locate_line! 1 }

        context 'to entry -1 of context 1' do
          shared_examples 'removes entries' do |motion|
            it 'removes contexts 0..1' do
              motion.call(contexts[1].entries[-1].line_in_window)

              expect(output).to have_entries([contexts[0].entries[0] ]+ contexts[2].entries)
              expect(contexts[0].entries[0].line_content).to eq(contexts[0].entries[0].line_number_text)
            end
          end

          include_examples 'removes entries', ->(line) { editor.send_keys "V#{line}ggc" }
          include_examples 'removes entries', ->(line) { editor.send_keys "c#{line}gg" }
        end

        context 'to the blank line after context 1' do
          shared_examples 'removes entries' do |motion|
            it 'removes contexts 0..1' do
              motion.call(contexts[1].entries[-1].line_in_window + 1)

              expect(output).to have_entries([contexts[0].entries[0] ]+ contexts[2].entries)
              expect(contexts[0].entries[0].line_content).to eq(contexts[0].entries[0].line_number_text)
            end
          end

          include_examples 'removes entries', ->(line) { editor.send_keys "V#{line}ggc" }
          include_examples 'removes entries', ->(line) { editor.send_keys "c#{line}gg" }
        end

        context 'to the filename of context 2' do
          shared_examples 'removes entries' do |motion|
            it 'removes contexts 0..1' do
              motion.call(contexts[2].entries[0].line_in_window - 1)

              expect(output).to have_entries([contexts[0].entries[0] ]+ contexts[2].entries)
              expect(contexts[0].entries[0].line_content).to eq(contexts[0].entries[0].line_number_text)
            end
          end

          include_examples 'removes entries', ->(line) { editor.send_keys "V#{line}ggc" }
          include_examples 'removes entries', ->(line) { editor.send_keys "c#{line}gg" }
        end
      end

      context 'from the blank line after the header' do
        before { editor.locate_line! 2 }

        context 'to entry -1 of context 1' do
          shared_examples 'removes entries' do |motion|
            it 'removes contexts 0..1' do
              motion.call(contexts[1].entries[-1].line_in_window)

              expect(output).to have_entries([contexts[0].entries[0] ]+ contexts[2].entries)
              expect(contexts[0].entries[0].line_content).to eq(contexts[0].entries[0].line_number_text)
            end
          end

          include_examples 'removes entries', ->(line) { editor.send_keys "V#{line}ggc" }
          include_examples 'removes entries', ->(line) { editor.send_keys "c#{line}gg" }
        end

        context 'to the blank line after context 1' do
          shared_examples 'removes entries' do |motion|
            it 'removes contexts 0..1' do
              motion.call(contexts[1].entries[-1].line_in_window + 1)

              expect(output).to have_entries([contexts[0].entries[0] ]+ contexts[2].entries)
              expect(contexts[0].entries[0].line_content).to eq(contexts[0].entries[0].line_number_text)
            end
          end

          include_examples 'removes entries', ->(line) { editor.send_keys "V#{line}ggs" }
          # include_examples 'removes entries', ->(line) { editor.send_keys "с#{line}gg" }
        end

        context 'to the filename of context 2' do
          shared_examples 'removes entries' do |motion|
            it 'removes contexts 0..1' do
              motion.call(contexts[2].entries[0].line_in_window - 1)

              expect(output).to have_entries([contexts[0].entries[0] ]+ contexts[2].entries)
              expect(contexts[0].entries[0].line_content).to eq(contexts[0].entries[0].line_number_text)
            end
          end

          include_examples 'removes entries', ->(line) { editor.send_keys "V#{line}ggc" }
          include_examples 'removes entries', ->(line) { editor.send_keys "c#{line}gg" }
        end
      end

      context 'from context 0 entry 0' do
        before  { contexts[0].entries[0].locate! }

        context 'to entry -1 of context 1' do
          shared_examples 'removes entries' do |motion|
            it 'removes contexts 0..1' do
              motion.call(contexts[1].entries[-1].line_in_window)

              expect(output).to have_entries([contexts[0].entries[0] ]+ contexts[2].entries)
              expect(contexts[0].entries[0].line_content).to eq(contexts[0].entries[0].line_number_text)
            end
          end
          include_examples 'removes entries', ->(line) { editor.send_keys "V#{line}ggc" }
          include_examples 'removes entries', ->(line) { editor.send_keys "c#{line}gg" }
        end

        context 'to the blank line after context 1' do
          shared_examples 'removes entries' do |motion|
            it 'removes contexts 0..1' do
              motion.call(contexts[1].entries[-1].line_in_window + 1)

              expect(output).to have_entries([contexts[0].entries[0] ]+ contexts[2].entries)
              expect(contexts[0].entries[0].line_content).to eq(contexts[0].entries[0].line_number_text)
            end
          end

          include_examples 'removes entries', ->(line) { editor.send_keys "V#{line}ggc" }
          include_examples 'removes entries', ->(line) { editor.send_keys "c#{line}gg" }
        end

        context 'to the filename of context 2' do
          shared_examples 'removes entries' do |motion|
            it 'removes contexts 0..1' do
              motion.call(contexts[2].entries[0].line_in_window - 1)

              expect(output).to have_entries([contexts[0].entries[0] ]+ contexts[2].entries)
              expect(contexts[0].entries[0].line_content).to eq(contexts[0].entries[0].line_number_text)
            end
          end

          include_examples 'removes entries', ->(line) { editor.send_keys_separately "V#{line}ggc" }
          include_examples 'removes entries', ->(line) { editor.send_keys_separately "c#{line}gg" }
        end
      end

      context 'from context 0 entry 1' do
        before  { contexts[0].entries[1].locate! }

        context 'to entry -1 of context 1' do
          shared_examples 'removes entries' do |motion|
            it 'removes entries from context 0, entry 1 to context 1, entry -1' do
              motion.call(contexts[1].entries[-1].line_in_window)

              expect(output)
                .to have_entries(entries)
                .except(contexts[0].entries[2..] + contexts[1].entries)
              expect(contexts[0].entries[1].line_content).to eq(contexts[0].entries[1].line_number_text)
            end
          end
          include_examples 'removes entries', ->(line) { editor.send_keys "V#{line}ggc" }
          include_examples 'removes entries', ->(line) { editor.send_keys "c#{line}gg" }
        end

        context 'to the blank line after context 0' do
          shared_examples 'removes entries' do |motion|
            it 'removes entries from context 0, entry 1 to context 1, entry -1' do
              motion.call(contexts[1].entries[-1].line_in_window + 1)

              expect(output)
                .to have_entries(entries)
                .except(contexts[0].entries[2..] + contexts[1].entries)
              expect(contexts[0].entries[1].line_content).to eq(contexts[0].entries[1].line_number_text)
            end
          end

          include_examples 'removes entries', ->(line) { editor.send_keys "V#{line}ggc" }
          include_examples 'removes entries', ->(line) { editor.send_keys "c#{line}gg" }
        end

        context 'to the filename of context 2' do
          shared_examples 'removes entries' do |motion|
            it 'removes entries from context 0, entry 1 to context 1, entry -1' do
              motion.call(contexts[2].entries[0].line_in_window - 1)

              expect(output)
                .to have_entries(entries)
                .except(contexts[0].entries[2..] + contexts[1].entries)
              expect(contexts[0].entries[1].line_content).to eq(contexts[0].entries[1].line_number_text)
            end
          end

          include_examples 'removes entries', ->(line) { editor.send_keys "V#{line}ggc" }
          include_examples 'removes entries', ->(line) { editor.send_keys "c#{line}gg" }
        end

        context 'to context 2 entry 0' do
          shared_examples 'removes entries' do |motion|
            it 'removes entries' do
              motion.call(contexts[2].entries[0].line_in_window)

              expect(output)
                .to have_entries(entries)
                .except(contexts[0].entries[2..] + contexts[1].entries + contexts[2].entries.first(1))
              expect(contexts[0].entries[1].line_content).to eq(contexts[0].entries[1].line_number_text)
            end
          end
          include_examples 'removes entries', ->(line) { editor.send_keys_separately "V#{line}ggc" }
          include_examples 'removes entries', ->(line) { editor.send_keys_separately "c#{line}gg" }
        end

        context 'to context 2 entry 1' do
          shared_examples 'removes entries' do |motion|
            it 'removes entries' do
              motion.call(contexts[2].entries[1].line_in_window)

              expect(output)
                .to have_entries(entries)
                .except(contexts[0].entries[2..] + contexts[1].entries + contexts[2].entries[..1])
              expect(contexts[0].entries[1].line_content).to eq(contexts[0].entries[1].line_number_text)
            end
          end

          include_examples 'removes entries', ->(line) { editor.send_keys "V#{line}ggc" }
          include_examples 'removes entries', ->(line) { editor.send_keys "c#{line}gg" }
        end
      end

      context 'from blank line after context 0 ' do
        before  { contexts[0].entries[-1].locate! }

        context 'to entry -1 of context 1' do
          shared_examples 'removes entries' do |motion|
            it 'removes context 1' do
              motion.call(contexts[1].entries[-1].line_in_window)
              expect(output).to have_entries(entries).except(contexts[1].entries)
            end
          end

          include_examples 'removes entries', ->(line) { editor.send_keys "jV#{line}ggc" }
          include_examples 'removes entries', ->(line) { editor.send_keys "jc#{line}gg" }
        end

        context 'to the blank line after context 0' do
          shared_examples 'removes entries' do |motion|
            it 'removes context 1' do
              motion.call(contexts[1].entries[-1].line_in_window + 1)
              expect(output).to have_entries(entries).except(contexts[1].entries)
            end
          end
          include_examples 'removes entries', ->(line) { editor.send_keys "jV#{line}ggc" }
          include_examples 'removes entries', ->(line) { editor.send_keys "jc#{line}gg" }
        end

        context 'to the filename of context 2' do
          shared_examples 'removes entries' do |motion|
            it 'removes context 1' do
              motion.call(contexts[2].entries[0].line_in_window - 1)

              expect(output).to have_entries(entries).except(contexts[1].entries)
            end
          end

          include_examples 'removes entries', ->(line) { editor.send_keys "jV#{line}ggc" }
          include_examples 'removes entries', ->(line) { editor.send_keys "jc#{line}gg" }
        end

        context 'to context 2 entry 0' do
          shared_examples 'removes entries' do |motion|
            it 'removes entries from context 1, entry 1 to context 2, entry 0' do
              motion.call(contexts[2].entries[0].line_in_window)

              expect(output)
                .to have_entries(entries)
                .except(contexts[1].entries + contexts[2].entries.first(1))
            end
          end

          include_examples 'removes entries', ->(line) { editor.send_keys "jV#{line}ggc" }
          include_examples 'removes entries', ->(line) { editor.send_keys "jc#{line}gg" }
        end

        context 'to context 2 entry 1' do
          shared_examples 'removes entries' do |motion|
            it 'removes entries from context 1, entry 1 to context 2, entry 1' do
              motion.call(contexts[2].entries[1].line_in_window)

              expect(output)
                .to have_entries(entries)
                .except(contexts[1].entries + contexts[2].entries.first(2))
            end
          end

          include_examples 'removes entries', ->(line) { editor.send_keys "jV#{line}ggc" }
          include_examples 'removes entries', ->(line) { editor.send_keys "jc#{line}gg" }
        end
      end

      xcontext 'delete from context -1' do
        context 'up until header' do
          include_examples 'delete everything up until', line_above: 1, context_index: -1
        end

        context 'up until blank line before header' do
          include_examples 'delete everything up until', line_above: 2, context_index: -1
        end
      end
    end
  end
end
