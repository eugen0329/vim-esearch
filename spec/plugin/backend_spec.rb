# frozen_string_literal: true

require 'spec_helper'
require 'plugin/shared_examples/backend'
require 'plugin/shared_examples/abortable_backend'

describe 'esearch#backend', :backend do
  include Helpers::FileSystem
  include Helpers::Strings
  include Helpers::OutputErrors
  include Helpers::ReportEditorStateOnError

  shared_examples 'finds 1 entry of' do |search_string, **kwargs|
    context "when searching for #{dump(search_string)}" do
      let(:other_files) do
        kwargs.fetch(:other_files) do
          [file('___', 'binary.bin', binary: true), file('', 'empty.txt')]
        end
      end
      let(:expected_file) { file(kwargs.fetch(:in), 'expected.txt') }
      let(:expected_path) { expected_file.relative_path }
      let(:search_directory) { directory([expected_file, *other_files]).persist! }
      let(:line)   { kwargs.fetch(:line) }
      let(:column) { kwargs.fetch(:column) }

      before do
        esearch.configuration.submit!
        esearch.cd! search_directory
      end

      append_after do
        if Configuration.debug_specs_performance? && backend == 'system'
          expect(VimrunnerSpy.echo_call_history.count).to be < 7
        end
        esearch.cleanup!
      end

      include_context 'report editor state on error'

      it "finds 1 entry of #{dump(search_string)} inside a file containing #{dump(kwargs[:in])}" do
        esearch.search!(to_search(search_string))

        KnownIssues.mark_example_pending_if_known_issue(self) do
          expect(esearch).to have_search_started

          expect(esearch)
            .to  have_search_finished
            .and have_not_reported_errors

          expect(esearch)
            .to  have_reported_a_single_result
            .and have_search_highlight(line, column)
            .and have_outputted_result_from_file_in_line(expected_path, line)
            .and have_outputted_result_with_right_position_inside_file(expected_path, line, column)
        end
      end
    end
  end

  shared_examples 'works with adapter' do |adapter, adapter_bin|
    context "works with adapter: #{adapter}", adapter.to_sym, adapter: adapter.to_sym do
      let(:adapter) { adapter }

      before do
        esearch.configure(adapter: adapter, regex: 1)

        esearch.configuration.adapter_bin = adapter_bin if adapter_bin
      end

      context 'when weird search strings' do
        context 'when matching regexp', :regexp, matching: :regexp do
          include_context 'finds 1 entry of', /345/,   in: "\n__345", line: 2, column: 3
          include_context 'finds 1 entry of', /3\d+5/, in: "\n__345", line: 2, column: 3
          include_context 'finds 1 entry of', /3\d*5/, in: '__345',   line: 1, column: 3
          include_context 'finds 1 entry of', /5$/,    in: "\n__5_5", line: 2, column: 5

          # are required mostly to choose the best commandline options for adapters
          context 'compatibility with syntax', :compatibility_regexps do
            include_context 'finds 1 entry of', /[[:digit:]]{2}/, in: "\n__12_", line: 2, column: 3, other_files: [
              file("1\n2_3\n4",    '1.txt'),
              file("a\n\nbb\nccc", '2.txt')
            ]
            include_context 'finds 1 entry of', /a{2}/, in: "a\n__aa_a_", line: 2, column: 3
            include_context 'finds 1 entry of', /\d{2}/, in: "\n__12_", line: 2, column: 3, other_files: [
              file("1\n2_3\n4",    '1.txt'),
              file("a\n\nbb\nccc", '2.txt')
            ]
            include_context 'finds 1 entry of', /(?<=the)cat/, in: "\nthecat", line: 2, column: 4, other_files: [
              file("\n___cat", '1.txt'),
              file("\n_hecat", '2.txt')
            ]
            include_context 'finds 1 entry of', /(?<name>\d)+5/, in: "\n__345", line: 2, column: 3
            include_context 'finds 1 entry of', '(?P<name>\d)+5', in: "\n__345", line: 2, column: 3
            include_context 'finds 1 entry of', /(?:\d)+34/, in: "\n__345", line: 2, column: 3
          end
        end

        context 'when matching literal', :literal do
          before { esearch.configure(adapter: adapter, regex: 0) }
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
          include_context 'finds 1 entry of', '==',     in: "_\n__==_",   line: 2, column: 3
          include_context 'finds 1 entry of', '{',      in: "_\n__{_",    line: 2, column: 3
          include_context 'finds 1 entry of', '}',      in: "_\n__}_",    line: 2, column: 3
          # invalid as regexps, but valid for literal match
          include_context 'finds 1 entry of', '++',     in: "_\n__++_",   line: 2, column: 3
          include_context 'finds 1 entry of', '**',     in: "_\n__**_",   line: 2, column: 3
        end
      end
    end
  end

  shared_examples 'a backend 2' do |backend|
    context "works with backend: #{backend}", backend.to_sym, backend: backend.to_sym do
      let(:backend) { backend }

      before { esearch.configure(backend: backend) }

      describe '#out#win' do
        before { esearch.configure(out: 'win') }

        include_context 'works with adapter', 'ag'
        include_context 'works with adapter', 'ack'
        include_context 'works with adapter', 'git'
        include_context 'works with adapter', 'grep'
        include_context 'works with adapter', 'pt', Configuration.pt_path
        include_context 'works with adapter', 'rg', Configuration.rg_path
      end
    end
  end

  describe '#system', :system do
    include_context 'a backend',   'system'
    include_context 'a backend 2', 'system'
  end

  describe '#vimproc', :vimproc, backend: :vimproc do
    before(:all) do
      esearch.editor.press! ':let g:esearch#backend#vimproc#updatetime = 30'
      esearch.editor.press! ':let g:esearch#backend#vimproc#read_timeout = 30'
    end

    include_context 'a backend', 'vimproc'
    include_context 'a backend 2', 'vimproc'
    it_behaves_like 'an abortable backend', 'vimproc'
  end

  describe '#nvim', :nvim do
    around(Configuration.vimrunner_switch_to_neovim_callback_scope) { |e| use_nvim(&e) }

    # TODO
    before(:each) do
      esearch.editor.press! ':let g:esearch#util#unicode_enabled = 0<Enter>'
    end

    include_context 'a backend', 'nvim'
    include_context 'a backend 2', 'nvim'
    it_behaves_like 'an abortable backend', 'nvim'
  end

  describe '#vim8', :vim8 do
    before { esearch.editor.press! ':let g:esearch#backend#vim8#timer = 100<Enter>' }

    include_context 'a backend', 'vim8'
    include_context 'a backend 2', 'vim8'
    it_behaves_like 'an abortable backend', 'vim8'
  end
end
