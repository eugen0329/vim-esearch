# frozen_string_literal: true

require 'spec_helper'
require 'plugin/shared_examples/backend.rb'
require 'plugin/shared_examples/abortable_backend.rb'
require 'plugin/shared_contexts/dumpable.rb'

describe 'esearch#backend', :backend do
  describe '#system', :system do
    it_behaves_like 'a backend', 'system'
  end

  describe '#vimproc', :vimproc do
    before(:all) do
      press ':let g:esearch#backend#vimproc#updatetime = 30'
      press ':let g:esearch#backend#vimproc#read_timeout = 30'
    end

    it_behaves_like 'a backend', 'vimproc'
    it_behaves_like 'an abortable backend', 'vimproc'
  end

  context 'draft' do
    search_string = '**'

    let(:other_files) do
      [file('with.arbitrary.extension', 'random_content'),
       file('empty_file.txt', ''),]
    end
    let(:expected_file) { file('expected.txt', search_string) }
    let!(:search_directory) { directory([expected_file, *other_files]).persist! }

    around do |example|
      esearch.configure!(backend: 'system', adapter: 'ag', out: 'win', regex: 0)
      esearch.cd! search_directory.to_s
      example.run
      cmd('close!') if bufname('%') =~ /Search/
    end

    it "finds `#{search_string}`" do
      esearch.search!(search_string)
      wait_for_search_start

      expect(esearch)
        .to have_search_started(timeout: 10.seconds)
        .and have_search_finished(timeout: 10.seconds)
        .and have_output_1_result
    end
  end

  describe '#nvim', :nvim do
    around(:all) { |e| use_nvim(&e) }

    it_behaves_like 'a backend', 'nvim'
    it_behaves_like 'an abortable backend', 'nvim'
  end

  describe '#vim8', :vim8 do
    before { press ':let g:esearch#backend#vim8#timer = 100<Enter>' }

    it_behaves_like 'a backend', 'vim8'
    it_behaves_like 'an abortable backend', 'vim8'
  end
end
