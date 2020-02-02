# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#cmdline menu' do

  shared_examples 'impl' do
    let(:open_menu) { '\\<C-o>' }
    let(:open_input) { [:leader, 'ff'] }

    def output_spy_calls
      esearch.output.calls_history
    end

    define_negated_matcher :not_to_change, :change


    before do
      esearch.configure(out: 'stubbed', backend: 'system', use: 'last')
    end

    after { esearch.output.reset_calls_history! }

    context 'changing options by hotkeys' do
      shared_examples 'it sets options using hotkey' do |hotkey, options|
        it "sets #{options} using hotkey" do
          expect {
            editor.send_keys(*open_input, open_menu)
            editor.send_keys(hotkey, 'search str', :enter)
          }.to change { esearch.configuration.global }
            .to include(*options)

          expect(output_spy_calls.last).to include(options)
        end
      end

      context 'set options' do
        before { esearch.configure!('word': 0, 'case': 0, 'regex': 0) }

        it_behaves_like 'it sets options using hotkey', '\\<C-c>', 'case'  => 1
        it_behaves_like 'it sets options using hotkey', 'c',       'case'  => 1

        it_behaves_like 'it sets options using hotkey', '\\<C-w>', 'word'  => 1
        it_behaves_like 'it sets options using hotkey', 'w',       'word'  => 1

        it_behaves_like 'it sets options using hotkey', 'r',       'regex' => 1
        it_behaves_like 'it sets options using hotkey', '\\<C-r>', 'regex' => 1

        context 'legacy hotkeys' do
          it_behaves_like 'it sets options using hotkey', '\\<C-s>', 'case'  => 1
          it_behaves_like 'it sets options using hotkey', 's',       'case'  => 1
        end
      end

      context 'reset options' do
        before { esearch.configure!('word': 1, 'case': 1, 'regex': 1) }

        it_behaves_like 'it sets options using hotkey', '\\<C-c>', 'case'  => 0
        it_behaves_like 'it sets options using hotkey', 'c',       'case'  => 0

        it_behaves_like 'it sets options using hotkey', '\\<C-w>', 'word'  => 0
        it_behaves_like 'it sets options using hotkey', 'w',       'word'  => 0

        it_behaves_like 'it sets options using hotkey', '\\<C-r>', 'regex' => 0
        it_behaves_like 'it sets options using hotkey', 'r',       'regex' => 0

        context 'legacy hotkeys' do
          it_behaves_like 'it sets options using hotkey', '\\<C-s>', 'case'  => 0
          it_behaves_like 'it sets options using hotkey', 's',       'case'  => 0
        end
      end
    end

    context 'when initial value is given' do
      before { esearch.configuration.submit!(overwrite: true) }

      it do
        editor.send_keys(*open_input, 'initial value', :enter)
        editor.send_keys(*open_input, open_menu)
        editor.send_keys('r')
        editor.send_keys(:enter)

        expect(output_spy_calls.last)
          .to include('regex' => 1, 'exp' => include('pcre' => 'initial value'))
      end
    end

    describe 'changing options by moving menu selection' do
      before do
        esearch.configuration.submit!(overwrite: true)
        editor.command('call esearch#util_testing#spy_echo()')
        editor.send_keys(*open_input, open_menu)
      end
      after { editor.command('call esearch#util_testing#unspy_echo()') }

      def menu_items
        esearch.output.echo_calls_history.last(3)
      end

      shared_examples 'it selects regex option' do |keys:|
        context "it selects regex option by pressing #{keys}" do
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
              .and change { esearch.configuration.global }
              .to include(*{'regex' => 1})
            expect(output_spy_calls.last).to include('regex' => 1)
          end
        end
      end

      shared_examples 'it selects word option' do |keys:|
        context "it selects word option by pressing #{keys}" do
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
              .and change { esearch.configuration.global }
              .to include(*{'word' => 1})
            expect(output_spy_calls.last).to include('word' => 1)
          end
        end
      end

      shared_examples 'it selects case option' do |keys:|
        context "it selects case option by pressing #{keys}" do
          it do
            expect {
              editor.send_keys(keys)
              editor.send_keys(:enter, 'search string', :enter)
            }.to change { esearch.configuration.global }
              .to include(*{'case' => 1})
            expect(output_spy_calls.last).to include('case' => 1)
          end

          it do
            expect {
              editor.send_keys(keys)
              editor.send_keys(:enter, 'search string', :enter)
            }.not_to change { menu_items }
              .from(match_array([
                                  /\A> c .+/,
                                  /\A  r .+/,
                                  /\A  w .+/
                                ]))
            expect(output_spy_calls.last).to include('case' => 1)
          end
        end
      end

      it_behaves_like 'it selects regex option', keys: 'j'
      it_behaves_like 'it selects regex option', keys: '\\<C-j>'

      it_behaves_like 'it selects word option',   keys: 'k'
      it_behaves_like 'it selects word option',   keys: 'jj'
      it_behaves_like 'it selects word option',   keys: '\\<C-k>'
      it_behaves_like 'it selects word option',   keys: '\\<C-j>\\<C-j>'

      it_behaves_like 'it selects case option',   keys: nil
      it_behaves_like 'it selects case option',   keys: 'jjj'
      it_behaves_like 'it selects case option',   keys: 'kkk'
    end

    context 'preserving cursor location' do
      let(:mode_key) { 'r' }
      let(:regexp_name) { 'pcre' }
      before { esearch.configuration.submit!(overwrite: true) }

      context 'in the middle' do
        it 'even' do
          editor.send_keys(*open_input, 'abcd', :left, :left, open_menu)
          editor.send_keys(mode_key, '\\<C-w>', :enter)

          expect(output_spy_calls.last['exp'][regexp_name]).to eq('cd')
        end

        it 'odd' do
          editor.send_keys(*open_input, 'abc', :left, open_menu)
          editor.send_keys(mode_key, '\\<C-w>', :enter)

          expect(output_spy_calls.last['exp'][regexp_name]).to eq('c')
        end
      end

      context 'in the beginning' do
        it do
          editor.send_keys(*open_input, 'abc', :left, :left, :left, :delete, open_menu)
          editor.send_keys(mode_key, :enter)

          expect(output_spy_calls.last['exp'][regexp_name]).to eq('bc')
        end
      end

      context 'in the end' do
        it do
          editor.send_keys(*open_input, 'abc', open_menu)
          editor.send_keys(mode_key, :backspace, :enter)

          expect(output_spy_calls.last['exp'][regexp_name]).to eq('ab')
        end
      end
    end

    context 'cancelling selection' do
      let(:mode_key) { 'r' }
      let(:regexp_name) { 'pcre' }
      before { esearch.configuration.submit!(overwrite: true) }

      def start_search
        change { output_spy_calls.last }
      end

      shared_examples 'it searches previous string' do |keys:|
        let(:previous_search_string) { 'initial search string' }
        let(:mapping_to_wait) do
          [editor.keyboard_keys_to_string(*keys, escape: false),
           'randomkeys'].join
        end
        before { editor.command("cmap  #{mapping_to_wait} noop") }
        after  { editor.command("cunmap #{mapping_to_wait}") }

        it "it searches previous string when #{keys} are pressed" do
          editor.send_keys(*open_input, previous_search_string, :enter)
          expect(output_spy_calls.last['exp']['literal'])
            .to eq(previous_search_string)

          expect { editor.send_keys(*open_input, *keys) }.not_to start_search

          expect { editor.send_keys(:enter) }
            .to start_search
            .and not_to_change {
              [output_spy_calls.last.dig('exp', 'pcre'),
               output_spy_calls.last.dig('exp', 'literal')]
            }.from([previous_search_string, previous_search_string])
        end
      end

      shared_examples 'it searches previous string when user mapping is defined' do |keys:, lhs:, rhs:|
        before { editor.command("cmap  #{lhs} #{rhs}") }
        after  { editor.command("cunmap #{lhs}") }

        include_examples 'it searches previous string', keys: keys
      end

      shared_examples 'it searches using' do |keys:, previous: 'initial vale', current: 'got value'|
        it "it searches previous string when #{keys} are pressed" do
          editor.send_keys(*open_input, previous, :enter)
          expect(output_spy_calls.last['exp']['literal']).to eq(previous)

          expect {
            editor.send_keys(*open_input)
            keys.each { |key| editor.send_keys(key) }
          }.not_to start_search

          expect { editor.send_keys(:enter) }
            .to start_search
            .and change { output_spy_calls.last.dig('exp', 'pcre') }
            .to(current)
        end
      end

      context 'mapped keys pressing' do
        # TODO
        # it_behaves_like 'it searches previous string',  keys: ["\\<C-o>", :escape]
      end

      context 'cancelling without moving cursor' do
        it_behaves_like 'it searches previous string',  keys: ['\\<C-c>']
        it_behaves_like 'it searches previous string',  keys: %i[escape]

        context do
          before do
            # prevent errors with testing Up and Down produce a single char for
            # timeouten period
            editor.command('set timeoutlen=0')
          end
          after { editor.command('set timeoutlen=1000') }
          it_behaves_like 'it searches previous string',  keys: %i[up down]
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

      it_behaves_like 'it searches previous string',  keys: ['\\<C-a>']
      it_behaves_like 'it searches previous string',  keys: ['\\<C-e>']

      context 'pressing unknown keys after previous search string' do
        it_behaves_like 'it searches using',
          keys:     ['\\<Tab>'],
          previous: 'abcd',
          current:  "abcd\t"
      end

      context 'compliance with meta mappings' do
        it_behaves_like 'it searches previous string when user mapping is defined',
          keys: ['\\<M-f>'],
          lhs:  '<M-f>',
          rhs:  '<S-Right>'
        it_behaves_like 'it searches previous string when user mapping is defined',
          keys: ['\\<M-b>'],
          lhs:  '<M-b>',
          rhs:  '<S-Left>'
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
