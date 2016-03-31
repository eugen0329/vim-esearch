require 'spec_helper'

context 'esearch' do
  context '#backend' do
    describe '#vimproc' do
      it_behaves_like 'a backend', 'vimproc', ['<', '>', '"', "'"]
      include_context 'dumpable'
    end
  end
end
