require 'spec_helper'
require 'plugin/shared_examples/backend.rb'
require 'plugin/shared_examples/abortable_backend.rb'
require 'plugin/shared_contexts/dumpable.rb'

context 'esearch' do
  context '#backend' do
    describe '#vimproc' do
      before(:all) do
        press ":let g:esearch#backend#vimproc#updatetime = 30"
        press ":let g:esearch#backend#vimproc#read_timeout = 30"
      end

      it_behaves_like 'a backend', 'vimproc'# if ENV['TRAVIS_OS_NAME'] != 'osx'
      it_behaves_like 'a backend', 'vimproc'
      it_behaves_like 'an abortable backend', 'vimproc'
    end
  end
end
