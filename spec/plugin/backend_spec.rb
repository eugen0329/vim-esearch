# frozen_string_literal: true

require 'spec_helper'
require 'plugin/shared_examples/backend'
require 'plugin/shared_examples/abortable_backend'

describe 'esearch#backend', :backend do
  include Helpers::FileSystem
  include Helpers::Strings
  include Helpers::Output
  include Helpers::ReportEditorStateOnError

  before  { esearch.configure(root_markers: []) }

  # to test paths: thorough filename verification, superficial entry check
  shared_examples 'searches in path' do |path:|
    context "when searching in a file with name #{path.inspect}" do
      let(:search_string) { '1' } # the search_string is secondary for the examples group
      let(:line) { 2 }
      let(:column) { 3..4 }
      let(:expected_file) { file("_\n__#{search_string}_", path) }
      let(:test_directory) { directory([expected_file]).persist! }
      let(:escaped_path) { editor.escape_filename(path) }

      before do
        esearch.configuration.submit!
        esearch.cd! test_directory
      end
      append_after { esearch.cleanup! }

      include_context 'report editor state on error'

      it "outputs 1 entry from the file named #{path.inspect}" do
        esearch.search!(search_string)

        KnownIssues.mark_example_pending_if_known_issue(self) do
          expect(esearch)
            .to  have_search_started
            .and have_search_finished
            .and have_not_reported_errors
            .and have_search_highlight(escaped_path, line, column)
            .and have_filename_highlight(escaped_path)
            .and have_outputted_result_from_file_in_line(escaped_path, line)
            .and have_outputted_result_with_right_position_inside_file(escaped_path, line, column.begin)
        end
      end
    end
  end

  # to test search string: thorough entry verification, superficial filename check
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

      append_after do
        # TODO: fix perormance and uncomment
        # if Configuration.debug_specs_performance? && backend == 'system'
        #   expect(VimrunnerSpy.echo_call_history.count).to be < 7
        # end
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
            .and have_search_highlight(expected_path, line, column)
            .and have_outputted_result_from_file_in_line(expected_path, line)
            .and have_outputted_result_with_right_position_inside_file(expected_path, line, column.begin)
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

      context 'when weird path' do
        context 'when filenames contain adapter output separators' do
          context "when dirname doesn't contain basename" do
            context 'when ASCII' do
              context 'when basename contains a separator' do
                include_context 'searches in path', path: 'a:b'
                include_context 'searches in path', path: 'a-b'
              end

              context 'when basename is similar to {filename}{SEP}{line}' do
                include_context 'searches in path', path: 'a:1'
                include_context 'searches in path', path: 'a:1:'
                include_context 'searches in path', path: 'a:1-'
              end

              context 'when basename is similar to {filename}{SEP}{line}{SEP}{text}' do
                include_context 'searches in path', path: 'a:1:2'
                include_context 'searches in path', path: 'a:1-2'
                include_context 'searches in path', path: 'a:1:2:'
                include_context 'searches in path', path: 'a:1-2:'
                include_context 'searches in path', path: 'a:1:2-'
                include_context 'searches in path', path: 'a:1-2-'
              end
            end

            context 'when multibyte' do
              context 'when filename with arbitrary chars' do
                include_context 'searches in path', path: '😄'
                include_context 'searches in path', path: '概'
                include_context 'searches in path', path: 'ц'
                include_context 'searches in path', path: 'æ'
              end

              context 'when basename is similar to {filename}{SEP}{line}{SEP}{text}' do
                include_context 'searches in path', path: 'Σ:1:2:'
                include_context 'searches in path', path: 'Σ:1-2:'
                include_context 'searches in path', path: 'Σ:1:2-'
                include_context 'searches in path', path: 'Σ:1-2-'
              end
            end
          end

          context 'when dirname contains a filename' do
            context 'when ASCII' do
              include_context 'searches in path', path: 'a:b:1/a:b'
              include_context 'searches in path', path: 'a:b-1/a-b'
              include_context 'searches in path', path: 'a:1:b/a:1'
              include_context 'searches in path', path: 'a-1:b/a-1'
            end

            context 'when multibyte' do
              include_context 'searches in path', path: 'Σ:1:b/Σ:1'
            end
          end
        end

        context 'when filenames contain control chars' do
          context 'when ASCII' do
            # \0 isn't accepted by any FS
            include_context 'searches in path', path: "a\a"
            include_context 'searches in path', path: "a\b"
            include_context 'searches in path', path: "a\t"
            include_context 'searches in path', path: "a\n"
            include_context 'searches in path', path: "a\v"
            include_context 'searches in path', path: "a\f"
            include_context 'searches in path', path: "a\r"
            include_context 'searches in path', path: "a\e"
          end

          context 'when UTF-8' do
            include_context 'searches in path', path: ("\u{0080}".."\u{009F}").to_a.sample

            context 'when lang tags' do
              include_context 'searches in path',
                path: ["\u{E0065}", "\u{E006E}", "\u{E002D}", "\u{E0075}", "\u{E0073}"].sample
            end

            context 'when interlinear annotation' do
              include_context 'searches in path',
                path: ["\u{FFF9}", "\u{FFFA}", "\u{FFFB}"].sample
            end
          end
        end

        context 'when filenames contain whitespaces' do
          include_context 'searches in path', path: 'a '
          include_context 'searches in path', path: ' a'
          include_context 'searches in path', path: 'a b'
          include_context 'searches in path', path: ' 1 a b'
        end

        context 'when filenames contain any special characters' do
          context 'when special for a shell' do
            context 'when special regardless the position' do
              include_context 'searches in path', path: '<'
              include_context 'searches in path', path: '<<'
              include_context 'searches in path', path: '>>'
              include_context 'searches in path', path: '('  # globbing
              include_context 'searches in path', path: ')'  # globbing
              include_context 'searches in path', path: '['  # globbing
              include_context 'searches in path', path: ']'  # globbing
              include_context 'searches in path', path: '{'  # ex: git add package{,-lock}.json
              include_context 'searches in path', path: '}'
              include_context 'searches in path', path: "'"
              include_context 'searches in path', path: ';'
              include_context 'searches in path', path: '&'
              include_context 'searches in path', path: '~'
              include_context 'searches in path', path: '$'  # deref
              include_context 'searches in path', path: '^'
              include_context 'searches in path', path: '*'  # globbing
              include_context 'searches in path', path: '**' # globbing
            end

            context 'when special in the beginning of a line' do
              # See :h fnameescape for details
              include_context 'searches in path', path: '+'   # disabling features with shopt
              include_context 'searches in path', path: '++'  # disabling features with shopt
              include_context 'searches in path', path: '-'   # ex: cd -, git checkout -
              include_context 'searches in path', path: '--'  # end of options
              include_context 'searches in path', path: '>'
              include_context 'searches in path', path: '+a'  # ex: shopt +o extglob
              include_context 'searches in path', path: '++a'
              include_context 'searches in path', path: '-a'
              include_context 'searches in path', path: '--a'
              include_context 'searches in path', path: '>a'
              include_context 'searches in path', path: 'a+'
              include_context 'searches in path', path: 'a++'
              include_context 'searches in path', path: 'a-'
              include_context 'searches in path', path: 'a--'
              include_context 'searches in path', path: 'a>'
            end

            # git-grep and likely some other utils do this
            context 'when special withing double quotes' do
              include_context 'searches in path', path: '\\'
              include_context 'searches in path', path: '\\\\'
              include_context 'searches in path', path: '"'
              include_context 'searches in path', path: '"a":1:b'
            end
          end

          context 'when special for vim' do
            include_context 'searches in path', path: '%'
            include_context 'searches in path', path: '<cfile>'
            include_context 'searches in path', path: '='
          end
        end
      end

      context 'when weird search strings' do
        context 'when matching regexp', :regexp, matching: :regexp do
          include_context 'finds 1 entry of', /345/,   in: "\n__345", line: 2, column: 3..6
          include_context 'finds 1 entry of', /3\d+5/, in: "\n__345", line: 2, column: 3..6
          include_context 'finds 1 entry of', /3\d*5/, in: '__345',   line: 1, column: 3..6
          include_context 'finds 1 entry of', /5$/,    in: "\n__5_5", line: 2, column: 5..6
          include_context 'finds 1 entry of', /^5/,    in: "_5_\n5_", line: 2, column: 1..2

          # are required mostly to choose the best commandline options for adapters
          context 'compatibility with syntax', :compatibility_regexps do
            include_context 'finds 1 entry of', /[[:digit:]]{2}/, in: "\n__12_", line: 2, column: 3..5, other_files: [
              file("1\n2_3\n4",    '1.txt'),
              file("a\n\nbb\nccc", '2.txt')
            ]
            include_context 'finds 1 entry of', /a{2}/,  in: "a\n__aa_a_", line: 2, column: 3..5
            include_context 'finds 1 entry of', /\d{2}/, in: "\n__12_",    line: 2, column: 3..5, other_files: [
              file("1\n2_3\n4",    '1.txt'),
              file("a\n\nbb\nccc", '2.txt')
            ]
            include_context 'finds 1 entry of', /(?<=the)cat/, in: "\nthecat", line: 2, column: 4..7, other_files: [
              file("\n___cat", '1.txt'),
              file("\n_hecat", '2.txt')
            ]
            include_context 'finds 1 entry of', /(?<name>\d)+5/,  in: "\n__345", line: 2, column: 3..6
            include_context 'finds 1 entry of', '(?P<name>\d)+5', in: "\n__345", line: 2, column: 3..6
            include_context 'finds 1 entry of', /(?:\d)+34/,      in: "\n__345", line: 2, column: 3..6
          end
        end

        context 'when matching literal', :literal do
          before { esearch.configure(adapter: adapter, regex: 0) }
          # potential errors with escaping
          include_context 'finds 1 entry of', '%',      in: "_\n__%__",   line: 2, column: 3..4
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

  shared_examples 'a backend 2' do |backend|
    context "works with backend: #{backend}", backend.to_sym, backend: backend.to_sym do
      let(:backend) { backend }

      before { esearch.configure(backend: backend, last_id: 0) }

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
    before do
      editor.command <<~VIML
        let g:esearch_out_win_render_using_lua = 0
      VIML
    end

    include_context 'a backend',   'system'
    include_context 'a backend 2', 'system'
  end

  describe '#vimproc', :vimproc, backend: :vimproc do
    before(:context) do
      editor.command <<~VIML
        let g:esearch_out_win_render_using_lua = 0
        let g:esearch#backend#vimproc#updatetime = 30
        let g:esearch#backend#vimproc#read_timeout = 30
        let g:esearch_win_update_using_timer = 0
      VIML
    end
    after(:context) { editor.press! ':let g:esearch_win_update_using_timer = 1<Enter>' }

    include_context 'a backend', 'vimproc'
    include_context 'a backend 2', 'vimproc'
    it_behaves_like 'an abortable backend', 'vimproc'
  end

  describe '#nvim', :neovim do
    around(Configuration.vimrunner_switch_to_neovim_callback_scope) { |e| use_nvim(&e) }

    # TODO
    before(:each) do
      editor.press! ':let g:esearch#has#unicode = 0<Enter>'
    end

    include_context 'a backend', 'nvim'
    include_context 'a backend 2', 'nvim'
    it_behaves_like 'an abortable backend', 'nvim'
  end

  describe '#vim8', :vim8 do
    it_behaves_like 'an abortable backend', 'vim8'

    context 'when rendering with lua', render: :lua do
      before { editor.command 'let g:esearch_out_win_render_using_lua = 1' }

      include_context 'a backend', 'vim8'
      include_context 'a backend 2', 'vim8'
    end

    context 'when rendering with viml', render: :viml do
      context 'when parsing with #legacy', parse: :legacy do
        before do
          editor.command <<~VIML
            let g:esearch_out_win_render_using_lua = 0
          VIML
        end

        include_context 'a backend', 'vim8'
        include_context 'a backend 2', 'vim8'
      end
    end
  end
end
