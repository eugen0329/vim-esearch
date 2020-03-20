# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#preview' do
  include Helpers::FileSystem
  include Helpers::Preview
  include Helpers::ReportEditorStateOnError
  include VimlValue::SerializationHelpers

  describe 'neovim', :neovim do
    let(:test_file) { file('aaa', 'from.txt') }
    let!(:test_directory) { directory([test_file]).persist! }

    around(Configuration.vimrunner_switch_to_neovim_callback_scope) { |e| use_nvim(&e) }
    before do
      esearch.configure!(regex: 1, backend: 'system', adapter: 'ag', 'out': 'win', root_markers: [])
      esearch.cd! test_directory
      esearch.search!('a')
      expect { editor.send_keys 'p' }
        .to change { window_handles.count }
        .by(1)
      expect(window_local_highlights[..-2]).to all eq(default_highlight)
      expect(window_local_highlights.last).to eq('Normal:NormalFloat')
    end
    after { esearch.cleanup! }

    include_context 'report editor state on error'

    shared_context 'verify test file content is not modified after a testcase' do
      after do
        # weird regression bug caused by unknown magic with vim's autocommands
        editor.locate_buffer! test_file.path
        expect(editor.lines.to_a).to eq(test_file.lines)
      end
    end

    describe 'closing on cursor moved' do
      it 'closes window on regular movement' do
        expect { editor.send_keys 'l' }
          .to change { window_handles.count }
          .by(-1)
        expect(window_local_highlights).to all eq(default_highlight)
      end
    end

    describe 'closing on opening' do
      context 'when opening with staying in the current window' do
        shared_examples 'open with stayin in the window' do |keys:|
          include_context 'verify test file content is not modified after a testcase'

          it 'closes preview and resets window-local highlits' do
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

          it 'closes preview and resets window-local highlits' do
            expect { editor.send_keys key }
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

        it 'closes preview and resets window-local highlits' do
          expect { editor.send_keys :enter }
            .to change { window_handles.count }.by(-1)
                                               .and change { editor.current_buffer_name }
            .to(test_file.path.to_s)
          expect(window_local_highlights).to all eq(default_highlight)
        end
      end
    end

    context 'describe keypress' do
      context 'bouncing split with staying in the current window' do
        include_context 'verify test file content is not modified after a testcase'

        # regression bug when the second opened buffer had incorrect
        # winhighlight
        it 'resets window-local highlight for all opened windows' do
          expect { editor.send_keys 'S', 'S' }
            .to change { window_handles.count }.by(1)
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
