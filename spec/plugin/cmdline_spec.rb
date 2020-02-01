# frozen_string_literal: true

require 'spec_helper'

context 'esearch#cmdline' do
  describe 'menu' do
    let(:open_menu) { '\\<C-o>' }
    let(:start_search) { [:leader, 'ff'] }
    let(:spy_calls) { editor.stubbed_output_args_history }

    after { editor.command!('let g:stubbed_output_args_history = []') }

    context 'changing' do
      shared_examples 'it sets options using menu' do |hotkey, options|
        it "sets #{options} using menu" do
          esearch.configure!(out: 'stubbed', backend: 'system')
          expect {
            editor.send_keys(*start_search, open_menu)
            editor.send_keys(hotkey, 'search str', :enter)
          }.to change { esearch.configuration.global }
            .to include(*options)

          expect(spy_calls.last).to include(options)
        end
      end

      context 'set options' do
        before { esearch.configure('word': 0, 'case': 0, 'regex': 0, backend: 'system') }

        include_examples 'it sets options using menu', '\\<C-r>', 'regex' => 1
        include_examples 'it sets options using menu', '\\<C-s>', 'case'  => 1
        include_examples 'it sets options using menu', '\\<C-w>', 'word'  => 1
        include_examples 'it sets options using menu', 'r',       'regex' => 1
        include_examples 'it sets options using menu', 's',       'case'  => 1
        include_examples 'it sets options using menu', 'w',       'word'  => 1
      end

      context 'reset options' do
        before { esearch.configure('word': 1, 'case': 1, 'regex': 1, backend: 'system') }

        include_examples 'it sets options using menu', '\\<C-r>', 'regex' => 0
        include_examples 'it sets options using menu', '\\<C-s>', 'case'  => 0
        include_examples 'it sets options using menu', '\\<C-w>', 'word'  => 0
        include_examples 'it sets options using menu', 'r',       'regex' => 0
        include_examples 'it sets options using menu', 's',       'case'  => 0
        include_examples 'it sets options using menu', 'w',       'word'  => 0
      end
    end

    context 'preserving position' do
      let(:mode_key) { 'r' }
      let(:regexp_name) { 'pcre' }
      before { esearch.configure!(out: 'stubbed', backend: 'system') }

      context 'in the middle' do
        it 'even' do
          editor.send_keys(*start_search, 'abcd', :left, :left, open_menu)
          editor.send_keys(mode_key, '\\<C-w>', :enter)

          expect(spy_calls.last['exp'][regexp_name]).to eq('cd')
        end

        it 'odd' do
          editor.send_keys(*start_search, 'abc', :left, open_menu)
          editor.send_keys(mode_key, '\\<C-w>', :enter)

          expect(spy_calls.last['exp'][regexp_name]).to eq('c')
        end
      end

      context 'in the beginning' do
        it do
          editor.send_keys(*start_search, 'abc', :left, :left, :left, :delete, open_menu)
          editor.send_keys(mode_key, :enter)

          expect(spy_calls.last['exp'][regexp_name]).to eq('bc')
        end
      end

      context 'in the end' do
        it do
          editor.send_keys(*start_search, 'abc', open_menu)
          editor.send_keys(mode_key, :backspace, :enter)

          expect(spy_calls.last['exp'][regexp_name]).to eq('ab')
        end
      end
    end

    context 'with prefilled' do
      before { esearch.configure!(out: 'stubbed', backend: 'system') }

      it do
        editor.send_keys(*start_search, '1', :enter)
        editor.send_keys(*start_search, open_menu)
        editor.send_keys('r', '123', :enter)

        expect(spy_calls.last)
          .to include('regex' => 1, 'exp' => include('pcre' => '123'))
      end
    end
  end
end
