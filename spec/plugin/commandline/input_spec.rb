# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#cmdline input', :commandline do
  include Helpers::Commandline

  shared_examples 'commandline input testing examples' do
    before { esearch.configure(out: 'stubbed', backend: 'system', prefill: ['last'], root_markers: [], live_update: 0) }
    after do
      esearch.cleanup!
      esearch.output.reset_calls_history!
    end

    describe 'initial selection' do
      before { esearch.configuration.submit!(overwrite: true) } # TODO: will be removed

      shared_examples 'it starts search at location "|" after pressing' do |keys:, prefilled_input:, expected_input:|
        context "when #{keys} pressed against input prefilled with #{prefilled_input.inspect}" do
          before { expect(keys.size).to be_present }

          include_context 'run preparatory search to enable prefilling', prefilled_input

          it "starts search of #{expected_input.inspect} with cursor at \"|\"" do
            expect do
              editor.send_keys(*open_input_keys)
              editor.send_keys_separately(*keys[..-2])
            end.not_to start_stubbed_search

            expect(editor)
              .to have_commandline_cursor_location(expected_input)
              .or not_to_be_in_commandline

            expect { editor.send_keys(keys.last) }
              .to start_stubbed_search
              .and finish_stubbed_search_for(expected_input.tr('|', ''))
          end
        end
      end

      shared_examples 'it changes commandline state to' do |keys:, prefilled_input:, expected_input:|
        context "when #{keys} keys are pressed while prefilled with #{prefilled_input.inspect}" do
          include_context 'run preparatory search to enable prefilling', prefilled_input

          it "it changes commandline state to #{expected_input}" do
            expect do
              editor.send_keys(*open_input_keys)
              editor.send_keys_separately(*keys)
            end.not_to start_stubbed_search

            expect(editor)
              .to  be_in_commandline
              .and have_commandline_cursor_location(expected_input)
          end
        end
      end

      shared_examples "it doesn't start search after pressing" do |keys:, prefilled_input: 'any'|
        context "when #{keys} keys are pressed while prefilled with #{prefilled_input.inspect}" do
          include_context 'run preparatory search to enable prefilling', prefilled_input

          it "it doesn't start search" do
            expect do
              editor.send_keys(*open_input_keys)
              editor.send_keys_separately(*keys)
            end.not_to start_stubbed_search
          end
        end
      end

      describe 'clear prefilled' do
        context 'defined in g:esearch#cmdline#clear_selection_chars' do
          context 'defaults' do
            include_examples 'it changes commandline state to',
              keys:            [:delete],
              prefilled_input: 'was',
              expected_input:  '|'

            include_examples 'it changes commandline state to',
              keys:            [:backspace],
              prefilled_input: 'was',
              expected_input:  '|'

            include_examples 'it changes commandline state to',
              keys:            ['\\<c-w>'],
              prefilled_input: 'was',
              expected_input:  '|'

            include_examples 'it changes commandline state to',
              keys:            ['\\<c-h>'],
              prefilled_input: 'was',
              expected_input:  '|'

            include_examples 'it changes commandline state to',
              keys:            ['\\<c-u>'],
              prefilled_input: 'was',
              expected_input:  '|'
          end

          context 'defined by user' do
            include_context 'add', value: '\\<c-n>', to: 'g:esearch#cmdline#clear_selection_chars'

            include_examples 'it changes commandline state to',
              keys:            ['\\<c-n>'],
              prefilled_input: 'was',
              expected_input:  '|'
          end

          context 'not defined' do
            include_examples 'it starts search at location "|" after pressing',
              keys:            ['\\<c-n>', 'after', :enter],
              prefilled_input: 'was',
              expected_input:  'wasafter|'
          end
        end
      end

      describe 'start searching of prefilled (press <enter> etc.)' do
        context 'defined in esearch#cmdline#start_search_chars' do
          context 'defaults' do
            include_examples 'it starts search at location "|" after pressing',
              keys:            [:enter],
              prefilled_input: 'was',
              expected_input:  'was|'
          end

          context 'defined by user' do
            include_context 'add', value: 's', to: 'g:esearch#cmdline#start_search_chars'

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
              prefilled_input: 'was',
              expected_input:  'was|'

            include_examples 'it starts search at location "|" after pressing',
              keys:            %i[down up enter],
              prefilled_input: 'was',
              expected_input:  'was|'

            include_examples 'it starts search at location "|" after pressing',
              keys:            %i[left enter],
              prefilled_input: 'was',
              expected_input:  'wa|s'

            include_examples 'it starts search at location "|" after pressing',
              keys:            %i[right enter],
              prefilled_input: 'was',
              expected_input:  'was|'
          end

          context 'defined by user' do
            include_context 'add', value: 'r', to: 'g:esearch#cmdline#cancel_selection_and_retype_chars'

            include_examples 'it starts search at location "|" after pressing',
              keys:            ['r', :enter],
              prefilled_input: 'was',
              expected_input:  'wasr|'
          end

          context 'not defined' do
            include_examples 'it starts search at location "|" after pressing',
              keys:            ['r', :enter],
              prefilled_input: 'was',
              expected_input:  'r|'
          end
        end
      end

      describe 'cancel selection' do
        context 'defined in g:esearch#cmdline#cancel_selection_chars' do
          context 'defaults' do
            include_examples 'it starts search at location "|" after pressing',
              keys:            ['\\<c-c>', :enter],
              prefilled_input: 'was',
              expected_input:  'was|'

            include_examples 'it starts search at location "|" after pressing',
              keys:            %i[escape enter],
              prefilled_input: 'was',
              expected_input:  'was|'
          end

          context 'defined by user' do
            include_context 'add', value: 'c', to: 'g:esearch#cmdline#cancel_selection_chars'

            include_examples 'it starts search at location "|" after pressing',
              keys:            ['c', :enter],
              prefilled_input: 'was',
              expected_input:  'was|'

          end

          context 'not defined' do
            include_examples 'it starts search at location "|" after pressing',
              keys:            ['c', :enter],
              prefilled_input: 'was',
              expected_input:  'c|'
          end
        end
      end

      describe 'retype if key is a kind of escape (control-*, alt-*, F1, ..)' do
        context 'defined in g:cmdline_mappings' do
          context 'defaults' do
            include_examples 'it starts search at location "|" after pressing',
              keys:            ['\\<c-o>', :escape, :enter],
              prefilled_input: 'was',
              expected_input:  'was|'

            include_examples 'it starts search at location "|" after pressing',
              keys:            ['\\<c-o>', :enter, :escape, :enter],
              prefilled_input: 'was',
              expected_input:  'was|'
          end
        end

        context 'defined by user' do
          context 'alt-*' do
            include_context 'defined commandline hotkey', '<m-b>', '<s-Left>'
            include_examples 'it starts search at location "|" after pressing',
              keys:            ['\\<m-b>', :enter],
              prefilled_input: 'was',
              expected_input:  '|was'
          end

          context 'control-*' do
            include_context 'defined commandline hotkey', '<c-x>', '<s-Left>'
            include_examples 'it starts search at location "|" after pressing',
              keys:            ['\\<c-x>', :enter],
              prefilled_input: 'was',
              expected_input:  '|was'
          end

          context 'F*' do
            include_context 'defined commandline hotkey', '<F2>', '<s-Left>'
            include_examples 'it starts search at location "|" after pressing',
              keys:            ['\\<F2>', :enter],
              prefilled_input: 'was',
              expected_input:  '|was'
          end

          context 'multiple keys sequence' do
            include_context 'defined commandline hotkey', '<c-x><c-x>', 'after'
            include_examples 'it starts search at location "|" after pressing',
              keys:            ['\\<c-x>\\<c-x>', :enter],
              prefilled_input: 'was',
              expected_input:  'wasafter|'
          end
        end

        context 'not defined' do
          include_examples 'it starts search at location "|" after pressing',
            keys:            ['\\<s-Left>', :enter],
            prefilled_input: 'was',
            expected_input:  '|was'

          include_examples 'it starts search at location "|" after pressing',
            keys:            ['\\<c-e>', :enter],
            prefilled_input: 'was',
            expected_input:  'was|'
        end
      end

      describe 'retype if commandline hotkey prefix' do
        context 'with cmap' do
          include_context 'defined commandline hotkey', 'h', 'after'
          include_examples 'it starts search at location "|" after pressing',
            keys:            ['h', :enter],
            prefilled_input: 'was',
            expected_input:  'wasafter|'
        end

        context 'without mappings or abbreviations' do
          include_examples 'it starts search at location "|" after pressing',
            keys:            ['h', :enter],
            prefilled_input: 'was',
            expected_input:  'h|'
        end

        context 'with ignoring other mode hotkeys' do
          include_context 'defined normal mode hotkey', 'h', 'after'
          include_examples 'it starts search at location "|" after pressing',
            keys:            ['h', :enter],
            prefilled_input: 'was',
            expected_input:  'h|'
        end

        context 'with commandline abbreviation' do
          include_context 'defined commandline abbreviation', 'h', 'after'
          include_examples 'it starts search at location "|" after pressing',
            keys:            ['h', :enter],
            prefilled_input: 'was',
            expected_input:  'h|'
        end

        context 'with ignoring other mode abbreviations' do
          include_context 'defined normal mode abbreviation', 'h', 'after'
          include_examples 'it starts search at location "|" after pressing',
            keys:            ['h', :enter],
            prefilled_input: 'was',
            expected_input:  'h|'
        end
      end

      describe 'overwrite prefilled (by pressing any regular char)' do
        context 'with a single regular char' do
          include_examples 'it starts search at location "|" after pressing',
            keys:            ['1', :enter],
            prefilled_input: 'was',
            expected_input:  '1|'
        end

        context 'with multiple regular chars (pasting and probably something else)' do
          include_examples 'it starts search at location "|" after pressing',
            keys:            ['pasted', :enter],
            prefilled_input: 'was',
            expected_input:  'pasted|'
        end
      end
    end
  end

  include_examples 'commandline input testing examples'
end
