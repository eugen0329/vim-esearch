# frozen_string_literal: true

require 'spec_helper'
require 'mkmf'

describe Debug do
  include Helpers::FileSystem

  let(:test_file) { file(%w[line1 line2]) }
  let(:log_file) { file("log entry1\nlog entry2") }
  let!(:testing_directory) { directory([test_file, log_file]).persist! }

  subject(:debug) { described_class }

  after(:context) { esearch.editor.command!('unlet! g:esearch b:esearch | au! User *') }

  describe '.plugin_log' do
    shared_examples 'it reads and outputs plugin log' do
      context 'present' do
        it { expect(debug.plugin_log(path: log_file.path)).to eq(log_file.lines) }
      end

      context 'missing' do
        it { expect(debug.plugin_log(path: 'missing')).to be_nil }
      end
    end

    context 'vim server' do
      it_behaves_like 'it reads and outputs plugin log'
    end

    context 'neovim server' do
      around(Configuration.vimrunner_switch_to_neovim_callback_scope) { |e| use_nvim(&e) }

      it_behaves_like 'it reads and outputs plugin log'
    end
  end

  describe '.nvim_log' do
    let(:server) { Configuration.vim.server }

    context 'vim server' do
      # or should it be an exception?
      it { expect(debug.nvim_log).to be_nil }
    end

    context 'neovim server' do
      around(Configuration.vimrunner_switch_to_neovim_callback_scope) { |e| use_nvim(&e) }

      context 'present' do
        it do
          expect(server).to receive(:nvim_log_file).and_return(log_file.path)
          expect(debug.nvim_log).to eq(log_file.lines)
        end
      end

      context 'missing' do
        it do
          expect(server).to receive(:nvim_log_file).and_return('missing')
          expect(debug.nvim_log).to be_nil
        end
      end
    end
  end

  describe '.verbose_log_file' do
    let(:server) { Configuration.vim.server }

    context 'vim server' do
      # or should it be an exception?
      it { expect(debug.verbose_log).to be_nil }
    end

    context 'neovim server' do
      around(Configuration.vimrunner_switch_to_neovim_callback_scope) { |e| use_nvim(&e) }

      context 'present' do
        it do
          expect(server).to receive(:verbose_log_file).and_return(log_file.path)
          expect(debug.verbose_log).to eq(log_file.lines)
        end
      end

      context 'missing' do
        it do
          expect(server).to receive(:verbose_log_file).and_return('missing')
          expect(debug.verbose_log).to be_nil
        end
      end
    end
  end

  describe '.update_time' do
    it { expect(debug.update_time).to be > 0 }
  end

  describe '.working_directories' do
    let(:expected) do
      {'$PWD' => Configuration.root, 'getcwd()' => testing_directory.path}
    end

    before { esearch.cd! testing_directory }

    it { expect(debug.working_directories).to match(expected) }
  end

  context '.screenshot!' do
    subject(:screenshot_file) { debug.screenshot! }

    before { skip "Can't find scrot executable" unless find_executable0('scrot') }
    after  { screenshot_file&.delete }

    context 'success' do
      subject(:screenshot_file) { debug.screenshot! }

      it { expect(screenshot_file).to be_file }
      it { expect(screenshot_file.size).to be > 0 }
    end

    context 'failure' do
      subject(:screenshot_file) { debug.screenshot!(directory: 'missing') }

      it do
        require 'pry'; binding.pry
        expect(screenshot_file).to be_nil
      end
    end
  end

  describe '.messages' do
    it { expect(debug.messages).to include match('Messages maintainer:') }
  end

  describe '.buffers' do
    before { esearch.edit! test_file }

    it { expect(debug.buffers).to include match(test_file.relative_path) }
  end

  describe '.runtimepaths' do
    it do
      expect(debug.runtimepaths).to include Configuration.root.to_s
    end
  end

  describe '.sourced_scripts' do
    let(:plugin_path) { Configuration.root.join('plugin/esearch.vim').to_s }

    it { expect(debug.sourced_scripts).to include match(plugin_path) }
  end

  describe '.buffer_content' do
    before { esearch.edit! test_file }

    it { expect(debug.buffer_content).to eq(test_file.lines) }
  end

  context '.buffer_configuration' do
    context 'when defined' do
      before { esearch.editor.command!('let b:esearch = {"option": ["..."]}') }

      it { expect(debug.buffer_configuration).to eq('option' => ['...']) }
    end

    context 'when undefined' do
      before(:context) { esearch.editor.command!('unlet! b:esearch') }

      it do
        expect(debug.buffer_configuration)
          .to  be_a(String)
          .and include('Undefined')
      end
    end
  end

  describe '.global_configuration' do
    context 'when defined' do
      before { esearch.editor.command!('let g:esearch = "global_configuration"') }

      it { expect(debug.global_configuration).to eq('global_configuration') }
    end

    context 'when undefined' do
      before { esearch.editor.command!('unlet! g:esearch') }

      it do
        expect(debug.global_configuration)
          .to  be_a(String)
          .and include('Undefined')
      end
    end
  end

  describe '.user_autocommands' do
    before { esearch.editor.command!('au User TestAutocommand echo 42') }

    it { expect(debug.user_autocommands).to include match('TestAutocommand') }
    it { expect(debug.user_autocommands).to include match('echo 42') }
  end
end
