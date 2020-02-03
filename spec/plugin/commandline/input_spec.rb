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

    describe 'initial selection' do
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

      describe 'clearing prefilled' do
        context 'defined in g:esearch#cmdline#clear_selection_chars' do
          context 'defaults' do
            include_examples 'it starts search at location "|" after pressing',
              keys:            [:delete, 'after', :enter],
              prefilled_input: 'was',
              expected_input:  'after|'

            include_examples 'it starts search at location "|" after pressing',
              keys:            [:backspace, 'after', :enter],
              prefilled_input: 'was',
              expected_input:  'after|'

            include_examples 'it starts search at location "|" after pressing',
              keys:            ['\\<C-w>', 'after', :enter],
              prefilled_input: 'was',
              expected_input:  'after|'
          end

          context 'defined by user' do
            include_context 'push', value: '\\<C-n>', to: 'g:esearch#cmdline#clear_selection_chars'

            include_examples 'it starts search at location "|" after pressing',
              keys:            ['\\<C-n>', 'after', :enter],
              prefilled_input: 'was',
              expected_input:  'after|'
          end

          context 'not defined' do
            include_examples 'it starts search at location "|" after pressing',
              keys:            ['\\<C-n>', 'after', :enter],
              prefilled_input: 'was',
              expected_input:  'wasafter|'
          end
        end
      end

      describe 'start searching of prefilled (press <Enter> etc.)' do
        context 'defined in esearch#cmdline#start_search_chars' do
          context 'defaults' do
            include_examples 'it starts search at location "|" after pressing',
              keys:            [:enter],
              prefilled_input: 'was',
              expected_input:  'was|'
          end

          context 'defined by user' do
            include_context 'push', value: 's', to: 'g:esearch#cmdline#start_search_chars'

            include_examples 'it starts search at location "|" after pressing',
              keys:            ['s'],
              prefilled_input: 'was',
              expected_input:  'was|'
          end

          context 'not defined' do
            include_examples "it doesn't start search after pressing",
              keys: ['s']
          end
        end
      end

      describe 'cancel selection and retype' do
        context 'defined in g:esearch#cmdline#cancel_selection_and_retype_chars' do
          context 'defaults' do
            include_context 'fix vim internal quirks with mapping timeout'

            include_examples 'it starts search at location "|" after pressing',
              keys:            %i[up down enter],
              prefilled_input: 'str',
              expected_input:  'str|'
            include_examples 'it starts search at location "|" after pressing',
              keys:            %i[down up enter],
              prefilled_input: 'str',
              expected_input:  'str|'
            include_examples 'it starts search at location "|" after pressing',
              keys:            %i[left enter],
              prefilled_input: 'str',
              expected_input:  'st|r'
            include_examples 'it starts search at location "|" after pressing',
              keys:            %i[right enter],
              prefilled_input: 'str',
              expected_input:  'str|'
          end

          context 'defined by user' do
            include_context 'push', value: 'r', to: 'g:esearch#cmdline#cancel_selection_and_retype_chars'

            include_examples 'it starts search at location "|" after pressing',
              keys:            ['r', :enter],
              prefilled_input: 'was',
              expected_input:  'wasr|'
          end

          context 'not defined' do
            include_examples 'it starts search at location "|" after pressing',
              keys:            ['r', :enter],
              prefilled_input: 'was',
              expected_input:  "r|"
          end
        end
      end

      describe 'cancel selection' do
        context 'defined in g:esearch#cmdline#cancel_selection_chars' do
          context 'defaults' do
            include_examples 'it starts search at location "|" after pressing',
              keys:            ['\\<C-c>', :enter],
              prefilled_input: 'str',
              expected_input:  'str|'
            include_examples 'it starts search at location "|" after pressing',
              keys:            %i[escape enter],
              prefilled_input: 'str',
              expected_input:  'str|'
          end

          context 'defined by user' do
            include_context 'push', value: 'c', to: 'g:esearch#cmdline#cancel_selection_chars'

            include_examples 'it starts search at location "|" after pressing',
              keys:            ['c', :enter],
              prefilled_input: 'was',
              expected_input:  'was|'

          end

          context 'not defined' do
            include_examples 'it starts search at location "|" after pressing',
              keys:            ['c', 'str after', :enter],
              prefilled_input: 'was',
              expected_input:  "cstr after|"
          end
        end
      end

      describe 'retype if key is kind of escape' do
        context 'defined in g:cmdline_mappings' do
          context 'defaults' do
            include_examples 'it starts search at location "|" after pressing',
              keys:            ['\\<C-o>', :escape, :enter],
              prefilled_input: 'str',
              expected_input:  'str|'
          end

          context 'defined by user' do
            # TODO
          end
        end

        context 'not mapped' do
          include_examples 'it starts search at location "|" after pressing',
            keys:            ['\\<S-Left>', :enter],
            prefilled_input: 'str',
            expected_input:  '|str'

          include_examples 'it starts search at location "|" after pressing',
            keys:            ['\\<C-e>', :enter],
            prefilled_input: 'str',
            expected_input:  'str|'
        end

        context 'defined using "cmap"' do
          context 'escaped' do
            context 'alt-b' do
              include_context 'defined commandline hotkey', '<M-b>', '<S-Left>'
              include_examples 'it starts search at location "|" after pressing',
                keys:            ['\\<M-b>', :enter],
                prefilled_input: 'str',
                expected_input:  '|str'
            end

            context 'control-b' do
              include_context 'defined commandline hotkey', '<C-b>', '<S-Left>'
              include_examples 'it starts search at location "|" after pressing',
                keys:            ['\\<C-b>', :enter],
                prefilled_input: 'str',
                expected_input:  '|str'
            end
          end

          # TODO add handling for user mappings
          #
          context 'multiple keys mappings' do
            context 'the first is captured and pressed automatically, the second - by user' do
              include_context 'defined commandline hotkey', '<C-f><C-f>', 'after'

              include_examples 'it starts search at location "|" after pressing',
                keys:            ['\\<C-f>\\<C-f>', :enter],
                prefilled_input: 'was',
                expected_input:  'wasafter|'
            end

            # context 'cancelling' do
            #   include_context 'defined commandline hotkey', '<C-r><C-r>', '<C-c>'

            #   include_examples "it doesn't start search after pressing",
            #     keys: ['s']
            # end
          end
        end
      end

      context 'overriding prefilled input selection (by pressing any regular char)' do
        context 'single char' do
          include_examples 'it starts search at location "|" after pressing',
            keys:            ['1', :enter],
            prefilled_input: 'was',
            expected_input:  '1|'
        end

        context 'multiple chars (pasting)' do
          include_examples 'it starts search at location "|" after pressing',
            keys:            ['after', :enter],
            prefilled_input: 'was',
            expected_input:  'after|'
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
