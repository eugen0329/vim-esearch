# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#cmdline menu' do
  include Helpers::CommandlineMenu

  shared_examples 'impl' do
    let(:open_menu) { '\\<C-o>' }
    let(:open_input) { [:leader, 'ff'] }

    before { esearch.configure(out: 'stubbed', backend: 'system', use: 'last') }
    after { esearch.output.reset_calls_history! }

    # NOTE: #start_search internally use timeout (like other gems like capybara
    # do), to using it with #not_to may cause extra delays avoiding of which can
    # cause false positives

    context 'changing options by hotkeys' do
      context 'when no initial search string given' do
        shared_examples 'it sets options using hotkey' do |hotkey, options|
          it "sets #{options} using hotkey" do
            expect {
              editor.send_keys(*open_input, open_menu)
              editor.send_keys(hotkey, 'search str', :enter)
            }.to set_global_options(options)
              .and start_search_with_options(options)
              .and have_search_finished_for('search str')
          end
        end

        context 'set options' do
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

        context 'reset options' do
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

      context 'when initial search string is given' do
        before { esearch.configuration.submit!(overwrite: true) }

        it "doesn't affect initial search string" do
          editor.send_keys(*open_input, 'initial value', :enter)

          expect {
            editor.send_keys(*open_input, open_menu)
            editor.send_keys('r')
          }.not_to start_search

          expect { editor.send_keys(:enter) }
            .to start_search
            .and start_search_with_options('regex' => 1)
            .and have_search_finished_for('initial value')
        end
      end
    end

    context 'changing options by moving menu selection' do
      shared_context 'opened menu testing' do
        before do
          esearch.configuration.submit!(overwrite: true)
          editor.command('call esearch#util_testing#spy_echo()')
          editor.send_keys(*open_input, open_menu)
        end
        after { editor.command('call esearch#util_testing#unspy_echo()') }
      end

      shared_examples 'it selects regex option' do |keys:|
        context "it selects regex option by pressing #{keys}" do
          include_context 'opened menu testing'

          it do
            expect {
              editor.send_keys(keys, :enter, 'search string', :enter)
            }.to change { menu_items }
              .from(match_array([
                                  /\A> c .+/,
                                  /\A  r .+/,
                                  /\A  w .+/
                                ]))
              .to(match_array([
                                /\A  c .+/,
                                /\A> r .+/,
                                /\A  w .+/
                              ]))
              .and set_global_options('regex' => 1)
              .and start_search_with_options('regex' => 1)
          end
        end
      end

      shared_examples 'it selects word option' do |keys:|
        context "it selects word option by pressing #{keys}" do
          include_context 'opened menu testing'

          it do
            expect {
              editor.send_keys(keys, :enter, 'search string', :enter)
            }.to change { menu_items }
              .from(match_array([
                                  /\A> c .+/,
                                  /\A  r .+/,
                                  /\A  w .+/
                                ]))
              .to(match_array([
                                /\A  c .+/,
                                /\A  r .+/,
                                /\A> w .+/
                              ]))
              .and set_global_options('word' => 1)
              .and start_search_with_options('word' => 1)
          end
        end
      end

      shared_examples 'it selects case option' do |keys:|
        context "it selects case option by pressing #{keys}" do
          include_context 'opened menu testing'

          it do
            expect {
              editor.send_keys(keys)
              editor.send_keys(:enter, 'search string', :enter)
            }.to set_global_options('case' => 1)
              .and start_search_with_options('case' => 1)

          end

          it do
            expect {
              editor.send_keys(keys)
              editor.send_keys(:enter, 'search string', :enter)
            }.to start_search_with_options('case' => 1)
              .and not_to_change { menu_items }
              .from(match_array([
                                  /\A> c .+/,
                                  /\A  r .+/,
                                  /\A  w .+/
                                ]))
          end
        end
      end

      include_examples 'it selects regex option', keys: 'j'
      include_examples 'it selects regex option', keys: '\\<C-j>'

      include_examples 'it selects word option',   keys: 'k'
      include_examples 'it selects word option',   keys: 'jj'
      include_examples 'it selects word option',   keys: '\\<C-k>'
      include_examples 'it selects word option',   keys: '\\<C-j>\\<C-j>'

      include_examples 'it selects case option',   keys: nil
      include_examples 'it selects case option',   keys: 'jjj'
      include_examples 'it selects case option',   keys: 'kkk'
    end

    context 'preserving cursor location' do
      let(:change_match_mode) { 'r' }
      before { esearch.configuration.submit!(overwrite: true) }

      context 'in the middle' do
        context 'even search string length' do
          it 'preserves location after closing menu' do
            editor.send_keys(*open_input, 'abcd', :left, :left, open_menu)
            editor.send_keys(change_match_mode, '\\<C-w>', :enter)

            expect(esearch).to have_search_finished_for('cd')
          end
        end

        context 'odd search string length' do
          it 'preserves location after closing menu' do
            editor.send_keys(*open_input, 'abc', :left, open_menu)
            editor.send_keys(change_match_mode, '\\<C-w>', :enter)

            expect(esearch).to have_search_finished_for('c')
          end
        end
      end

      context 'in the beginning' do
        it 'preserves location after closing menu' do
          editor.send_keys(*open_input, 'abc', :left, :left, :left, open_menu)
          editor.send_keys(change_match_mode, :delete, :enter)

          expect(esearch).to have_search_finished_for('bc')
        end
      end

      context 'in the end' do
        it 'preserves location after closing menu' do
          editor.send_keys(*open_input, 'abc', open_menu)
          editor.send_keys(change_match_mode, :backspace, :enter)

          expect(esearch).to have_search_finished_for('ab')
        end
      end
    end

    context 'cancelling selection' do
      before { esearch.configuration.submit!(overwrite: true) }

      shared_examples 'it searches previous input' do |keys:|
        let(:previous_search_string) { 'initial search string' }
        let(:hotkey_with_the_same_prefix) do
          [editor.keyboard_keys_to_string(*keys, escape: false),
           'randomkeys'].join
        end

        before { editor.command("cmap  #{hotkey_with_the_same_prefix} noop") }
        after  { editor.command("cunmap #{hotkey_with_the_same_prefix}") }

        it "it searches previous input when #{keys} are pressed" do
          editor.send_keys(*open_input, previous_search_string, :enter)
          expect(esearch).to have_search_finished_for(previous_search_string)

          expect { editor.send_keys(*open_input, *keys) }.not_to start_search

          expect { editor.send_keys(:enter) }
            .to start_search
            .and start_search_with_previous_input(previous_search_string)
        end
      end

      shared_context 'define commandline hotkey mapping' do |lhs, rhs|
        before { editor.command("cmap  #{lhs} #{rhs}") }
        after  { editor.command("cunmap #{lhs}") }
      end

      shared_examples 'it searches using' do |keys:, previous: 'initial vale', current: 'got value'|
        it "it searches previous input when #{keys} are pressed" do
          editor.send_keys(*open_input, previous, :enter)
          expect(esearch).to have_search_finished_for(previous)

          expect {
            editor.send_keys(*open_input)
            editor.send_keys_separately(*keys)
          }.not_to start_search

          expect { editor.send_keys(:enter) }
            .to start_search
            .and have_search_finished_for(current)
        end
      end

      context 'mapped keys pressing' do
        # TODO
        it_behaves_like 'it searches previous input',  keys: ['\\<C-o>', :escape]
      end

      context 'cancelling without moving cursor' do
        it_behaves_like 'it searches previous input',  keys: ['\\<C-c>']
        it_behaves_like 'it searches previous input',  keys: %i[escape]

        context 'up and down keys' do
          # in vim8 a trailing char appears for a short period and cause extra
          # character to be searched
          before { editor.command('set timeoutlen=0') }
          after { editor.command('set timeoutlen=1000') }
          it_behaves_like 'it searches previous input', keys: %i[up down]
        end
      end

      context 'cancelling with moving cursor' do
        it_behaves_like 'it searches using',
          keys:     ['\\<Left>', :backspace],
          previous: 'abcd',
          current:  'abd'

        it_behaves_like 'it searches using',
          keys:     ['\\<Right>', :backspace],
          previous: 'abcd',
          current:  'abc'

        it_behaves_like 'it searches using',
          keys:     ['\\<S-Left>', :delete],
          previous: 'abcd',
          current:  'bcd'

        it_behaves_like 'it searches using',
          keys:     ['\\<S-Right>', :backspace],
          previous: 'abcd',
          current:  'abc'
      end

      it_behaves_like 'it searches previous input',  keys: ['\\<C-a>']
      it_behaves_like 'it searches previous input',  keys: ['\\<C-e>']

      context 'pressing unknown keys after previous search string' do
        it_behaves_like 'it searches using',
          keys:     ['\\<Tab>'],
          previous: 'abcd',
          current:  "abcd\t"
      end

      context 'compliance with meta mappings' do
        context 'alt-f' do
          include_context 'define commandline hotkey mapping', '<M-f>', '<S-Right>'
          include_examples 'it searches previous input', keys: ['\\<M-f>']
        end
        context 'alt-b' do
          include_context 'define commandline hotkey mapping', '<M-b>', '<S-Left>'
          include_examples 'it searches previous input', keys: ['\\<M-b>']
        end
      end
    end
  end

  context 'neovim' do
    around(:context) { |e| use_nvim(&e) }

    include_examples 'impl'
  end

  context 'vim' do
    include_examples 'impl'
  end
end
