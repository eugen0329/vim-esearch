# frozen_string_literal: true

require 'spec_helper'

describe 'Modifiable window mode motions' do
  include Helpers::FileSystem
  include VimlValue::SerializationHelpers
  include Helpers::Modifiable

  include_context 'setup modifiable testing'

  shared_context 'delete everything up until' do |line_above:, context_index:|
    let(:i) { context_index }

    context 'entries 0..1' do
      shared_examples 'removes entries' do |motion|
        it 'removes entries 0..1' do
          contexts[i].entries[1].locate!
          motion.call(line_above)

          expect(esearch.output)
            .to  have_missing_entries(contexts[...i].map(&:entries).flatten)
            .and have_missing_entries(contexts[i].entries[..1])
            .and have_valid_entries(contexts[i].entries[2..])
            .and have_valid_entries((contexts - contexts[..i]).map(&:entries).flatten)
        end
      end

      include_examples 'removes entries', ->(line) { editor.send_keys "V#{line}ggd" }
      include_examples 'removes entries', ->(line) { editor.send_keys "d#{line}gg" }
    end

    context 'entries 0..2' do
      shared_examples 'removes entries' do |motion|
        it 'removes entries 0..2' do
          contexts[i].entries[2].locate!
          motion.call(line_above)

          expect(esearch.output)
            .to  have_missing_entries(contexts[...i].map(&:entries).flatten)
            .and have_missing_entries(contexts[i].entries[..2])
            .and have_valid_entries(contexts[i].entries[3..])
            .and have_valid_entries((contexts - contexts[..i]).map(&:entries).flatten)
        end
      end

      include_examples 'removes entries', ->(line) { editor.send_keys "V#{line}ggd" }
      include_examples 'removes entries', ->(line) { editor.send_keys "d#{line}gg" }
    end

    context 'entries 0..-1' do
      shared_examples 'removes entries' do |motion|
        it 'removes entries 0..-1' do
          contexts[i].entries[-1].locate!
          motion.call(line_above)

          expect(esearch.output)
            .to  have_missing_entries(contexts[..i].map(&:entries).flatten)
            .and have_valid_entries((contexts - contexts[..i]).map(&:entries).flatten)
        end
      end

      include_examples 'removes entries', ->(line) { editor.send_keys "V#{line}ggd" }
      include_examples 'removes entries', ->(line) { editor.send_keys "d#{line}gg" }
    end
  end

  shared_examples "doesn't have effect after motion" do |motion|
    it 'removes entries 0..-1' do
      entry.locate!
      expect { instance_exec(&motion) }
        .not_to change { editor.lines.to_a }
    end
  end

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

      include_examples 'recover header', -> { editor.send_keys 'Vd' }
      include_examples 'recover header', -> { editor.send_keys 'Vddd' }
      include_examples 'recover header', -> { editor.send_keys 'Vlhd' }
      include_examples 'recover header', -> { editor.send_keys 'dd' }
      include_examples 'recover header', -> { editor.send_keys 'ddVd' }
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

            context 'inside non-blank lines' do
              include_examples 'removes entries', -> { editor.send_keys 'Vipd' }
              include_examples 'removes entries', -> { editor.send_keys 'Vapd' }
              include_examples 'removes entries', -> { editor.send_keys 'dip' }
              include_examples 'removes entries', -> { editor.send_keys 'dap' }
            end

            context 'on a blank line' do
              let(:entry) { contexts[i].entries.first }

              include_examples 'removes entries', -> { editor.send_keys 'kkVapd' }
              include_examples 'removes entries', -> { editor.send_keys 'kkdap' }
              include_examples 'removes entries', -> { editor.send_keys 'kk', 'Vipd' }
              # Strangely enough, but normal mode textobject doesn't capture
              # paragraph below, while visual line mode does
              include_examples "doesn't have effect after motion", -> { editor.send_keys 'kkdip' }
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

            include_examples 'recover context name after motion down', -> { editor.send_keys 'Vjd' }
            include_examples 'recover context name after motion down', -> { editor.send_keys 'dj' }
            include_examples 'recover context name after motion up',   -> { editor.send_keys 'Vkd' }
            include_examples 'recover context name after motion up',   -> { editor.send_keys 'dk' }
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

              include_examples 'removes entries', -> { editor.send_keys 'Vjd' }
              include_examples 'removes entries', -> { editor.send_keys 'dj' }
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

              include_examples 'removes entries', -> { editor.send_keys 'V2jd' }
              include_examples 'removes entries', -> { editor.send_keys 'd2j' }
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

              include_examples 'removes entries', -> { editor.send_keys 'Vjd' }
              include_examples 'removes entries', -> { editor.send_keys 'dj' }
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

              include_examples 'removes entries', -> { editor.send_keys 'Vkd' }
              include_examples 'removes entries', -> { editor.send_keys 'dk' }
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

              include_examples 'removes entries', -> { editor.send_keys 'V2kd' }
              include_examples 'removes entries', -> { editor.send_keys 'd2k' }
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

              include_examples 'removes entries', -> { editor.send_keys 'Vkd' }
              include_examples 'removes entries', -> { editor.send_keys 'dk' }
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

              include_examples 'removes entries', ->(line) { editor.send_keys "V#{line}ggd" }
              include_examples 'removes entries', ->(line) { editor.send_keys "d#{line}gg" }
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

            include_examples 'removes entries', -> { editor.send_keys 'Vd' }
            include_examples 'removes entries', -> { editor.send_keys 'Vlhd' }
            include_examples 'removes entries', -> { editor.send_keys 'dd' }
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

            include_examples 'removes entries', -> { editor.send_keys 'Vd' }
            include_examples 'removes entries', -> { editor.send_keys 'Vlhd' }
            include_examples 'removes entries', -> { editor.send_keys 'dd' }
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

            include_examples 'removes entries', -> { editor.send_keys 'Vd' }
            include_examples 'removes entries', -> { editor.send_keys 'Vlhd' }
            include_examples 'removes entries', -> { editor.send_keys 'dd' }
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

            include_examples 'recover context name', -> { editor.send_keys 'Vd' }
            include_examples 'recover context name', -> { editor.send_keys 'dd' }
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

            include_examples 'recover blank line before context', -> { editor.send_keys 'Vd' }
            include_examples 'recover blank line before context', -> { editor.send_keys 'dd' }
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
