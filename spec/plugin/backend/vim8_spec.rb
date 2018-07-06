require 'spec_helper'
require 'plugin/shared_examples/backend.rb'
require 'plugin/shared_contexts/dumpable.rb'

context 'esearch' do
  context '#backend' do

    describe '#vim8' do
      before { press ":let g:esearch#backend#vim8#timer = 100<Enter>" }

      it_behaves_like 'a backend', 'vim8'
    end

  end
end
