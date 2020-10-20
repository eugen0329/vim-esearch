# frozen_string_literal: true

require 'spec_helper'
require 'mkmf'

describe Debug do
  include Helpers::FileSystem

  let(:test_file) { file(%w[line1 line2]) }
  let(:log_file) { file("log entry1\nlog entry2") }
  let!(:test_directory) { directory([test_file, log_file]).persist! }

  subject(:debug) { described_class }

  after(:context) { editor.command!('unlet! g:esearch b:esearch | au! User *') }

  describe '.plugin_log' do
    shared_examples 'it reads and outputs plugin log' do
      context 'when present' do
        it { expect(debug.plugin_log(path: log_file.path)).to eq(log_file.lines) }
      end

      context 'when missing' do
        it { expect(debug.plugin_log(path: 'missing')).to be_nil }
      end
    end

    it_behaves_like 'it reads and outputs plugin log'
  end

  describe '.running_processes' do
    shared_examples 'outputs running processes' do
      it do
        expect(debug.running_processes)
          .to be_a(Array)
          .and include match(/\s*#{vim.server.pid}.+#{vim.server.executable}/)
      end
    end

    include_examples 'outputs running processes'
  end

  describe '.working_directories' do
    let(:cwd_content) do
      test_directory
        .files
        .map { |f| [f.path.basename.to_s, f.readlines] }
        .push(['.git', 'directory'])
        .sort
    end
    let(:expected) do
      {
        '$PWD'        => Configuration.root,
        'getcwd()'    => test_directory.path,
        'cwd_content' => cwd_content,
      }
    end

    before { esearch.cd! test_directory }

    it do
      expect(debug.working_directories).to match(expected)
    end
  end

  describe '.screenshot!' do
    subject(:screenshot_file) { debug.screenshot! }

    before { skip "Can't find scrot executable" unless find_executable0('scrot') }
    after  { screenshot_file&.delete }

    context 'default name' do
      context 'when success' do
        subject(:screenshot_file) { debug.screenshot! }

        it { expect(screenshot_file).to be_file }
        it { expect(screenshot_file.size).to be > 0 }
      end

      context 'when failure' do
        subject(:screenshot_file) { debug.screenshot!(directory: 'missing') }

        it { expect(screenshot_file).to be_nil }
      end
    end

    context 'custom name' do
      context 'when success' do
        subject(:screenshot_file) { debug.screenshot!('custom_name.png') }

        it { expect(screenshot_file.basename.to_s).to eq('custom_name.png') }
        it { expect(screenshot_file).to be_file }
        it { expect(screenshot_file.size).to be > 0 }
      end

      context 'when failure' do
        subject(:screenshot_file) { debug.screenshot!('custom_name.png', directory: 'missing') }

        it { expect(screenshot_file).to be_nil }
      end
    end
  end

  describe '.messages' do
    it do
      expect(debug.messages)
        .to be_a(Array)
        .and be_present
    end
  end

  describe '.buffers' do
    before { esearch.edit! test_file }

    it { expect(debug.buffers).to include match(test_file.relative_path) }
  end

  describe '.runtimepaths' do
    xit { expect(debug.runtimepaths).to include Configuration.root.to_s }
  end

  describe '.sourced_scripts' do
    let(:plugin_path) do
      Configuration
        .root
        .join('plugin/esearch.vim')
        .to_s
        .gsub(`echo $HOME`.chomp, '')
    end

    it { expect(debug.sourced_scripts).to include match(plugin_path) }
  end

  describe '.buffer_content' do
    before { esearch.edit! test_file }

    it { expect(debug.buffer_content).to eq(test_file.lines) }
  end

  describe '.configuration' do
    context 'when defined' do
      before { editor.command!('let g:esearch = {"global": "configuration"}') }

      it { expect(debug.configuration('g:esearch')).to eq('global' => 'configuration') }
    end

    context 'when undefined' do
      before { editor.command!('unlet! g:esearch') }

      it do
        expect(debug.global_configuration)
          .to  be_a(String)
          .and include('Undefined')
      end
    end
  end

  describe '.user_autocommands' do
    before { editor.command!('au User TestAutocommand echo 42') }

    it { expect(debug.user_autocommands).to include match('TestAutocommand') }
    it { expect(debug.user_autocommands).to include match('echo 42') }
  end
end
