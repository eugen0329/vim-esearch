# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#cmdline menu' do
  include Helpers::Commandline

  shared_examples 'commandline menu testing examples' do
    before { esearch.configure(out: 'stubbed', backend: 'system', use: 'last') }
    after do
      esearch.cleanup!
      esearch.output.reset_calls_history!
    end

    # NOTE editor#send_keys after #open_menu_keys must be called separately due to
    # +clientserver implimentation particularities

    describe 'change options using hotkeys' do
      shared_examples 'it sets options using hotkey' do |hotkey, options|
        it "sets #{options} using hotkey" do
          expect {
            editor.send_keys(*open_input_keys, *open_menu_keys)
            editor.send_keys(hotkey, 'search str', :enter)
          }.to set_global_options(options)
            .and start_search_with_options(options)
            .and finish_search_for('search str')
        end
      end

      context 'default mappings' do
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
    end

    describe 'change options by moving the menu selection' do
      shared_context 'opened menu testing' do
        before do
          esearch.configuration.submit!(overwrite: true)
          editor.command('call esearch#util_testing#spy_echo()')
          editor.send_keys(*open_input_keys, *open_menu_keys)
        end
        after { editor.command('call esearch#util_testing#unspy_echo()') }
      end

      shared_examples 'it locates "regex" menu items by pressing' do |keys:|
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
                start_with('  p ')
              ])).to(match_array([
                start_with('  c '),
                start_with('> r '),
                start_with('  w ')
                start_with('  p ')
              ]))
              .and set_global_options('regex' => 1)
              .and start_search_with_options('regex' => 1)
          end
        end
      end

      shared_examples 'it locates "word" menu items by pressing' do |keys:|
        context "when pressing #{keys}" do
          include_context 'opened menu testing'

          it 'locates "word" option' do
            expect { editor.send_keys(*keys, :enter, 'search string', :enter) }
              .to change { menu_items }
              .from(match_array([
                start_with('> c '),
                start_with('  r '),
                start_with('  w ')
                start_with('  p ')
              ])).to(match_array([
                start_with('  c '),
                start_with('  r '),
                start_with('> w ')
                start_with('> p ')
              ]))
              .and set_global_options('word' => 1)
              .and start_search_with_options('word' => 1)
          end
        end
      end

      shared_examples 'it locates "case" menu items by pressing' do |keys:|
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
                start_with('  p ')
              ]))
          end
        end
      end

      context 'default hotkeys' do
        ## Menu outlook is:
        # > c       toggle (c)ase sensitive match
        #   r       toggle (r)egexp match
        #   w       toggle (w)ord match
        #   p       edit (p)ath

        include_examples 'it locates "regex" menu items by pressing', keys: ['j']
        include_examples 'it locates "regex" menu items by pressing', keys: ['\\<C-j>']

        include_examples 'it locates "word" menu items by pressing',  keys: ['kk']
        include_examples 'it locates "word" menu items by pressing',  keys: ['jj']
        include_examples 'it locates "word" menu items by pressing',  keys: ['\\<C-k>\\<C-k>']
        include_examples 'it locates "word" menu items by pressing',  keys: ['\\<C-j>\\<C-j>']

        include_examples 'it locates "case" menu items by pressing',  keys: []
        include_examples 'it locates "case" menu items by pressing',  keys: ['jjjj']
        include_examples 'it locates "case" menu items by pressing',  keys: ['kkkk']
      end
    end

    describe 'dismissing menu' do
      before { esearch.configuration.submit!(overwrite: true) } # TODO: will be removed

      context 'default hotkeys' do
        before { editor.send_keys(*open_input_keys, *open_menu_keys) }

        it { expect { editor.send_keys(:escape) }.to change { editor.mode }.to(:commandline) }
      end

      context 'cursor position' do
        context 'within input provided by user' do
          shared_examples 'it preserves cursor location after dismissing' do |expected_location:, dismiss_with:|
            context "when dismissing with #{dismiss_with} keys" do
              let(:test_string) { expected_location.tr('|', '') }
              it "preserves location #{expected_location} at '|'" do
                editor.send_keys(*open_input_keys,
                                 test_string,
                                 *goto_location_keys(expected_location),
                                 *open_menu_keys)
                editor.send_keys(*dismiss_with)

                expect(editor).to have_commandline_cursor_location(expected_location)
              end
            end
          end

          shared_examples 'it preserves cursor location after dismissing with' do |keys:|
            include_examples 'it preserves cursor location after dismissing',
              dismiss_with:      keys,
              expected_location: 'st|rn'

            include_examples 'it preserves cursor location after dismissing',
              dismiss_with:      keys,
              expected_location: 'st|n'

            include_examples 'it preserves cursor location after dismissing',
              dismiss_with:      keys,
              expected_location: 'strn|'

            include_examples 'it preserves cursor location after dismissing',
              dismiss_with:      keys,
              expected_location: '|strn'
          end

          context 'when dismissing with selection of an option' do
            include_examples 'it preserves cursor location after dismissing with',
              keys: [:enter]
          end

          context 'when dismissing with cancelling' do
            include_examples 'it preserves cursor location after dismissing with',
              keys: [:escape]
          end

          context 'when multibyte input' do
            include_examples 'it preserves cursor location after dismissing',
              dismiss_with:      [:enter],
              expected_location: 'st|Σn'
          end
        end

        context 'within prefilled input' do
          shared_examples 'it preserves cursor location after dismissing with' do |keys:, expected_location:|
            context do
              include_context 'run preparatory search to enable prefilling', expected_location.tr('|', '')

              it "preserves location #{expected_location} after cancelling" do
                editor.send_keys(*open_input_keys, *open_menu_keys)
                editor.send_keys(*keys)

                expect(editor).to have_commandline_cursor_location(expected_location)
              end
            end
          end

          context 'when dismissing with selection of an option' do
            include_examples 'it preserves cursor location after dismissing with',
              keys:              [:enter],
              expected_location: 'str|'
          end

          context 'when dismissing with cancelling' do
            include_examples 'it preserves cursor location after dismissing with',
              keys:              [:escape],
              expected_location: 'str|'
          end
        end
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
