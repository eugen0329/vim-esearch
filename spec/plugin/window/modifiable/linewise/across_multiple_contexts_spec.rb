# frozen_string_literal: true

require 'spec_helper'

describe 'Modifiable window mode motions', :window do
  include Helpers::FileSystem
  include VimlValue::SerializationHelpers
  include Helpers::Modifiable

  include_context 'setup modifiable testing'

  describe 'delete across multiple contexts' do
    context 'delete from context 0' do
      context 'up until header' do
        include_examples 'delete everything up until', line_above: 1, context_index: 0
      end

      context 'up until blank line before header' do
        include_examples 'delete everything up until', line_above: 2, context_index: 0
      end
    end

    context 'delete context between two contexts' do
      context 'up until header' do
        include_examples 'delete everything up until', line_above: 1, context_index: 1
      end

      context 'up until blank line before header' do
        include_examples 'delete everything up until', line_above: 2, context_index: 1
      end

      context 'from the header' do
        context 'to line -1 of context 1' do
          shared_examples 'removes entries' do |motion|
            it 'removes contexts 0..1' do
              editor.locate_line! 1
              motion.call(contexts[1].entries[-1].line_in_window)

              expect(esearch.output)
                .to  have_missing_entries(contexts[0].entries + contexts[1].entries)
                .and have_valid_entries(contexts[2].entries)
            end
          end

          include_examples 'removes entries', ->(line) { editor.send_keys "V#{line}ggd" }
          include_examples 'removes entries', ->(line) { editor.send_keys "d#{line}gg" }
        end

        context 'to the blank line after context 0' do
          shared_examples 'removes entries' do |motion|
            it 'removes contexts 0..1' do
              editor.locate_line! 1
              motion.call(contexts[1].entries[-1].line_in_window + 1)

              expect(esearch.output)
                .to  have_missing_entries(contexts[0].entries + contexts[1].entries)
                .and have_valid_entries(contexts[2].entries)
            end
          end

          include_examples 'removes entries', ->(line) { editor.send_keys "V#{line}ggd" }
          include_examples 'removes entries', ->(line) { editor.send_keys "d#{line}gg" }
        end

        context 'to the filename of context 2' do
          shared_examples 'removes entries' do |motion|
            it 'removes contexts 0..1' do
              editor.locate_line! 1
              motion.call(contexts[2].entries[0].line_in_window - 1)

              expect(esearch.output)
                .to  have_missing_entries(contexts[0].entries + contexts[1].entries)
                .and have_valid_entries(contexts[2].entries)
            end
          end

          include_examples 'removes entries', ->(line) { editor.send_keys "V#{line}ggd" }
          include_examples 'removes entries', ->(line) { editor.send_keys "d#{line}gg" }
        end
      end

      context 'from the blank line after the header' do
        context 'to line -1 of context 1' do
          shared_examples 'removes entries' do |motion|
            it 'removes contexts 0..1' do
              editor.locate_line! 2
              motion.call(contexts[1].entries[-1].line_in_window)

              expect(esearch.output)
                .to  have_missing_entries(contexts[0].entries + contexts[1].entries)
                .and have_valid_entries(contexts[2].entries)
            end
          end

          include_examples 'removes entries', ->(line) { editor.send_keys "V#{line}ggd" }
          include_examples 'removes entries', ->(line) { editor.send_keys "d#{line}d" }
        end

        context 'to the blank line after context 0' do
          shared_examples 'removes entries' do |motion|
            it 'removes contexts 0..1' do
              editor.locate_line! 2
              motion.call(contexts[1].entries[-1].line_in_window + 1)

              expect(esearch.output)
                .to  have_missing_entries(contexts[0].entries + contexts[1].entries)
                .and have_valid_entries(contexts[2].entries)
            end
          end

          include_examples 'removes entries', ->(line) { editor.send_keys "V#{line}ggd" }
          include_examples 'removes entries', ->(line) { editor.send_keys "d#{line}ggd" }
        end

        context 'to the filename of context 2' do
          shared_examples 'removes entries' do |motion|
            it 'removes contexts 0..1' do
              editor.locate_line! 2
              motion.call(contexts[2].entries[0].line_in_window - 1)

              expect(esearch.output)
                .to  have_missing_entries(contexts[0].entries + contexts[1].entries)
                .and have_valid_entries(contexts[2].entries)
            end
          end

          include_examples 'removes entries', ->(line) { editor.send_keys "V#{line}ggd" }
          include_examples 'removes entries', ->(line) { editor.send_keys "d#{line}gg" }
        end
      end

      context 'from context 0 entry 0' do
        context 'to line -1 of context 1' do
          shared_examples 'removes entries' do |motion|
            it 'removes contexts 0..1' do
              contexts[0].entries[0].locate!
              motion.call(contexts[1].entries[-1].line_in_window)

              expect(esearch.output)
                .to  have_missing_entries(contexts[0].entries + contexts[1].entries)
                .and have_valid_entries(contexts[2].entries)
            end
          end
          include_examples 'removes entries', ->(line) { editor.send_keys "V#{line}ggd" }
          include_examples 'removes entries', ->(line) { editor.send_keys "d#{line}gg" }
        end

        context 'to the blank line after context 0' do
          shared_examples 'removes entries' do |motion|
            it 'removes contexts 0..1' do
              contexts[0].entries[0].locate!
              motion.call(contexts[1].entries[-1].line_in_window + 1)

              expect(esearch.output)
                .to  have_missing_entries(contexts[0].entries + contexts[1].entries)
                .and have_valid_entries(contexts[2].entries)
            end
          end

          include_examples 'removes entries', ->(line) { editor.send_keys "V#{line}ggd" }
          include_examples 'removes entries', ->(line) { editor.send_keys "d#{line}gg" }
        end

        context 'to the filename of context 2' do
          shared_examples 'removes entries' do |motion|
            it 'removes contexts 0..1' do
              contexts[0].entries[0].locate!
              motion.call(contexts[2].entries[0].line_in_window - 1)

              expect(esearch.output)
                .to  have_missing_entries(contexts[0].entries + contexts[1].entries)
                .and have_valid_entries(contexts[2].entries)
            end
          end

          include_examples 'removes entries', ->(line) { editor.send_keys "V#{line}ggd" }
          include_examples 'removes entries', ->(line) { editor.send_keys "d#{line}gg" }
        end
      end

      context 'from context 0 entry 1' do
        context 'to line -1 of context 1' do
          shared_examples 'removes entries' do |motion|
            it 'removes entries from context 0, entry 1 to context 1, entry -1' do
              contexts[0].entries[1].locate!
              motion.call(contexts[1].entries[-1].line_in_window)

              expect(esearch.output)
                .to  have_valid_entries(contexts[0].entries[..0])
                .and have_missing_entries(contexts[0].entries[1..])
                .and have_missing_entries(contexts[1].entries)
                .and have_valid_entries(contexts[2].entries)
            end
          end
          include_examples 'removes entries', ->(line) { editor.send_keys "V#{line}ggd" }
          include_examples 'removes entries', ->(line) { editor.send_keys "d#{line}gg" }
        end

        context 'to the blank line after context 0' do
          shared_examples 'removes entries' do |motion|
            it 'removes entries from context 0, entry 1 to context 1, entry -1' do
              contexts[0].entries[1].locate!
              motion.call(contexts[1].entries[-1].line_in_window + 1)

              expect(esearch.output)
                .to  have_valid_entries(contexts[0].entries[..0])
                .and have_missing_entries(contexts[0].entries[1..])
                .and have_missing_entries(contexts[1].entries)
                .and have_valid_entries(contexts[2].entries)
            end
          end

          include_examples 'removes entries', ->(line) { editor.send_keys "V#{line}ggd" }
          include_examples 'removes entries', ->(line) { editor.send_keys "d#{line}gg" }
        end

        context 'to the filename of context 2' do
          shared_examples 'removes entries' do |motion|
            it 'removes entries from context 0, entry 1 to context 1, entry -1' do
              contexts[0].entries[1].locate!
              motion.call(contexts[2].entries[0].line_in_window - 1)

              expect(esearch.output)
                .to  have_valid_entries(contexts[0].entries[..0])
                .and have_missing_entries(contexts[0].entries[1..])
                .and have_missing_entries(contexts[1].entries)
                .and have_valid_entries(contexts[2].entries)
            end
          end

          include_examples 'removes entries', ->(line) { editor.send_keys "V#{line}ggd" }
          include_examples 'removes entries', ->(line) { editor.send_keys "d#{line}gg" }
        end

        context 'to context 2 entry 0' do
          shared_examples 'removes entries' do |motion|
            it 'removes entries' do
              contexts[0].entries[1].locate!
              motion.call(contexts[2].entries[0].line_in_window)

              expect(esearch.output)
                .to  have_valid_entries(contexts[0].entries[..0])
                .and have_missing_entries(contexts[0].entries[1..])
                .and have_missing_entries(contexts[1].entries)
                .and have_missing_entries(contexts[2].entries[..0])
                .and have_valid_entries(contexts[2].entries[1..])
            end
          end
          include_examples 'removes entries', ->(line) { editor.send_keys "V#{line}ggd" }
          include_examples 'removes entries', ->(line) { editor.send_keys "d#{line}gg" }
        end

        context 'to context 2 entry 1' do
          shared_examples 'removes entries' do |motion|
            it 'removes entries' do
              contexts[0].entries[1].locate!
              motion.call(contexts[2].entries[1].line_in_window)

              expect(esearch.output)
                .to  have_valid_entries(contexts[0].entries[..0])
                .and have_missing_entries(contexts[0].entries[1..])
                .and have_missing_entries(contexts[1].entries)
                .and have_missing_entries(contexts[2].entries[..1])
                .and have_valid_entries(contexts[2].entries[2..])
            end
          end

          include_examples 'removes entries', ->(line) { editor.send_keys "V#{line}ggd" }
          include_examples 'removes entries', ->(line) { editor.send_keys "d#{line}gg" }
        end
      end

      context 'from blank line after context 0 ' do
        context 'to line -1 of context 1' do
          shared_examples 'removes entries' do |motion|
            it 'removes context 1' do
              contexts[0].entries[-1].locate!
              motion.call(contexts[1].entries[-1].line_in_window)

              expect(esearch.output)
                .to  have_valid_entries(contexts[0].entries + contexts[2].entries)
                .and have_missing_entries(contexts[1].entries)
            end
          end

          include_examples 'removes entries', ->(line) { editor.send_keys "jV#{line}ggd" }
          include_examples 'removes entries', ->(line) { editor.send_keys "jd#{line}gg" }
        end

        context 'to the blank line after context 0' do
          shared_examples 'removes entries' do |motion|
            it 'removes context 1' do
              contexts[0].entries[-1].locate!
              motion.call(contexts[1].entries[-1].line_in_window + 1)

              expect(esearch.output)
                .to  have_valid_entries(contexts[0].entries + contexts[2].entries)
                .and have_missing_entries(contexts[1].entries)
            end
          end
          include_examples 'removes entries', ->(line) { editor.send_keys "jV#{line}ggd" }
          include_examples 'removes entries', ->(line) { editor.send_keys "jd#{line}gg" }
        end

        context 'to the filename of context 2' do
          shared_examples 'removes entries' do |motion|
            it 'removes context 1' do
              contexts[0].entries[-1].locate!
              motion.call(contexts[2].entries[0].line_in_window - 1)

              expect(esearch.output)
                .to  have_valid_entries(contexts[0].entries + contexts[2].entries)
                .and have_missing_entries(contexts[1].entries)
            end
          end

          include_examples 'removes entries', ->(line) { editor.send_keys "jV#{line}ggd" }
          include_examples 'removes entries', ->(line) { editor.send_keys "jd#{line}ggd" }
        end

        context 'to context 2 entry 0' do
          shared_examples 'removes entries' do |motion|
            it 'removes entries from context 1, entry 1 to context 2, entry 0' do
              contexts[0].entries[-1].locate!
              motion.call(contexts[2].entries[0].line_in_window)

              expect(esearch.output)
                .to  have_valid_entries(contexts[0].entries)
                .and have_missing_entries(contexts[1].entries)
                .and have_missing_entries(contexts[2].entries[..0])
                .and have_valid_entries(contexts[2].entries[1..])
            end
          end

          include_examples 'removes entries', ->(line) { editor.send_keys "jV#{line}ggd" }
          include_examples 'removes entries', ->(line) { editor.send_keys "jd#{line}gg" }
        end

        context 'to context 2 entry 1' do
          shared_examples 'removes entries' do |motion|
            it 'removes entries from context 1, entry 1 to context 2, entry 1' do
              contexts[0].entries[-1].locate!
              motion.call(contexts[2].entries[1].line_in_window)

              expect(esearch.output)
                .to  have_valid_entries(contexts[0].entries)
                .and have_missing_entries(contexts[1].entries)
                .and have_missing_entries(contexts[2].entries[..1])
                .and have_valid_entries(contexts[2].entries[2..])
            end
          end

          include_examples 'removes entries', ->(line) { editor.send_keys "jV#{line}ggd" }
          include_examples 'removes entries', ->(line) { editor.send_keys "jd#{line}gg" }
        end
      end

      context 'delete from context -1' do
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
