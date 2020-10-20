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

  # to test paths: thorough filename verification, superficial entry check
  shared_examples 'searches in path' do |path:|
    context "when searching in a file with name #{path.inspect}" do
      let(:search_string) { '1' } # the search_string is secondary for the examples group
      let(:line) { 2 }
      let(:column) { 3..4 }
      let(:expected_file) { file("_\n__#{search_string}_", path) }
      let(:test_directory) { directory([expected_file]).persist! }

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
            .and have_search_highlight(path, line, column)
            .and have_filename_highlight(path)
            .and have_outputted_result_from_file_in_line(path, line)
            .and have_outputted_result_with_right_position_inside_file(path, line, column.begin)
        end
      end
    end
  end

  shared_examples 'works with adapter' do |adapter|
    context "works with adapter: #{adapter}", adapter.to_sym, adapter: adapter.to_sym do
      let(:adapter) { adapter }

      before { esearch.configure(adapter: adapter, regex: 0) }

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
            # TODO: lookahead parser
            # include_context 'searches in path', path: "a\n"
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

        context 'when rev-list in paths' do
          before { esearch.configure(paths: '`git rev-list --all`') }

          include_context 'works with adapter', 'git'
        end
      end
    end
  end

  describe '#system', :system do
    before { esearch.configure(win_render_strategy: 'viml', parse_strategy: 'viml') }

    it_behaves_like 'a backend', 'system'
  end

  describe '#vim8', :vim8 do
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
