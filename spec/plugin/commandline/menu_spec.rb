# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#cmdline menu' do
  include Helpers::Commandline

  shared_examples 'commandline menu testing examples' do
    let(:open_menu) { '\\<C-o>' }
    let(:open_input) { [:leader, 'ff'] }

    before { esearch.configure(out: 'stubbed', backend: 'system', use: 'last') }
    after do
      esearch.cleanup!
      esearch.output.reset_calls_history!
    end

    context 'changing options using hotkeys' do
      shared_examples 'it sets options using hotkey' do |hotkey, options|
        it "sets #{options} using hotkey" do
          expect {
            editor.send_keys(*open_input, open_menu)
            editor.send_keys(hotkey, 'search str', :enter)
          }.to set_global_options(options)
            .and start_search_with_options(options)
            .and finish_search_for('search str')
        end
      end

      context 'when enabling options' do
        before { esearch.configure!('word': 0, 'case': 0, 'regex': 0) }

        include_examples 'it sets options using hotkey', '\\<C-c>', 'case'  => 1
        include_examples 'it sets options using hotkey', 'c',       'case'  => 1

        include_examples 'it sets options using hotkey', '\\<C-w>', 'word'  => 1
        include_examples 'it sets options using hotkey', 'w',       'word'  => 1

        include_examples 'it sets options using hotkey', 'r',       'regex' => 1
        include_examples 'it sets options using hotkey', '\\<C-r>', 'regex' => 1

        context 'legacy hotkeys' do
          include_examples 'it sets options using hotkey', '\\<C-s>', 'case'  => 1
          include_examples 'it sets options using hotkey', 's',       'case'  => 1
        end
      end

      context 'when disabling options' do
        before { esearch.configure!('word': 1, 'case': 1, 'regex': 1) }

        include_examples 'it sets options using hotkey', '\\<C-c>', 'case'  => 0
        include_examples 'it sets options using hotkey', 'c',       'case'  => 0

        include_examples 'it sets options using hotkey', '\\<C-w>', 'word'  => 0
        include_examples 'it sets options using hotkey', 'w',       'word'  => 0

        include_examples 'it sets options using hotkey', '\\<C-r>', 'regex' => 0
        include_examples 'it sets options using hotkey', 'r',       'regex' => 0

        context 'legacy hotkeys' do
          include_examples 'it sets options using hotkey', '\\<C-s>', 'case'  => 0
          include_examples 'it sets options using hotkey', 's',       'case'  => 0
        end
      end
    end

    context 'changing options by moving the menu selection' do
      shared_context 'opened menu testing' do
        before do
          esearch.configuration.submit!(overwrite: true)
          editor.command('call esearch#util_testing#spy_echo()')
          editor.send_keys(*open_input, open_menu)
        end
        after { editor.command('call esearch#util_testing#unspy_echo()') }
      end

      shared_examples 'it locates "regex" menu item using' do |keys:|
        context "when pressing #{keys}" do
          include_context 'opened menu testing'

          it 'locates "regex" option' do
            expect {
              editor.send_keys(*keys, :enter, 'search string', :enter)
            }.to change { menu_items }
              .from(match_array([
                start_with('> c '),
                start_with('  r '),
                start_with('  w ')
              ])).to(match_array([
                start_with('  c '),
                start_with('> r '),
                start_with('  w ')
              ]))
              .and set_global_options('regex' => 1)
              .and start_search_with_options('regex' => 1)
          end
        end
      end

      shared_examples 'it locates "word" menu item using' do |keys:|
        context "when pressing #{keys}" do
          include_context 'opened menu testing'

          it 'locates "word" option' do
            expect { editor.send_keys(*keys, :enter, 'search string', :enter) }
              .to change { menu_items }
              .from(match_array([
                start_with('> c '),
                start_with('  r '),
                start_with('  w ')
              ])).to(match_array([
                start_with('  c '),
                start_with('  r '),
                start_with('> w ')
              ]))
              .and set_global_options('word' => 1)
              .and start_search_with_options('word' => 1)
          end
        end
      end

      shared_examples 'it locates "case" menu item using' do |keys:|
        context "when pressing #{keys}" do
          include_context 'opened menu testing'

          it 'locates "case" option' do
            expect {
              editor.send_keys(*keys)
              editor.send_keys(:enter, 'search string', :enter)
            }.to set_global_options('case' => 1)
              .and start_search_with_options('case' => 1)
              .and not_to_change { menu_items }
              .from(match_array([
                start_with('> c '),
                start_with('  r '),
                start_with('  w ')
              ]))
          end
        end
      end

      include_examples 'it locates "regex" menu item using', keys: ['j']
      include_examples 'it locates "regex" menu item using', keys: ['\\<C-j>']

      include_examples 'it locates "word" menu item using',  keys: ['k']
      include_examples 'it locates "word" menu item using',  keys: ['jj']
      include_examples 'it locates "word" menu item using',  keys: ['\\<C-k>']
      include_examples 'it locates "word" menu item using',  keys: ['\\<C-j>\\<C-j>']

      include_examples 'it locates "case" menu item using',  keys: []
      include_examples 'it locates "case" menu item using',  keys: ['jjj']
      include_examples 'it locates "case" menu item using',  keys: ['kkk']
    end

    context 'when dismissing menu' do
      before { esearch.configuration.submit!(overwrite: true) } # TODO: will be removed

      context 'no prefilled -> input text -> press keys -> open -> dismiss' do
        shared_examples 'it preserves cursor location' do |fill_with:, expected_location:, press_keys:|
          let(:cursor_location_probe) { '|' }

          it 'preserves location after closing menu' do
            expect {
              editor.send_keys(*open_input, fill_with, *press_keys, open_menu)
              editor.send_keys(:escape, cursor_location_probe, :enter)
            }.to start_search & finish_search_for(expected_location)
          end

          it 'preserves location after selection an option' do
            expect {
              editor.send_keys(*open_input, fill_with, *press_keys, open_menu)
              editor.send_keys(:enter, cursor_location_probe, :enter)
            }.to start_search & finish_search_for(expected_location)
          end
        end

        include_examples 'it preserves cursor location',
          fill_with:         'strn',
          expected_location: 'st|rn',
          press_keys:        %i[left left]

        include_examples 'it preserves cursor location',
          fill_with:         'str',
          expected_location: 'st|r',
          press_keys:        [:left]

        include_examples 'it preserves cursor location',
          fill_with:         'str',
          expected_location: '|str',
          press_keys:        %i[left left left]

        include_examples 'it preserves cursor location',
          fill_with:         'str',
          expected_location: 'str|',
          press_keys:        []
      end

      context 'prefilled -> open -> dismiss' do
        shared_examples 'it puts cursor at the after dismissing with' do |keys:|
          context "when dismissing menu with #{keys}" do
            let(:previous_input) { 'previous input' }
            let(:cursor_location_probe) { '|' }
            let(:input_with_cursor_location) { [previous_input, cursor_location_probe].join }

            before { editor.send_keys(*open_input, previous_input, :enter) }

            it 'puts cursor at the end of the input' do
              expect {
                editor.send_keys(*open_input, open_menu)
                editor.send_keys_separately(*keys, cursor_location_probe, :enter)
              }.to start_search & finish_search_for(input_with_cursor_location)
            end
          end
        end

        include_examples 'it puts cursor at the after dismissing with', keys: [:enter]
        include_examples 'it puts cursor at the after dismissing with', keys: [:escape]
      end
    end
  end

  context 'neovim', :neovim do
    around(:context) { |e| use_nvim(&e) }

    include_examples 'commandline menu testing examples'
  end

  context 'vim' do
    include_examples 'commandline menu testing examples'
  end
end
