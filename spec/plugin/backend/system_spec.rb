require 'spec_helper'

# TODO consider merge adapters in adapters_spec.rb
context 'esearch' do
  context '#backend' do
    describe '#system' do
      after :each do |example|
        cmd('close!') if bufname("%") =~ /Search/
      end

      ['grep'].each do |adapter|
        it_behaves_like 'a backend', 'system', adapter, ['<', '>', '"', "'", '(', ')', '(', '[', ']', '\'', '$', '^']
      end
      include_context 'dumpable'
    end
  end
end



