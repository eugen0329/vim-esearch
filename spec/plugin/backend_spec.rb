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
    shared_examples 'finds 1 entry of' do |search_string, **kwargs|
      context "when searching for `#{search_string.dump}`" do
        let(:other_files) do
          [file('with.arbitrary.extension', 'random_content'),
           file('empty.txt', ''),]
        end
        let(:expected_file) { file('expected.txt', kwargs.fetch(:in)) }
        let(:search_directory) { directory([expected_file, *other_files]).persist! }
        let(:line)   { kwargs.fetch(:line) }
        let(:column) { kwargs.fetch(:column) }

        it "finds 1 entry inside file containing #{kwargs[:in].dump}" do
          esearch.cd! search_directory
          esearch.search!(search_string)

          expect(esearch)
            .to have_search_started(timeout: 10.seconds)
            .and have_search_finished(timeout: 10.seconds)
            .and have_output_1_result_in_header
        end
      end
    end

    shared_examples 'works with adapter' do |adapter|
      context 'when regex' do
      end

      context 'when literal' do
        before { esearch.configure!(backend: 'system', adapter: adapter, out: 'win', regex: 0) }

        include_context 'finds 1 entry of', '%', in: "_\n__%__", line: 2, column: 3
      end
    end

    it_behaves_like 'works with adapter', 'ag'
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
