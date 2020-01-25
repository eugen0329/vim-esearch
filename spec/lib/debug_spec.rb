# frozen_string_literal: true

require 'spec_helper'

describe Debug, :debug do
  include Helpers::FileSystem
  let(:debug) { described_class }

  context 'undefined' do
    before(:context) { esearch.editor.command!('unlet! g:esearch | unlet! b:esearch') }

    it { expect(debug.global_configuration).to  include('Undefined') }
    it { expect(debug.buffer_configuration).to  include('Undefined') }
    it { expect(debug.request_configuration).to include('Undefined') }
  end

  context 'defined' do
    let(:test_lines) { %w[line1 line2] }
    let(:test_file) { file(test_lines) }
    let(:log_file) { file("log entry1\nlog entry2") }
    let(:testing_directory) { directory([test_file, log_file]).persist! }
    let(:buffer_configuration) { {'anything_without_request' => 2} }
    let(:esearch_path) { Configuration.root.join('plugin/esearch.vim').to_s }
    let(:working_directories) do
      {'$PWD' => Configuration.root, 'getcwd()' => testing_directory.path}
    end

    before(:each) do
      esearch.cd! testing_directory
      esearch.edit! test_file

      esearch.editor.command!([
        'let g:esearch = "global_configuration"',
        'let b:esearch = {"request": "request_configuration", "anything_without_request": 2}',
        'au User TestAutocommand echo 1',
      ].join('|'))
    end

    after(:context) { esearch.editor.command!('unlet! g:esearch b:esearch | au! User *') }

    context 'options' do
      it { expect(debug.update_time).to           be > 0                     }
      it { expect(debug.working_directories).to   match(working_directories) }
    end

    context 'logging' do
      context 'vim' do
        context 'present' do
          it { expect(debug.plugin_log(log_file.path)).to eq(log_file.lines) }
        end

        context 'missing' do
          it { expect(debug.plugin_log('missing')).to be_nil }
        end
      end

      context 'neovim' do
        let(:server) { Configuration.vim.server }

        around(Configuration.vimrunner_switch_to_neovim_callback_scope) { |e| use_nvim(&e) }

        context 'present' do
          it { expect(debug.plugin_log(log_file.path)).to eq(log_file.lines) }

          it do
            expect(server).to receive(:verbose_log_file).and_return(log_file.path)
            expect(debug.verbose_log).to eq(log_file.lines)
          end

          it do
            expect(server).to receive(:nvim_log_file).and_return(log_file.path)
            expect(debug.nvim_log).to eq(log_file.lines)
          end
        end

        context 'missing' do
          it { expect(debug.plugin_log(log_file.path)).to eq(log_file.lines) }

          it do
            expect(server).to receive(:verbose_log_file).and_return('missing')
            expect(debug.verbose_log).to be_nil
          end

          it do
            expect(server).to receive(:nvim_log_file).and_return('missing')
            expect(debug.nvim_log).to be_nil
          end
        end
      end
    end

    context 'lists' do
      it { expect(debug.messages).to          include match('Messages maintainer:')  }
      it { expect(debug.sourced_scripts).to   include match(esearch_path)            }
      it { expect(debug.runtimepaths).to      include Configuration.root.to_s        }
      it { expect(debug.buffers).to           include match(test_file.relative_path) }
      it { expect(debug.user_autocommands).to include match('TestAutocommand')       }
    end

    context 'esearch configurations' do
      it { expect(debug.global_configuration).to  eq("global_configuration")  }
      it { expect(debug.buffer_configuration).to  eq(buffer_configuration)    }
      it { expect(debug.request_configuration).to eq('request_configuration') }
      it { expect(debug.buffer_content).to        eq(test_lines)              }
    end
  end
end
