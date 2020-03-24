# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#preview' do
  include Helpers::FileSystem
  include Helpers::Preview
  include Helpers::ReportEditorStateOnError
  include VimlValue::SerializationHelpers
  Context ||= Helpers::Modifiable::Context

  # TODO: extra testing scenarios (currently blocked by editor version)
  #   - file with a name required to be escaped

  describe 'neovim', :neovim do
    # Random #shuffle can be reproduced by specifying --seed N, as Kernel.srand
    # is used in spec_helper
    let(:uglified_names) do
      ['😄', '概', 'ц', 'æ', "a\a", "a\b", "a\t", "a\v", "a\f", "a\r",
       "a\e", '<', '<<', '>>', '(', ')', '[', ']', '{', '}', "'", ';', '&', '~',
       '$', '^', '*', '**', '+', '++', '-', '--', '>', '+a', '++a', '-a', '--a',
       '>a', 'a+', 'a++', 'a-', 'a--', 'a>', '\\', '\\\\', '"', '"a":1:b', 'a ',
       ' a', 'a b', ' 1 a b'].shuffle
    end

    let(:search_string) { 'a' }
    let(:contexts) do
      [Context.new(uglified_names.pop, [search_string] * 10),
       Context.new(uglified_names.pop, [search_string] * 10)]
    end
    let(:files) do
      contexts.map { |c| c.file = file(c.content, c.name) }
    end
    let!(:test_directory) { directory(files).persist! }
    let(:ctx1) { contexts[0] }
    let(:ctx2) { contexts[1] }

    around(Configuration.vimrunner_switch_to_neovim_callback_scope) { |e| use_nvim(&e) }

    shared_context 'start search' do
      before do
        esearch.configure!(regex: 1, backend: 'system', adapter: 'ag', 'out': 'win', root_markers: [])
        esearch.cd! test_directory
        esearch.search!(search_string)
        ctx1.locate!
      end
    end

    after do
      expect(editor.messages).not_to include('Error')
      esearch.cleanup!
    end

    include_context 'report editor state on error'

    shared_context 'verify test file content is not modified after a testcase' do
      after do
        # weird regression bug caused by unknown magic with vim's autocommands
        editor.edit! ctx1.absolute_path
        expect(editor.lines.to_a).to eq(ctx1.content)
      end
    end

    shared_context "open preview and verify it's correctness" do
      before do
        expect { editor.send_keys 'p' }
          .to change { window_handles.count }
          .by(1)
        expect(window_local_highlights[..-2]).to all eq(default_highlight)
        expect(window_local_highlights.last).to eq('Normal:NormalFloat')
      end
    end

    describe 'API' do
      describe 'max_edit_size option' do
        before do
          editor.command! <<~VIML
            call esearch#out#win#map('e', {es-> es.preview({'max_edit_size': 0}) })
          VIML
        end
        include_context 'start search'

        it 'opens a scratch buffer when the size in KB is exceeded' do
          expect { editor.send_keys 'e' }
            .to change { editor.ls }
            .to include('[Scratch]')
        end
      end

      describe 'width and height options' do
        context 'when using real buffer' do
          before do
            editor.command! "call esearch#out#win#map('e', {es-> es.preview({'width': 5, 'height': 10}) })"
          end
          include_context 'start search'
          before { editor.send_keys 'e' }

          it 'opens window with a specified geometry' do
            editor.invalidate_cache!
            expect(window_height(window_handles.last)).to eq(10)
            expect(window_width(window_handles.last)).to eq(5)
          end
        end

        context 'when using scratch buffer' do
          before do
            editor.command! <<~VIML
              call esearch#out#win#map('e', {es-> es.preview({'width': 5, 'height': 10, 'max_edit_size': 0}) })
            VIML
          end
          include_context 'start search'
          before do
            expect { editor.send_keys 'e' }
              .to change { editor.ls }
              .to include('[Scratch]')
          end

          it 'opens window with a specified geometry' do
            expect(window_height(window_handles.last)).to eq(10)
            expect(window_width(window_handles.last)).to eq(5)
          end
        end
      end
    end

    describe 'swapfiles' do
      let(:swap_file) { file('swap_content', swap_path(ctx1.file.path)) }
      let(:files) do
        contexts.first(1).map { |c| c.file = file(c.content, c.name) }
      end

      before do
        editor.command <<~VIML
          set swapfile directory=#{test_directory} updatecount=1
          set updatecount=1
        VIML
        test_directory.files << swap_file
        test_directory.persist!
      end
      include_context 'start search'
      after do
        expect(window_local_highlights).to all eq(default_highlight)
        swap_file.unlink
        editor.command <<~VIML
          set noswapfile
          set updatecount=0
        VIML
      end

      it 'handles buffer opened staying in the current window' do
        expect { editor.send_keys 'p' }
          .to change { window_handles.count }
          .by(1)
          .and not_to_change { editor.current_buffer_name }

        expect { editor.raw_send_keys('S', 'e') }
          .to not_change { window_handles.count }
          .and not_to_change { editor.current_buffer_name }
      end

      # regression bug caused by raising error on nvim_open_win after
      # specifying a buffer with existing swap that was already opened
      it 'handles previously opened buffer' do
        2.times do
          expect { editor.send_keys 'p' }
            .to change { window_handles.count }
            .by(1)
            .and not_to_change { editor.current_buffer_name }

          # split and press (A)bort
          expect { editor.raw_send_keys('s', 'a') }
            .to change { window_handles.count }
            .by(-1)
            .and not_to_change { editor.current_buffer_name }
        end
      end
    end

    describe 'closing on cursor moved' do
      include_context 'start search'
      include_context "open preview and verify it's correctness"

      it 'closes window on regular movement' do
        expect { editor.send_keys 'hjkl' }
          .to change { window_handles.count }
          .by(-1)
        expect(window_local_highlights).to all eq(default_highlight)
      end
    end

    describe 'handle blank results' do
      let(:search_string) { 'a' }
      let(:contexts) { [Context.new('file2.txt', 'b')] }

      it "doesn't fail on blank results" do
        expect { editor.send_keys 'p' }
          .to not_change { editor.messages }
          .and not_to_change { window_local_highlights }
          .and not_to_change { window_handles }
      end
    end

    describe 'handle opening multiple files' do
      include_context 'start search'

      context 'when opening with stay option' do
        it 'resets options on opening files' do
          expect do
            ctx1.locate!
            editor.send_keys_separately 'p', 'T'
            ctx2.locate!
            editor.send_keys_separately 'p', 'T'
          end
            .to change { window_handles.count }
            .by(2)
            .and not_to_change { window_local_highlights.uniq }
            .from([''])
        end
      end

      context 'when opening without stay option' do
        it 'resets options on opening files' do
          expect do
            ctx1.locate!
            editor.send_keys_separately 'p'
            ctx2.locate!
            editor.send_keys_separately 'p', 's'
          end
            .to change { window_handles.count }
            .by(1)
            .and not_to_change { window_local_highlights.uniq }
            .from([''])
        end
      end
    end

    describe 'closing on opening a file' do
      include_context 'start search'
      include_context "open preview and verify it's correctness"

      context 'when opening with staying in the current window' do
        shared_examples 'open with stayin in the window' do |keys:|
          include_context 'verify test file content is not modified after a testcase'

          it 'closes preview and resets window-local highlights' do
            expect { editor.send_keys keys }
              .to not_change { window_handles.count }
              .and not_to_change { editor.current_buffer_name }
            expect(window_local_highlights).to all eq(default_highlight)
          end
        end

        it_behaves_like 'open with stayin in the window', keys: 'T'
        it_behaves_like 'open with stayin in the window', keys: 'S'
        it_behaves_like 'open with stayin in the window', keys: 'O'
      end

      context 'when opening with jumping to an opened window' do
        shared_examples 'open with jumping to the opened file' do |keys:|
          include_context 'verify test file content is not modified after a testcase'

          it 'closes preview and resets window-local highlights' do
            expect { editor.send_keys keys }
              .to not_change { window_handles.count }
              .and change { editor.current_buffer_name }.to(ctx1.absolute_path.to_s)
            expect(window_local_highlights).to all eq(default_highlight)
          end
        end

        it_behaves_like 'open with jumping to the opened file', keys: 't'
        it_behaves_like 'open with jumping to the opened file', keys: 's'
        it_behaves_like 'open with jumping to the opened file', keys: 'o'
      end

      context 'when opening in the current window' do
        include_context 'verify test file content is not modified after a testcase'

        it 'closes preview and resets window-local highlights' do
          expect { editor.send_keys :enter }
            .to change { window_handles.count }
            .by(-1)
            .and change { editor.current_buffer_name }
            .to(ctx1.absolute_path.to_s)
          expect(window_local_highlights).to all eq(default_highlight)
        end
      end
    end

    describe 'bouncing keypress' do
      include_context 'start search'
      include_context "open preview and verify it's correctness"

      context 'bouncing split with staying in the current window' do
        let(:split_silent) { '\\<Plug>(esearch-win-split-silent)' }

        include_context 'verify test file content is not modified after a testcase'

        # regression bug when the second opened buffer had incorrect
        # winhighlight
        it 'resets window-local highlight for all opened windows' do
          expect { editor.send_keys split_silent, split_silent }
            .to change { window_handles.count }
            .by(1)
            .and not_to_change { editor.current_buffer_name }
          expect(window_local_highlights).to all eq(default_highlight)
        end
      end

      context 'when bouncing opening preview' do
        it 'keeps only a single preview window opened' do
          expect { editor.send_keys 'p', 'p' }
            .to not_change { window_handles.count }
            .and not_to_change { editor.current_buffer_name }
          expect(window_local_highlights[..-2]).to all eq(default_highlight)
          expect(window_local_highlights.last).to eq('Normal:NormalFloat')
        end
      end
    end
  end
end
