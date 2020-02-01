# frozen_string_literal: true

require 'spec_helper'

context 'esearch#cmdline' do
  after { editor.command!('let g:stubbed_output_args_history = []') }
  let(:open_menu) { '\\<C-o>' }
  let(:start_search) { [:leader, 'ff'] }
  let(:call_history) {editor.stubbed_output_args_history[-1]  }

  context 'change' do
    before do
      esearch.configure!(out: 'stubbed')
      editor.send_keys *start_search, open_menu
    end

    it do
      editor.send_keys '\\<C-r>', '123', :enter
      expect(call_history['regex']).to eq(1)
    end

    it do
      editor.send_keys '\\<C-s>', '123', :enter
      expect(call_history['case']).to eq(1)
    end

    it do
      editor.send_keys '\\<C-w>', '123', :enter
      expect(call_history['word']).to eq(1)
    end
  end

  context 'preserving position' do
    before { esearch.configure!(out: 'stubbed') }

    context 'in the middle' do
      it 'even' do
        editor.send_keys *start_search, 'abcd', :left, :left, open_menu
        editor.send_keys 'r', '\\<C-w>', :enter

        expect(call_history['exp']['pcre']).to eq('cd')
      end

      it 'odd' do
        editor.send_keys *start_search, 'abc', :left, open_menu
        editor.send_keys 'r', '\\<C-w>', :enter

        expect(call_history['exp']['pcre']).to eq('c')
      end
    end

    context 'in the beginning'  do
      it do
        editor.send_keys *start_search, 'abc', :left, :left, :left, :delete, open_menu
        editor.send_keys 'r', :enter

        expect(call_history['exp']['pcre']).to eq('bc')
      end
    end

    context  'in the end' do
      it do
        editor.send_keys *start_search, 'abc', open_menu
        editor.send_keys 'r', :backspace, :enter

        expect(call_history['exp']['pcre']).to eq('ab')
      end
    end
  end

  context 'with prefilled' do
    before do
      esearch.configure!(out: 'stubbed')
    end

    it do
      editor.send_keys *start_search, '1',  :enter
      editor.send_keys *start_search, open_menu
      editor.send_keys '\\<C-r>', '123', :enter

      expect(call_history)
        .to include('regex' => 1, 'exp' => include('pcre' => '123'))
    end
  end
end
