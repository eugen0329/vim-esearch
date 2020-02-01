# frozen_string_literal: true

require 'spec_helper'

context 'esearch#cmdline' do
  context 'change' do
    after do
      esearch.editor.command!('let g:stubbed_output_args_history = []')
    end

    before do
      esearch.configure(out: 'stubbed')
      esearch.configuration.submit!(overwrite: true)
      esearch.editor.press_with_user_mappings! '\\\\ff\\<C-o>'
    end


    it do
      esearch.editor.press_with_user_mappings! '\\<C-r>'
      esearch.editor.press_with_user_mappings! '123\\<CR>'
      expect(esearch.editor.stubbed_output_args_history[-1]['regex']).to eq(1)
    end

    it do
      esearch.editor.press_with_user_mappings! '\\<C-s>'
      esearch.editor.press_with_user_mappings! '123\\<CR>'
      expect(esearch.editor.stubbed_output_args_history[-1]['case']).to eq(1)
    end

    it do
      esearch.editor.press_with_user_mappings! '\\<C-w>'
      esearch.editor.press_with_user_mappings! '123\\<CR>'
      expect(esearch.editor.stubbed_output_args_history[-1]['word']).to eq(1)
    end

  end

  context 'preserve position' do
    it 'even' do
      esearch.configure(out: 'stubbed')
      esearch.configuration.submit!(overwrite: true)
      esearch.editor.press_with_user_mappings! '\\\\ffabcd\\<Left>\\<Left>'
      esearch.editor.press_with_user_mappings! '\\<C-o>'
      esearch.editor.press_with_user_mappings! 'r\\<C-w>'
      esearch.editor.press_with_user_mappings! '\\<CR>'

      expect(esearch.editor.stubbed_output_args_history[-1]['exp']['pcre']).to eq('cd')
    end

    it 'odd' do
      esearch.configure(out: 'stubbed')
      esearch.configuration.submit!(overwrite: true)
      esearch.editor.press_with_user_mappings! '\\\\ffabc\\<Left>'
      esearch.editor.press_with_user_mappings! '\\<C-o>'
      esearch.editor.press_with_user_mappings! 'r\\<C-w>'
      esearch.editor.press_with_user_mappings! '\\<CR>'

      expect(esearch.editor.stubbed_output_args_history[-1]['exp']['pcre']).to eq('c')
    end

    it 'beginning' do
      esearch.configure(out: 'stubbed')
      esearch.configuration.submit!(overwrite: true)
      esearch.editor.press_with_user_mappings! '\\\\ffabc\\<Left>\\<Left>\\<Left>\\<Del>'
      esearch.editor.press_with_user_mappings! '\\<C-o>'
      esearch.editor.press_with_user_mappings! 'r'
      esearch.editor.press_with_user_mappings! '\\<CR>'

      expect(esearch.editor.stubbed_output_args_history[-1]['exp']['pcre']).to eq('bc')
    end

    it 'end' do
      esearch.configure(out: 'stubbed')
      esearch.configuration.submit!(overwrite: true)
      esearch.editor.press_with_user_mappings! '\\\\ffabc'
      esearch.editor.press_with_user_mappings! '\\<C-o>'
      esearch.editor.press_with_user_mappings! 'r'
      esearch.editor.press_with_user_mappings! '\\<BS>\\<CR>'

      expect(esearch.editor.stubbed_output_args_history[-1]['exp']['pcre']).to eq('ab')
    end
  end

  context 'with prefilled' do
    it do
      esearch.configure(out: 'stubbed')
      esearch.configuration.submit!(overwrite: true)
      esearch.editor.press_with_user_mappings! '\\\\ff1\\<CR>'
      expect(esearch.editor.stubbed_output_args_history[-1]['exp']['literal']).to eq('1')

      esearch.editor.press_with_user_mappings! '\\\\ff\\<C-o>'
      esearch.editor.press_with_user_mappings! '\\<C-r>'
      esearch.editor.press_with_user_mappings! '123\\<CR>'
      expect(esearch.editor.stubbed_output_args_history[-1]['regex']).to eq(1)
      expect(esearch.editor.stubbed_output_args_history[-1]['exp']['pcre']).to eq('123')
    end
  end
end
