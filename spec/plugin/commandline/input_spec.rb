# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#cmdline input' do
  include Helpers::Commandline

  shared_examples 'commandline input testing examples' do
    before { esearch.configure(out: 'stubbed', backend: 'system', use: 'last') }
    after do
      esearch.cleanup!
      esearch.output.reset_calls_history!
    end

    context 'when cancelling initial selection' do
      before { esearch.configuration.submit!(overwrite: true) } # TODO: will be removed

      shared_context 'run preparatory search to enable prefilling' do |search_string|
        before do
          expect { editor.send_keys(*open_input, search_string, :enter) }
            .to start_search & finish_search_for(search_string)
        end
      end

      shared_examples 'it starts search at location "|" after pressing' do |keys:, prefilled_input:, expected_input:|
        context "when #{keys} keys are pressed" do
          before { expect(keys.size).to be_present }

          include_context 'run preparatory search to enable prefilling', prefilled_input

          it 'it starts search at a specific location' do
            expect {
              editor.send_keys(*open_input)
              next if keys.size < 2

              editor.send_keys_separately(*keys[..-2])
              expect(editor.commandline_cursor_location)
                .to eq(expected_input.index('|') + 1)
            }.not_to start_search

            expect { editor.send_keys(keys[-1]) }
              .to start_search
              .and finish_search_for(expected_input.tr('|', ''))
          end
        end
      end

      shared_examples "it doesn't start search after pressing" do |keys:, prefilled_input: 'any'|
        context "when #{keys} keys are pressed" do
          include_context 'run preparatory search to enable prefilling', prefilled_input

          it "it doesn't start search" do
            expect {
              editor.send_keys(*open_input)
              editor.send_keys_separately(*keys)
            }.not_to start_search
          end
        end
      end

      context 'cancelling prefilled input selection (<Esc>, <Left>, ...)' do
        context 'with moving cursor' do
          include_examples 'it starts search at location "|" after pressing',
            keys:            ['\\<Left>', :enter],
            prefilled_input: 'str',
            expected_input:  'st|r'

          include_examples 'it starts search at location "|" after pressing',
            keys:            ['\\<Right>', :enter],
            prefilled_input: 'str',
            expected_input:  'str|'

          include_examples 'it starts search at location "|" after pressing',
            keys:            ['\\<S-Left>', :enter],
            prefilled_input: 'str',
            expected_input:  '|str'

          include_examples 'it starts search at location "|" after pressing',
            keys:            ['\\<S-Right>', :enter],
            prefilled_input: 'str',
            expected_input:  'str|'

          include_examples 'it starts search at location "|" after pressing',
            keys:            ['\\<C-a>', :enter],
            prefilled_input: 'str',
            expected_input:  'str|'
          include_examples 'it starts search at location "|" after pressing',
            keys:            ['\\<C-e>', :enter],
            prefilled_input: 'str',
            expected_input:  'str|'

          context 'up and down keys' do
            include_context 'fix vim internal quirks with mapping timeout'
            include_examples 'it starts search at location "|" after pressing',
              keys:            %i[up down enter],
              prefilled_input: 'str',
              expected_input:  'str|'
          end
        end

        context 'without moving cursor' do
          include_examples 'it starts search at location "|" after pressing',
            keys:            ['\\<C-c>', :enter],
            prefilled_input: 'str',
            expected_input:  'str|'
          include_examples 'it starts search at location "|" after pressing',
            keys:            %i[escape enter],
            prefilled_input: 'str',
            expected_input:  'str|'
        end

        context 'with pressing remapped hotkeys' do
          context 'defaults' do
            include_examples 'it starts search at location "|" after pressing',
              keys:            ['\\<C-o>', :escape, :enter],
              prefilled_input: 'str',
              expected_input:  'str|'
          end

          context 'alt-f' do
            include_context 'defined commandline hotkey', '<M-f>', '<S-Right>'
            include_examples 'it starts search at location "|" after pressing',
              keys:            ['\\<M-f>', :enter],
              prefilled_input: 'str',
              expected_input:  'str|'
          end

          context 'alt-b' do
            include_context 'defined commandline hotkey', '<M-b>', '<S-Left>'
            include_examples 'it starts search at location "|" after pressing',
              keys:            ['\\<M-b>', :enter],
              prefilled_input: 'str',
              expected_input:  '|str'
          end
        end
      end

      context 'starting search with prefilled text skipping input step (<Enter>, ...)' do
        context 'when default keys' do
          include_examples 'it starts search at location "|" after pressing',
            keys:            [:enter],
            prefilled_input: 'input was',
            expected_input:  'input was|'
        end

        context 'when custom keys' do
          context 'when defined' do
            before { editor.command('call add(g:esearch#cmdline#start_search_chars, "s")') }
            after { editor.command('unlet g:esearch#cmdline#start_search_chars[-1]') }

            include_examples 'it starts search at location "|" after pressing',
              keys:            ['s'],
              prefilled_input: 'input was',
              expected_input:  'input was|'
          end

          context 'when not defined' do
            include_examples "it doesn't start search after pressing",
              keys: ['s']
          end
        end
      end

      context 'overriding prefilled input selection (by pressing any regular char)' do
        include_examples 'it starts search at location "|" after pressing',
          keys:            [:delete, 'str', :enter],
          prefilled_input: 'input was',
          expected_input:  'str|'

        include_examples 'it starts search at location "|" after pressing',
          keys:            [:backspace, 'str', :enter],
          prefilled_input: 'input was',
          expected_input:  'str|'

        context 'single char' do
          include_examples 'it starts search at location "|" after pressing',
            keys:            ['1', :enter],
            prefilled_input: 'input was',
            expected_input:  '1|'
        end

        context 'multiple chars' do
          include_examples 'it starts search at location "|" after pressing',
            keys:            ['multiple chars', :enter],
            prefilled_input: 'input was',
            expected_input:  'multiple chars|'
        end
      end

      context 'handling multiple chars mappings' do
        context 'starting search' do
          include_context 'defined commandline hotkey', '<C-r><C-r>', '<Enter>'

          include_examples 'it starts search at location "|" after pressing',
            keys:            ['\\<C-r>\\<C-r>'],
            prefilled_input: 'input was',
            expected_input:  'input was|'
        end

        context 'cancelling' do
          include_context 'defined commandline hotkey', '<C-r><C-r>', '<C-c>'

          include_examples "it doesn't start search after pressing",
            keys: ['s']
        end
      end
    end
  end

  context 'neovim', :neovim do
    around(:context) { |e| use_nvim(&e) }

    include_examples 'commandline input testing examples'
  end

  context 'vim' do
    include_examples 'commandline input testing examples'
  end
end
