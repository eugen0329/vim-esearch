# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#preview' do
  include Helpers::FileSystem
  include Helpers::Preview
  include Helpers::Open
  include Helpers::ReportEditorStateOnError
  include VimlValue::SerializationHelpers
  Context ||= Helpers::Modifiable::Context

  CONFIRM_EDIT_IN_SWAP_PROMPT = 'e'

  # TODO: extra testing scenarios (currently blocked by editor version)
  #   - file with a name required to be escaped

  describe 'neovim', :neovim do
    let(:search_string) { 'n' }
    let(:contexts) do
      [Context.new('a.c', ['int'] * 100),
       Context.new('b.c', ['int'] * 100)]
    end
    let(:files) do
      contexts.map { |c| c.file = file(c.content, c.name) }
    end
    let!(:test_directory) { directory(files).persist! }
    let(:ctx1) { contexts[0] }
    let(:ctx2) { contexts[1] }

    around(Configuration.vimrunner_switch_to_neovim_callback_scope) { |e| use_nvim(&e) }
    after do
      expect(editor.messages).not_to match(/E\d{1,4}:/)
      # tabnew is a workaround to prevent possible bug in neovim/it's client that causes
      # crash on using %bwipeout with a floating window open
      editor.command! 'call esearch#preview#close() | tabnew'
      esearch.cleanup!
    end
    include_context 'report editor state on error'

    shared_context 'start search' do
      before do
        esearch.configure!(regex: 1, backend: 'system', adapter: 'ag', 'out': 'win', root_markers: [])
        esearch.cd! test_directory
        esearch.search!(search_string)
        ctx1.locate!
      end
    end

    shared_context 'verify test files content is not modified after a testcase' do
      after do
        # weird regression bug caused by unknown magic with vim's autocommands
        editor.edit_ignoring_swap!(ctx1.absolute_path)
        expect(editor.lines.to_a).to eq(ctx1.content)
        editor.edit_ignoring_swap!(ctx2.absolute_path)
        expect(editor.lines.to_a).to eq(ctx2.content)
      end
    end

    shared_examples 'it closes the preview stying in the search window' do |keys:|
      it 'closes the preview stying in the buffer' do
        expect { editor.raw_send_keys(*keys) }
          .to close_popup_and_open_window
          .and stay_in_buffer
      end
    end

    shared_examples 'it closes the preview and enters into the buffer' do |keys:|
      it 'closes the preview and switches into the buffer' do
        expect { editor.raw_send_keys(*keys) }
          .to close_popup_and_open_window
          .and start_editing(ctx1.absolute_path)
        expect(editor.lines.to_a).to eq(ctx1.content)
        expect(editor.syntax_under_cursor).not_to be_blank
      end
    end

    shared_context "open preview and verify it's correctness" do
      before do
        expect { editor.send_keys 'p' }
          .to stay_in_buffer
          .and change { windows.count }.by(1)
        expect(window_highlights[..-2]).to all eq(default_highlight)
        expect(window_highlights.last).to eq('Normal:NormalFloat')
      end
    end

    describe 'opening' do
      describe 'regular open' do
        include_context 'start search'

        context 'when a file is opened in a split' do
          let(:changes_count) { (1..2).to_a.sample }
          before do
            editor.edit_ignoring_swap!(ctx1.absolute_path, opener: 'vnew')
            changes_count.times { editor.command! '1,2delete' }
            editor.command! 'wincmd p'
          end

          it "doesn't affect the buffer state" do
            expect { editor.send_keys 'p', 'hjkl', 'p' }
              .to stay_in_buffer
              .and change { windows.count }.by(1)
            editor.command! 'au! esearch_preview_autoclose *'
            editor.echo func('esearch#win#enter', windows.last)
            expect(editor.syntax_under_cursor).not_to be_blank
            expect(editor.changenr).to eq(changes_count)
          end
        end

        context 'when the file is closed' do
          include_context 'verify test files content is not modified after a testcase'

          it 'zooms the preview on double p press' do
            expect { editor.send_keys 'p' }
              .to stay_in_buffer
              .and change { windows.count }.by(1)

            expect { editor.send_keys 'p' }
              .to stay_in_buffer
              .and not_to_change { windows.count }
              .and change { window_height(windows.last) }
              .to be > window_height(windows.last)
          end

          it "doesn't reset the highlights on double open" do
            expect { editor.send_keys 'p', 'hjkl', 'p' }
              .to stay_in_buffer
              .and change { windows.count }.by(1)
            editor.command! 'au! esearch_preview_autoclose *'
            editor.echo func('esearch#win#enter', windows.last)
            expect(editor.syntax_under_cursor).not_to be_blank
          end

          it 'opens the preview of different files' do
            expect {
              ctx1.locate!
              editor.send_keys 'p'
              ctx2.locate!
              editor.send_keys 'p'
            }.to stay_in_buffer
              .and change { windows.count }.by(1)
          end
        end
      end

      describe 'closing' do
        include_context 'start search'
        include_context "open preview and verify it's correctness"
        include_context 'verify test files content is not modified after a testcase'
        after { expect(window_highlights).to all eq(default_highlight) }

        context 'when on moving the cursor' do
          it 'closes the preview' do
            expect { editor.send_keys 'hjkl' }.to close_window(windows.last)
          end
        end

        context 'when on editing' do
          it_behaves_like 'it closes the preview stying in the search window', keys: 'T'
          it_behaves_like 'it closes the preview stying in the search window', keys: 'S'
          it_behaves_like 'it closes the preview stying in the search window', keys: 'O'

          it_behaves_like 'it closes the preview and enters into the buffer', keys: 't'
          it_behaves_like 'it closes the preview and enters into the buffer', keys: 's'
          it_behaves_like 'it closes the preview and enters into the buffer', keys: 'o'

          context 'when reusing the current window' do
            it 'closes preview and resets window-local highlights' do
              expect { editor.send_keys :enter }
                .to close_window(windows.last)
                .and start_editing(ctx1.absolute_path)
            end
          end
        end
      end

      describe 'interaction with [Command Line] window' do
        include_context 'start search'
        include_context "open preview and verify it's correctness"

        context 'when entering the [Command Line] window' do
          it "doesn't inherit the options" do
            expect { editor.raw_send_keys 'q:' }
              .to open_window('[Command Line]')
            expect(current_window_highlight).to be_blank
          end
        end

        context 'when leaving the [Command Line] window' do
          it "doesn't affect the preview options" do
            expect { editor.raw_send_keys 'q:', ":q\n" }
              .to stay_in_buffer
              .and not_to_change { window_highlights }
          end

          it "doesn't affect autoclose events" do
            editor.raw_send_keys 'q:', ":q\n"
            expect { editor.send_keys 'hjkl' }
              .to close_window(windows.last)
          end
        end
      end

      describe 'handling swapfiles' do
        let(:ctx1_swap) { swap_file('swap_content', ctx1.file) }
        let(:ctx2_swap) { swap_file('swap_content', ctx2.file) }
        before do
          test_directory.files << ctx1_swap
          test_directory.files << ctx2_swap
          test_directory.persist!
        end

        include_context 'enable swaps'
        include_context 'start search'
        include_context "open preview and verify it's correctness"
        include_context 'verify test files content is not modified after a testcase'

        it 'previews in a scratch buffer' do
          expect(editor.ls).to include('[Scratch]')
        end

        it_behaves_like 'it closes the preview stying in the search window', keys: ['T', CONFIRM_EDIT_IN_SWAP_PROMPT]
        it_behaves_like 'it closes the preview stying in the search window', keys: ['S', CONFIRM_EDIT_IN_SWAP_PROMPT]
        it_behaves_like 'it closes the preview stying in the search window', keys: ['O', CONFIRM_EDIT_IN_SWAP_PROMPT]

        it_behaves_like 'it closes the preview and enters into the buffer', keys: ['t', CONFIRM_EDIT_IN_SWAP_PROMPT]
        it_behaves_like 'it closes the preview and enters into the buffer', keys: ['s', CONFIRM_EDIT_IN_SWAP_PROMPT]
        it_behaves_like 'it closes the preview and enters into the buffer', keys: ['o', CONFIRM_EDIT_IN_SWAP_PROMPT]
      end
    end

    describe 'entering' do
      shared_examples 'it enters the preview without confirmation' do
        context 'when the preview is opened' do
          it 'reuses the minimal height' do
            editor.send_keys_separately 'p'

            expect { editor.send_keys 'P' }
              .to not_change { windows.count }
              .and start_editing(ctx1.absolute_path)
              .and not_to_change { window_height(windows.last) }
          end

          it 'reuses zoomed height' do
            editor.send_keys_separately 'p', 'p'

            expect { editor.send_keys 'P' }
              .to not_change { windows.count }
              .and start_editing(ctx1.absolute_path)
              .and not_to_change { window_height(windows.last) }
          end

          it 'enters the preview' do
            2.times do
              editor.send_keys 'p'

              expect { editor.raw_send_keys 'P' }
                .to not_change { windows.count }
                .and start_editing(ctx1.absolute_path)
              expect(current_window_highlight).to eq('Normal:NormalFloat')
              expect(editor.lines.to_a).to eq(ctx1.content)
              editor.quit!
            end
          end
        end

        context 'when the preview is closed' do
          it 'enters the preview without confirmations' do
            2.times do
              expect { editor.raw_send_keys 'P' }
                .to open_window(ctx1.absolute_path)
              expect(editor).to have_popup_highlight('Normal:NormalFloat')
              expect(editor.lines.to_a).to eq(ctx1.content)
              editor.quit!
            end
          end
        end
      end

      describe 'handling leaving entered' do
        include_context 'start search'
        include_context 'verify test files content is not modified after a testcase'

        before  { editor.send_keys 'P' }

        context 'from the [Command Line] while the preview is opened' do
          before do
            expect { editor.raw_send_keys 'q:' }
              .to open_window('[Command Line]')
          end

          it 'closes the preview on splitting' do
            expect { editor.raw_send_keys "isplit\n" }
              .to open_window(ctx1.absolute_path)
              .and change { window_highlights }
              .to(all(be_blank))
          end

          it 'closes the preview on editing in a tab' do
            expect { editor.raw_send_keys "itabedit\n" }
              .to change { tabpages_list.count }
              .by(1)
              .and change { window_highlights }
              .to(all(be_blank))
          end
        end

        context 'from the preview' do
          it 'closes the preview on splitting' do
            expect { editor.split! ctx2.absolute_path }
              .to start_editing(ctx2.absolute_path)
              .and not_to_change { windows.count }
              .and change { window_highlights }
              .to(all(be_blank))
          end

          it 'closes the preview on editing in a tab' do
            expect { editor.tabedit! ctx2.absolute_path }
              .to open_tab(ctx2.absolute_path)
              .and change { window_highlights }
              .to(all(be_blank))
          end

          it 'closes the preview on swithing to another window' do
            expect { editor.send_keys '\\<C-w>k' }
              .to change { editor.current_buffer_name }
              .and change { windows.count }
              .by(-1)
              .and change { window_highlights }
              .to(all(be_blank))
          end

          it 'closes the preview on starting a new search' do
            expect { esearch.search!(search_string) }
              .to change { editor.current_buffer_name }
              .and change { windows.count }
              .by(-1)
              .and change { window_highlights }
              .to(all(be_blank))
          end
        end
      end

      describe 'handling entering without swapfiles' do
        include_context 'start search'
        include_context 'verify test files content is not modified after a testcase'

        context 'when a file is opened in a split' do
          before do
            editor.edit_ignoring_swap!(ctx1.absolute_path, opener: 'vnew')
            editor.command! 'wincmd p'
          end

          it_behaves_like 'it enters the preview without confirmation'
        end

        context 'when a file is closed' do
          it_behaves_like 'it enters the preview without confirmation'

          context 'when deleting an opened buffer' do
            # NOTE dc09e176. Prevents options inheritance when trying to delete the buffer
            # A rare but still possible case
            it 'prevents options inheritance' do
              expect { editor.raw_send_keys 'P' }
                .to change { windows.count }
                .and start_editing(ctx1.absolute_path)
              expect(editor).to have_popup_highlight('Normal:NormalFloat')

              editor.command '%bwipeout'
              esearch.search!(search_string)
              ctx1.locate!

              expect { editor.edit_ignoring_swap!(ctx1.absolute_path) }
                .to open_window(ctx1.absolute_path)
              expect(editor).to have_default_window_highlights
            end
          end
        end
      end

      describe 'handling swapfiles' do
        let(:ctx1_swap) { swap_file('swap_content', ctx1.file) }
        let(:ctx2_swap) { swap_file('swap_content', ctx2.file) }
        before do
          test_directory.files << ctx1_swap
          test_directory.files << ctx2_swap
          test_directory.persist!
        end
        include_context 'enable swaps'
        include_context 'start search'
        include_context 'verify test files content is not modified after a testcase'

        context 'when a file is not opened' do
          context 'when editing' do
            context 'when the preview is opened' do
              it 'enters the buffer after confirmation' do
                2.times do
                  editor.send_keys 'p'
                  expect { editor.raw_send_keys 'P', CONFIRM_EDIT_IN_SWAP_PROMPT }
                    .to not_change { windows.count }
                    .and start_editing(ctx1.absolute_path)
                  expect(editor).to have_popup_highlight('Normal:NormalFloat')
                  editor.quit!
                end
              end
            end

            context 'when the preview is closed' do
              it 'enters the buffer after confirmation' do
                2.times do
                  expect { editor.raw_send_keys 'P', CONFIRM_EDIT_IN_SWAP_PROMPT }
                    .to open_window(ctx1.absolute_path)
                  expect(editor).to have_popup_highlight('Normal:NormalFloat')
                  editor.quit!
                end
              end
            end
          end

          context 'when cancelling' do
            context 'when a file is opened in a split' do
              before do
                editor.edit_ignoring_swap!(ctx1.absolute_path, opener: 'vnew')
                editor.command! 'wincmd p'
              end

              it_behaves_like 'it enters the preview without confirmation'
            end

            context "when a file isn't opened" do
              context 'when the preview is opened' do
                shared_examples 'it handles cancelling with' do |keys:|
                  it 'clears options on cancelling' do
                    editor.send_keys 'p'

                    expect { editor.raw_send_keys 'P', *keys }
                      .to close_window(windows.last)
                      .and not_to_change { editor.current_buffer_name }
                    expect(window_highlights).to all(eq(''))
                  end
                end

                # Pressing (A)bort throws an exception,
                it_behaves_like 'it handles cancelling with', keys: 'a'
                # ...  while pressing (Q)uit aren't
                it_behaves_like 'it handles cancelling with', keys: 'q'
              end

              context 'when the preview is closed' do
                shared_examples 'it handles cancelling with' do |keys:|
                  it 'clears options on cancelling' do
                    expect { editor.raw_send_keys 'P', *keys }
                      .to not_change { windows.count }
                      .and not_to_change { editor.current_buffer_name }
                    expect(window_highlights).to all(eq(''))
                  end
                end

                # Pressing (A)bort throws an exception,
                it_behaves_like 'it handles cancelling with', keys: 'a'
                # ...  while pressing (Q)uit aren't
                it_behaves_like 'it handles cancelling with', keys: 'q'
              end
            end
          end
        end
      end
    end
  end
end
