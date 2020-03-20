# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#preview' do
  include Helpers::FileSystem
  include Helpers::Preview
  include Helpers::ReportEditorStateOnError
  include VimlValue::SerializationHelpers

  # TODO extra testing scenarios (currently blocked by editor version)
  #   - file with a name required to be escaped
  #   - new buffers bloat

  describe 'neovim', :neovim do
    let(:search_string) { 'a' }
    let(:file_content) { search_string * 3 }
    let(:test_file) { file(file_content, 'from.txt') }
    let!(:test_directory) { directory([test_file]).persist! }

    around(Configuration.vimrunner_switch_to_neovim_callback_scope) { |e| use_nvim(&e) }

    before do
      esearch.configure!(regex: 1, backend: 'system', adapter: 'ag', 'out': 'win', root_markers: [])
      esearch.cd! test_directory
      esearch.search!(search_string)
    end

    after do
      expect(editor.messages).not_to include('Error')
      esearch.cleanup!
    end

    include_context 'report editor state on error'

    shared_context 'verify test file content is not modified after a testcase' do
      after do
        # weird regression bug caused by unknown magic with vim's autocommands
        editor.locate_buffer! test_file.path
        expect(editor.lines.to_a).to eq(test_file.lines)
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

    describe 'swapfiles' do
      let!(:swap_file) { file('', swap_path(test_file.path)).persist! }

      before { editor.command 'set updatecount=1' } # start writing swap
      after do
        expect(window_local_highlights).to all eq(default_highlight)
        swap_file.unlink
      end

      it "handles buffer opened staying in the current window" do
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
      it "handles previously opened buffer" do
        2.times do
          expect { editor.send_keys 'p' }
            .to change { window_handles.count }
            .by(1)
            .and not_to_change { editor.current_buffer_name }

          expect { editor.raw_send_keys('s', 'q') }
            .to change { window_handles.count }
            .by(-1)
            .and not_to_change { editor.current_buffer_name }
        end
      end
    end

    describe 'closing on cursor moved' do
      include_context "open preview and verify it's correctness"

      it 'closes window on regular movement' do
        expect { editor.send_keys 'l' }
          .to change { window_handles.count }
          .by(-1)
        expect(window_local_highlights).to all eq(default_highlight)
      end
    end

    describe 'handle blank results' do
      let(:search_string) { 'a' }
      let(:file_content) { 'b' }

      it "doesn't fail on blank results" do
        expect { editor.send_keys 'p' }
          .to not_change { editor.messages }
          .and not_to_change { window_local_highlights }
          .and not_to_change { window_handles }
      end
    end

    describe 'closing on opening a file' do
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
              .and change { editor.current_buffer_name }.to(test_file.path.to_s)
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
            .to(test_file.path.to_s)
          expect(window_local_highlights).to all eq(default_highlight)
        end
      end
    end

    describe 'bouncing keypress' do
      include_context "open preview and verify it's correctness"

      context 'bouncing split with staying in the current window' do
        include_context 'verify test file content is not modified after a testcase'

        # regression bug when the second opened buffer had incorrect
        # winhighlight
        it 'resets window-local highlight for all opened windows' do
          expect { editor.send_keys 'S', 'S' }
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
