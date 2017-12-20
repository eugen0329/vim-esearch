require 'spec_helper'
require 'plugin/shared_examples/backend.rb'
require 'plugin/shared_contexts/dumpable.rb'

context 'esearch' do
  context '#backend' do

    describe '#vimproc' do
      it_behaves_like 'a backend', 'vimproc'# if ENV['TRAVIS_OS_NAME'] != 'osx'
    end

  end
end
