# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#cmdline menu' do
  let(:open_menu) { '\\<C-o>' }
  let(:start_search) { [:leader, 'ff'] }

  def output_spy_calls
    esearch.output.calls_history
  end

  before { esearch.configure(out: 'stubbed', backend: 'system') }
  after { esearch.output.reset_calls_history! }

  context 'changing options by hotkeys' do
    shared_examples 'it sets options using hotkey' do |hotkey, options|
      it "sets #{options} using hotkey" do
        expect {
          editor.send_keys(*start_search, open_menu)
          editor.send_keys(hotkey, 'search str', :enter)
        }.to change { esearch.configuration.global }
          .to include(*options)

        expect(output_spy_calls.last).to include(options)
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

  context 'when initial value is given' do
    before { esearch.configuration.submit!(overwrite: true) }

    it do
      editor.send_keys(*start_search, 'initial value', :enter)
      editor.send_keys(*start_search, open_menu)
      editor.send_keys('r', 'search str', :enter)

      expect(output_spy_calls.last)
        .to include('regex' => 1, 'exp' => include('pcre' => 'search str'))
    end
  end

  describe 'changing options by moving menu selection' do
    before do
      esearch.configuration.submit!(overwrite: true)
      editor.command('call esearch#util_testing#spy_echo()')
      editor.send_keys(*start_search, open_menu)
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
            editor.send_keys(keys, :enter, 'search string', :enter)
          }.to change { esearch.configuration.global }
            .to include(*{'case' => 1})
          expect(output_spy_calls.last).to include('case' => 1)
        end

        it do
          expect {
            editor.send_keys(keys, :enter, 'search string', :enter)
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
    let(:mode_key) { 'r' }
    let(:regexp_name) { 'pcre' }
    before { esearch.configuration.submit!(overwrite: true) }

    context 'in the middle' do
      it 'even' do
        editor.send_keys(*start_search, 'abcd', :left, :left, open_menu)
        editor.send_keys(mode_key, '\\<C-w>', :enter)

        expect(output_spy_calls.last['exp'][regexp_name]).to eq('cd')
      end

      it 'odd' do
        editor.send_keys(*start_search, 'abc', :left, open_menu)
        editor.send_keys(mode_key, '\\<C-w>', :enter)

        expect(output_spy_calls.last['exp'][regexp_name]).to eq('c')
      end
    end

    context 'in the beginning' do
      it do
        editor.send_keys(*start_search, 'abc', :left, :left, :left, :delete, open_menu)
        editor.send_keys(mode_key, :enter)

        expect(output_spy_calls.last['exp'][regexp_name]).to eq('bc')
      end
    end

    context 'in the end' do
      it do
        editor.send_keys(*start_search, 'abc', open_menu)
        editor.send_keys(mode_key, :backspace, :enter)

        expect(output_spy_calls.last['exp'][regexp_name]).to eq('ab')
      end
    end
  end

  context 'cancelling selection' do
    let(:mode_key) { 'r' }
    let(:regexp_name) { 'pcre' }
    before { esearch.configuration.submit!(overwrite: true)  }

    shared_examples 'it searches previous string' do |keys:, previous: 'initial vale'|
      define_negated_matcher :not_to_change, :change

      it "it searches previous string when #{keys} are pressed" do
        editor.send_keys(*start_search, previous, :enter)
        expect(output_spy_calls.last['exp']['literal']).to eq(previous)

        expect {
          editor.send_keys(*start_search)
          keys.each { |key| editor.send_keys(key) }
        }
          .to  change { output_spy_calls.last['id'] }
          .and not_to_change { output_spy_calls.last.dig('exp', 'literal') }
          .from(previous)
      end
    end

    shared_examples 'it searches using' do |keys:, previous: 'initial vale', current: 'got value'|
      it "it searches previous string when #{keys} are pressed" do
        editor.send_keys(*start_search, previous, :enter)
        expect(output_spy_calls.last['exp']['literal']).to eq(previous)

        expect {
          editor.send_keys(*start_search)
          keys.each { |key| editor.send_keys(key) }
        }
          .to change { output_spy_calls.last['id'] }
          .and change { output_spy_calls.last.dig('exp', 'literal') }
          .from(previous)
          .to(current)
      end
    end
    # TODO
    # include_examples 'it searches previous string',  keys: ["\\<C-o>", :escape, :enter]

    context 'cancelling without moving cursor' do
      include_examples 'it searches previous string',  keys: ['\\<C-c>', :enter]
      include_examples 'it searches previous string',  keys: %i[escape enter]
      include_examples 'it searches previous string',  keys: [:enter]
      include_examples 'it searches previous string',  keys: %i[up enter]
      include_examples 'it searches previous string',  keys: %i[down enter]
    end

    context 'cancelling with moving cursor' do
      include_examples 'it searches using',
        keys:     ['\\<Left>', :backspace, :enter],
        previous: 'abcd',
        current:  'abd'

      include_examples 'it searches using',
        keys:     ['\\<Right>', :backspace, :enter],
        previous: 'abcd',
        current:  'abc'

      include_examples 'it searches using',
        keys:     ['\\<S-Left>', :delete, :enter],
        previous: 'abcd',
        current:  'bcd'

      include_examples 'it searches using',
        keys:     ['\\<S-Right>', :backspace, :enter],
        previous: 'abcd',
        current:  'abc'
    end

    include_examples 'it searches previous string',  keys: ['\\<C-a>', :enter]
    include_examples 'it searches previous string',  keys: ['\\<C-e>', :enter]

    context 'pressing unknown keys after previous search string' do
      include_examples 'it searches using',
        keys:     ['\\<Tab>', :enter],
        previous: 'abcd',
        current:  "abcd\t"
    end

    # context 'message' do
    # include_examples 'it searches previous string',  keys: ["\\<M-f>", :enter]
    # include_examples 'it searches previous string',  keys: ["\\<M-b>", :enter]
    # end
    # include_examples 'it searches previous string',  keys: ["\\<Tab>", :enter]
  end
end
