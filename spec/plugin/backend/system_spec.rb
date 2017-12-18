require 'spec_helper'
require 'plugin/shared_examples/backend.rb'
require 'plugin/shared_contexts/dumpable.rb'

context 'esearch' do
  context '#backend' do

    describe '#system' do
      it_behaves_like 'a backend', 'system'
    end

  end
end
