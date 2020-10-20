# frozen_string_literal: true

require 'spec_helper'
require 'plugin/shared_examples/abortable_backend'

describe 'esearch#backend', :backend do
  include Helpers::FileSystem
  include Helpers::Strings
  include Helpers::Output
  include Helpers::ReportEditorStateOnError
  include VimlValue::SerializationHelpers

  before { esearch.configure(root_markers: [], adapters: {grep: {options: '--exclude-dir=.git'}}) }

  shared_examples 'finds 1 entry of' do |search_string, **kwargs|
    context "when searching for #{dump(search_string)}" do
      let(:other_files) do
        kwargs.fetch(:other_files) do
          [file('___', 'binary.bin', binary: true), file('', 'empty.txt')]
        end
      end
      let(:expected_file) { file(kwargs.fetch(:in), 'expected.txt') }
      let(:expected_path) { expected_file.relative_path }
      let(:test_directory) { directory([expected_file, *other_files]).persist! }
      let(:line)   { kwargs.fetch(:line) }
      let(:column) { kwargs.fetch(:column) }

      before do
        esearch.configuration.submit!
        esearch.cd! test_directory
      end
      append_after { esearch.cleanup! }

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
            .and have_search_highlight(expected_path, line, column)
            .and have_outputted_result_from_file_in_line(expected_path, line)
            .and have_outputted_result_with_right_position_inside_file(expected_path, line, column.begin)
        end
      end
    end
  end

  shared_examples 'works with adapter' do |adapter|
    context "works with adapter: #{adapter}", adapter.to_sym, adapter: adapter.to_sym do
      let(:adapter) { adapter }

      before { esearch.configure(adapter: adapter, regex: 0) }

      context 'when weird search strings' do
        context 'when matching regexp', :regexp, matching: :regexp do
          before do
            esearch.configure(adapter: adapter, regex: (adapter =~ /grep|git/ ? 'extended' : 1))
          end

          include_context 'finds 1 entry of', /345/,   in: "\n__345", line: 2, column: 3..6
          include_context 'finds 1 entry of', /3\d+5/, in: "\n__345", line: 2, column: 3..6
          include_context 'finds 1 entry of', /3\d*5/, in: '__345',   line: 1, column: 3..6
          include_context 'finds 1 entry of', /5$/,    in: "\n__5_5", line: 2, column: 5..6
          include_context 'finds 1 entry of', /^5/,    in: "_5_\n5_", line: 2, column: 1..2
        end

        context 'when matching literal', :literal do
          before { esearch.configure(adapter: adapter, regex: 0) }
          # potential errors with escaping
          include_context 'finds 1 entry of', '%',      in: "_\n__%__",   line: 2, column: 3..4
          include_context 'finds 1 entry of', '#',      in: "_\n__#__",   line: 2, column: 3..4
          include_context 'finds 1 entry of', '!',      in: "_\n__!__",   line: 2, column: 3..4
          # TODO
          # include_context 'finds 1 entry of', '%{',     in: "_\n__%{__",  line: 2, column: 3..4
          include_context 'finds 1 entry of', '<',      in: "_\n__<_",    line: 2, column: 3..4
          include_context 'finds 1 entry of', '>',      in: "_\n__>_",    line: 2, column: 3..4
          include_context 'finds 1 entry of', '2 > 1',  in: "_\n_2 > 1_", line: 2, column: 2..7
          include_context 'finds 1 entry of', '2 < 1',  in: "_\n_2 < 1_", line: 2, column: 2..7
          include_context 'finds 1 entry of', '2 >> 1', in: "_\n2 >> 1_", line: 2, column: 1..7
          include_context 'finds 1 entry of', '2 << 1', in: "_\n2 << 1_", line: 2, column: 1..7
          include_context 'finds 1 entry of', '"',      in: "_\n__\"_",   line: 2, column: 3..4
          include_context 'finds 1 entry of', '\'',     in: "_\n__\'_",   line: 2, column: 3..4
          include_context 'finds 1 entry of', '(',      in: "_\n__(_",    line: 2, column: 3..4
          include_context 'finds 1 entry of', ')',      in: "_\n__)_",    line: 2, column: 3..4
          include_context 'finds 1 entry of', '[',      in: "_\n__[_",    line: 2, column: 3..4
          include_context 'finds 1 entry of', ']',      in: "_\n__]_",    line: 2, column: 3..4
          include_context 'finds 1 entry of', '{',      in: "_\n__{_",    line: 2, column: 3..4
          include_context 'finds 1 entry of', '}',      in: "_\n__}_",    line: 2, column: 3..4
          include_context 'finds 1 entry of', '\\',     in: "_\n__\\_",   line: 2, column: 3..4
          include_context 'finds 1 entry of', '\\\\',   in: "_\n_\\\\_",  line: 2, column: 2..4
          include_context 'finds 1 entry of', '//',     in: "_\n__//_",   line: 2, column: 3..5
          include_context 'finds 1 entry of', '\/',     in: "_\n__\\/_",  line: 2, column: 3..5
          include_context 'finds 1 entry of', '$',      in: "_\n__$_",    line: 2, column: 3..4
          include_context 'finds 1 entry of', '^',      in: "_\n__^_",    line: 2, column: 3..4
          include_context 'finds 1 entry of', ';',      in: "_\n__;_",    line: 2, column: 3..4
          include_context 'finds 1 entry of', '&',      in: "_\n__&_",    line: 2, column: 3..4
          include_context 'finds 1 entry of', '~',      in: "_\n__~_",    line: 2, column: 3..4
          include_context 'finds 1 entry of', '==',     in: "_\n__==_",   line: 2, column: 3..5
          # invalid as regexps, but valid for literal match
          include_context 'finds 1 entry of', '-',      in: "_\n__-_",    line: 2, column: 3..4
          include_context 'finds 1 entry of', '+',      in: "_\n__+_",    line: 2, column: 3..4
          include_context 'finds 1 entry of', '++',     in: "_\n__++_",   line: 2, column: 3..5
          include_context 'finds 1 entry of', '**',     in: "_\n__**_",   line: 2, column: 3..5
        end
      end
    end
  end

  shared_examples 'a backend' do |backend|
    context "works with backend: #{backend}", backend.to_sym, backend: backend.to_sym do
      let(:backend) { backend }

      before { esearch.configure(backend: backend, last_id: 0) }

      describe '#out#win' do
        before { esearch.configure(out: 'win') }

        include_context 'works with adapter', 'ag'
        include_context 'works with adapter', 'ack'
        include_context 'works with adapter', 'git'
        include_context 'works with adapter', 'grep'
        include_context 'works with adapter', 'pt'
        include_context 'works with adapter', 'rg'
      end
    end
  end

  describe '#system', :system do
    before { esearch.configure(win_render_strategy: 'viml', parse_strategy: 'viml') }

    it_behaves_like 'a backend', 'system'
  end

  describe '#vim8', :vim8 do
    it_behaves_like 'an abortable backend', 'vim8'

    context 'when rendering with lua', render: :lua do
      before { esearch.configure(win_render_strategy: 'lua', parse_strategy: 'lua') }

      it_behaves_like 'a backend', 'vim8'
    end

    context 'when rendering with viml', render: :viml do
      before { esearch.configure(win_render_strategy: 'viml', parse_strategy: 'viml') }

      it_behaves_like 'a backend', 'vim8'
    end
  end
end
