require 'spec_helper'

context 'esearch' do
  context '#backend' do
    describe '#vimproc' do
      after :each do |example|
        cmd('close!') if bufname("%") =~ /Search/
      end

      ['grep'].each do |adapter|
        it_behaves_like 'a backend', 'vimproc', adapter, ['<', '>', '"', "'", '(', ')', '(', '[', ']', '\'', '$', '^']
      end
      include_context 'dumpable'
    end
  end
end



