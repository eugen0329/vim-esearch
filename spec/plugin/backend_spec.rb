# frozen_string_literal: true

require 'spec_helper'
require 'plugin/shared_examples/backend.rb'
require 'plugin/shared_examples/abortable_backend.rb'
require 'plugin/shared_contexts/dumpable.rb'


def search_string_dump(search_string)
  if search_string.is_a? Regexp
    search_string.inspect
  elsif search_string.is_a? String
    search_string.dump
  else
    search_string.to_s
  end
end

def search_string_to_s(search_string)
  return search_string.inspect[1..-2] if search_string.is_a? Regexp

  search_string.to_s
end

describe 'esearch#backend', :backend do
  shared_examples 'finds 1 entry of' do |search_string, **kwargs|
    context "when searching for #{search_string_dump(search_string)}" do
      let(:other_files) do
        [file('with.arbitrary.extension', 'random_content'),
         file('empty.txt', ''),]
      end
      let(:expected_file) { file('expected.txt', kwargs.fetch(:in)) }
      let(:search_directory) { directory([expected_file, *other_files]).persist! }
      let(:line)   { kwargs.fetch(:line) }
      let(:column) { kwargs.fetch(:column)  && nil }

      before { esearch.cd! search_directory }

      it "finds 1 entry inside file containing #{kwargs[:in].dump}" do |e|
        esearch.search!(search_string_to_s(search_string))

        expect(esearch)
          .to  have_search_started(timeout: 2.seconds)
          .and have_search_finished(timeout: 2.seconds)
          .and have_reported_single_result_in_header
          .and have_outputted_result_in_file(expected_file.relative_path, line, column)
      end
    end
  end

  shared_examples 'works with adapter' do |adapter|
    context "works with adapter: #{adapter}", adapter.to_sym do
      context 'when weird search strings' do
        xcontext 'when matching regexp', :regexp do
          include_context 'finds 1 entry of', /123/,   in: "\n__123", line: 2, column: 3
          include_context 'finds 1 entry of', /\d+/,   in: "\n__123", line: 2, column: 3
          include_context 'finds 1 entry of', /\d{2}/, in: "\n_12_",  line: 2, column: 2 do
            let(:other_files) do
              [file('1.txt', "1\n2_3\n4"),
               file('2.txt', "a\n\nbb\nccc"),]
            end
          end
          include_context 'finds 1 entry of', /\d{2}/, in: "\n_12_", line: 2, column: 2 do
            let(:other_files) do
              [file('1.txt', "1\n2_3\n4"),
               file('2.txt', "a\n\nbb\nccc"),]
            end
          end
          include_context 'finds 1 entry of', /(?<=the)cat/, in: "\nthecat", line: 2, column: 4 do
            let(:other_files) do
              [file('1.txt', "\n___cat"),
               file('2.txt', "\n_hecat"),]
            end
          end
        end

        context 'when matching literal', :literal do
          before { esearch.configure!(adapter: adapter, regex: 0) }

          # potential errors with escaping
          include_context 'finds 1 entry of', '%',      in: "_\n__%__",   line: 2, column: 3
          include_context 'finds 1 entry of', '<',      in: "_\n__<_",    line: 2, column: 3
          include_context 'finds 1 entry of', '>',      in: "_\n__>_",    line: 2, column: 3
          include_context 'finds 1 entry of', '2 > 1',  in: "_\n_2 > 1_", line: 2, column: 2
          include_context 'finds 1 entry of', '2 < 1',  in: "_\n_2 < 1_", line: 2, column: 2
          include_context 'finds 1 entry of', '2 >> 1', in: "_\n2 >> 1_", line: 2, column: 1
          include_context 'finds 1 entry of', '2 << 1', in: "_\n2 << 1_", line: 2, column: 1
          include_context 'finds 1 entry of', '"',      in: "_\n__\"_",   line: 2, column: 3
          include_context 'finds 1 entry of', '\'',     in: "_\n__\'_",   line: 2, column: 3
          include_context 'finds 1 entry of', '(',      in: "_\n__(_",    line: 2, column: 3
          include_context 'finds 1 entry of', ')',      in: "_\n__)_",    line: 2, column: 3
          include_context 'finds 1 entry of', '(',      in: "_\n__(_",    line: 2, column: 3
          include_context 'finds 1 entry of', '[',      in: "_\n__[_",    line: 2, column: 3
          include_context 'finds 1 entry of', ']',      in: "_\n__]_",    line: 2, column: 3
          include_context 'finds 1 entry of', '\\',     in: "_\n__\\_",   line: 2, column: 3
          include_context 'finds 1 entry of', '$',      in: "_\n__$_",    line: 2, column: 3
          include_context 'finds 1 entry of', '//',     in: "_\n__//_",   line: 2, column: 3
          include_context 'finds 1 entry of', '\\\\',   in: "_\n_\\\\_",  line: 2, column: 2
          include_context 'finds 1 entry of', '\/',     in: "_\n__\\/_",  line: 2, column: 3
          include_context 'finds 1 entry of', '^',      in: "_\n__^_",    line: 2, column: 3
          include_context 'finds 1 entry of', ';',      in: "_\n__;_",    line: 2, column: 3
          include_context 'finds 1 entry of', '&',      in: "_\n__&_",    line: 2, column: 3
          include_context 'finds 1 entry of', '~',      in: "_\n__~_",    line: 2, column: 3
          # invalid as regexps, but valid for literal match
          include_context 'finds 1 entry of', '++',     in: "_\n__++_",   line: 2, column: 3
          include_context 'finds 1 entry of', '**',     in: "_\n__**_",   line: 2, column: 3
          include_context 'finds 1 entry of', '==',     in: "_\n__==_",   line: 2, column: 3
          include_context 'finds 1 entry of', '{',      in: "_\n__{_",    line: 2, column: 3
          include_context 'finds 1 entry of', '}',      in: "_\n__}_",    line: 2, column: 3
        end
      end
    end
  end

  shared_examples 'a backend 2' do |backend|
    before { esearch.configure!(backend: backend) }

    context 'when #out#win' do
      before { esearch.configure!(out: 'win') }

      include_context 'works with adapter', 'ag'
      include_context 'works with adapter', 'ack'
      # include_context 'works with adapter', 'git'
      include_context 'works with adapter', 'grep'
      include_context 'works with adapter', 'pt'
      include_context 'works with adapter', 'rg'
    end
  end

  describe '#system', :system do
    it_behaves_like 'a backend 2', 'system'
  end

  xdescribe '#vimproc', :vimproc do
    before(:all) do
      press ':let g:esearch#backend#vimproc#updatetime = 30'
      press ':let g:esearch#backend#vimproc#read_timeout = 30'
    end

    it_behaves_like 'a backend', 'vimproc'
    it_behaves_like 'an abortable backend', 'vimproc'
  end

  xdescribe '#nvim', :nvim do
    around(:all) { |e| use_nvim(&e) }

    it_behaves_like 'a backend', 'nvim'
    it_behaves_like 'an abortable backend', 'nvim'
  end

  xdescribe '#vim8', :vim8 do
    before { press ':let g:esearch#backend#vim8#timer = 100<Enter>' }

    it_behaves_like 'a backend', 'vim8'
    it_behaves_like 'an abortable backend', 'vim8'
  end
end
