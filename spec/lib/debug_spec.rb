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
    let(:testing_directory) { directory([test_file]).persist! }
    let(:buffer_configuration) { {'anything_without_request' => 2} }
    let(:working_directories) do
      {'$PWD' => Configuration.root, 'getcwd()' => testing_directory.path}
    end

    before(:each) do
      esearch.cd! testing_directory
      esearch.edit! test_file

      esearch.editor.command!([
        'let g:esearch = "global_configuration"',
        'let b:esearch = {"request": "request_configuration", "anything_without_request": 2}',
        'au User TestAutocommand echo 1'
      ].join('|'))
    end
    after(:context) { esearch.editor.command!('unlet! g:esearch | unlet! b:esearch | au! User *') }

    context 'options' do
      it { expect(debug.update_time).to           be > 0                     }
      it { expect(debug.working_directories).to   match(working_directories) }
    end

    context 'commands' do
      it { expect(debug.messages).to              all be_present                   }
      it { expect(debug.sourced_scripts).to       all match(%r{\s*\d+:\s*[\w/]+})  }
      it { expect(debug.runtimepath).to           all be_present                   }
      it { expect(debug.buffers).to               all be_present                   }
      it { expect(debug.user_autocommands).to     include match('TestAutocommand') }
    end

    context 'esearch configurations' do
      it { expect(debug.global_configuration).to  eq("global_configuration")  }
      it { expect(debug.buffer_configuration).to  eq(buffer_configuration)    }
      it { expect(debug.request_configuration).to eq('request_configuration') }
      it { expect(debug.buffer_content).to        eq(test_lines)              }
    end
  end
end
