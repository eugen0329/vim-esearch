# frozen_string_literal: true

require 'spec_helper'
require 'mkmf'

describe DumpEditorStateOnErrorFormatter do
  describe '#example_failed' do
    let(:output) { String.new }
    let(:dummy_notification) { double(:dummy_notification) }
    let(:console_color_code_regexp) { /\e\[\d+m/ }

    subject(:formatter) { described_class.new(output) }

    before do
      expect(Debug).to receive(:runtimepaths).and_return(['<runtimepaths>'])
      expect(Debug).to receive(:sourced_scripts).and_return(['<sourced_scripts>'])
      expect(Debug).to receive(:buffer_content).and_return(['<buffer_content>'])
      expect(Debug).to receive(:buffer_configuration).and_return('<buffer_configuration>')
      expect(Debug).to receive(:global_configuration).and_return('<global_configuration>')
      expect(Debug).to receive(:user_autocommands).and_return(['<user_autocommands>'])
      expect(Debug).to receive(:plugin_log).and_return(['<plugin_log>'])
      expect(Debug).to receive(:nvim_log).and_return(['<nvim_log>'])
      expect(Debug).to receive(:verbose_log).and_return(['<verbose_log>'])
      expect(Debug).to receive(:update_time).and_return('<update_time>')
      expect(Debug).to receive(:working_directories).and_return('<working_directories>': '<working_directories>')
      expect(Debug).to receive(:messages).and_return(['<messages>'])
      expect(Debug).to receive(:buffers).and_return(['<buffers>'])
      expect(Debug).to receive(:screenshot!).and_return('<screenshot_path>')
    end

    it 'outputs all the debug data' do
      formatter.example_failed(dummy_notification)

      expect(output)
        .to  include('<runtimepaths>')
        .and include('<sourced_scripts>')
        .and include('<buffer_content>')
        .and include('<buffer_configuration>')
        .and include('<global_configuration>')
        .and include('<user_autocommands>')
        .and include('<plugin_log>')
        .and include('<nvim_log>')
        .and include('<verbose_log>')
        .and include('<update_time>')
        .and include('<working_directories>')
        .and include('<messages>')
        .and include('<buffers>')
        .and include('<screenshot_path>')
    end

    it 'outputs colorized' do
      formatter.example_failed(dummy_notification)

      expect(output)
        .to  match(/\A#{console_color_code_regexp}/)
        .and match(/#{console_color_code_regexp}\z/)
    end

    context 'output indentation' do
      let(:indentation_level) { 2 }
      let(:output_lines_without_color) do
        output.gsub(console_color_code_regexp, '').split("\n")
      end

      it 'outputes with correct indentation' do
        indentation_level.times { formatter.example_group_started(dummy_notification) }
        formatter.example_failed(dummy_notification)

        expect(output_lines_without_color)
          .to all start_with('  ' * indentation_level)
      end

      it 'is able to revert indentation' do
        indentation_level.times { formatter.example_group_started(dummy_notification) }
        indentation_level.times { formatter.example_group_finished(dummy_notification) }
        formatter.example_failed(dummy_notification)

        expect(output_lines_without_color)
          .to include start_with(/[^\s]/)
      end
    end
  end
end
