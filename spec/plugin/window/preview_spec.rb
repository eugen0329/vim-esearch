# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#preview' do
  include Helpers::FileSystem
  include Helpers::Preview
  include Helpers::Open
  include Helpers::ReportEditorStateOnError
  include VimlValue::SerializationHelpers
  Context ||= Helpers::Modifiable::Context

  # TODO: extra testing scenarios (currently blocked by editor version)
  #   - file with a name required to be escaped

  describe 'neovim', :neovim do
    # Random #shuffle can be reproduced by specifying --seed N, as Kernel.srand
    # is used in spec_helper
    # let(:uglified_names) do
    #   ['😄', '概', 'ц', 'æ', "a\a", "a\b", "a\t", "a\v", "a\f", "a\r",
    #    "a\e", '<', '<<', '>>', '(', ')', '[', ']', '{', '}', "'", ';', '&', '~',
    #    '$', '^', '*', '**', '+', '++', '-', '--', '>', '+a', '++a', '-a', '--a',
    #    '>a', 'a+', 'a++', 'a-', 'a--', 'a>', '\\', '\\\\', '"', '"a":1:b', 'a ',
    #    ' a', 'a b', ' 1 a b'].shuffle
    # end
    let(:uglified_names) do
      ['a', 'b']
    end

    let(:search_string) { 'n' }
    let(:contexts) do
      [Context.new(uglified_names.pop + '.c', ['int'] * 10),
       Context.new(uglified_names.pop + '.c', ['int'] * 10)]
    end
    let(:files) do
      contexts.map { |c| c.file = file(c.content, c.name) }
    end
    let!(:test_directory) { directory(files).persist! }
    let(:ctx1) { contexts[0] }
    let(:ctx2) { contexts[1] }

    around(Configuration.vimrunner_switch_to_neovim_callback_scope) { |e| use_nvim(&e) }
    after do
      expect(editor.messages).not_to include('Error')
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
        expect { editor.raw_send_keys *keys }
          .to close_popup_and_open_window
          .and stay_in_buffer
      end
    end

    shared_examples 'it closes the preview and enters into the buffer' do |keys:|
      it 'closes the preview and switches into the buffer' do
        expect { editor.raw_send_keys *keys }
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

    describe 'showing' do
      describe 'regular show' do
        include_context 'start search'
        include_context 'verify test files content is not modified after a testcase'

        it 'opens the preview on double click' do
          expect { editor.send_keys 'p', 'p' }
            .to stay_in_buffer
            .and change { windows.count }.by(1)
        end

        it 'opens the preview on double click' do
          expect {
            ctx1.locate!
            editor.send_keys 'p'
            ctx2.locate!
            editor.send_keys 'p'
          }.to stay_in_buffer
            .and change { windows.count }.by(1)
        end
      end

      describe 'closing' do
        include_context 'start search'
        include_context "open preview and verify it's correctness"
        include_context 'verify test files content is not modified after a testcase'
        after { expect(window_highlights).to all eq(default_highlight) }

        context 'when on moving the cursor' do
          it do
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
          it "doesn't unload the preview options" do
            expect { editor.raw_send_keys 'q:', ":q\n" }
              .to stay_in_buffer
              .and not_to_change { window_highlights }
          end

          it "doesn't unload autoclose events" do
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

        it_behaves_like 'it closes the preview stying in the search window', keys: ['T', 'e']
        it_behaves_like 'it closes the preview stying in the search window', keys: ['S', 'e']
        it_behaves_like 'it closes the preview stying in the search window', keys: ['O', 'e']

        it_behaves_like 'it closes the preview and enters into the buffer', keys: ['t', 'e']
        it_behaves_like 'it closes the preview and enters into the buffer', keys: ['s', 'e']
        it_behaves_like 'it closes the preview and enters into the buffer', keys: ['o', 'e']
      end
    end

    describe 'entering' do
      shared_examples 'it enters the preview without confirmation' do
        context 'when the preview is opened' do
          it 'enters the preview without confirmations' do
            2.times do
              editor.send_keys 'p'

              expect { editor.raw_send_keys 'P' }
                .to not_change { windows.count }
                .and start_editing(ctx1.absolute_path)
              expect(editor).to have_popup_highlight('Normal:NormalFloat')
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

      describe 'handling leaving' do
        include_context 'start search'
        include_context 'verify test files content is not modified after a testcase'

        before  { editor.send_keys 'P' }

        context 'from the [Command Line] while the preview is opened' do
          before do
            expect { editor.raw_send_keys 'q:' }
              .to open_window('[Command Line]')
          end

          it 'closes the preview and unloads highlights' do
            expect { editor.raw_send_keys "isplit\n" }
              .to open_window(ctx1.absolute_path)
              .and change { window_highlights }
              .to(all(be_blank))
          end

          it 'closes the preview and unloads highlights' do
            expect { editor.raw_send_keys "itabedit\n" }
              .to change { tabpages_list.count }
              .by(1)
              .and change { window_highlights }
              .to(all(be_blank))
          end
        end

        context 'from the preview' do
          it 'closes the preview on split' do
            expect { editor.command! "split #{editor.escape_filename(ctx2.absolute_path)}" }
              .to start_editing(ctx2.absolute_path)
              .and not_to_change { windows.count }
              .and change { window_highlights }
              .to(all(be_blank))
          end

          it 'closes the preview on edit in a tab' do
            expect { editor.command! "tabedit #{editor.escape_filename(ctx2.absolute_path)}" }
              .to open_tab(ctx2.absolute_path)
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
                  expect { editor.raw_send_keys 'P', 'e' }
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
                  expect { editor.raw_send_keys 'P', 'e' }
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

                # (A)abort throws an exception,
                it_behaves_like 'it handles cancelling with', keys: 'a'
                # ...  while (Q)uit not
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

                # (A)abort throws an exception,
                it_behaves_like 'it handles cancelling with', keys: 'a'
                # ...  while (Q)uit not
                it_behaves_like 'it handles cancelling with', keys: 'q'
              end
            end
          end
        end

      end
    end

    # describe 'entering' do
    #   context 'when preview is closed' do
    #     include_context 'start search'

    #     it 'opens preview window and enters into it' do
    #       expect { editor.send_keys 'P' }
    #         .to change { windows.count } .by(1)
    #         .and change { editor.current_buffer_name }
    #         .to(ctx1.absolute_path)
    #         .and change { window_highlights.uniq.sort }
    #         .to(['', 'Normal:NormalFloat'].sort)
    #     end
    #   end

    #   context 'when editing from preview' do
    #     include_context 'start search'
    #     before { editor.send_keys 'P' }

    #     it 'handles edit self' do
    #       expect { editor.command! "edit #{editor.escape_filename(ctx1.absolute_path)}" }
    #         .to not_change { tabpages_list.count }
    #         .and not_change { editor.current_buffer_name }
    #         .and not_change { window_highlights.uniq.sort }

    #       expect { editor.send_keys_separately ':q', :enter, :enter }
    #         .to change { window_highlights.uniq.sort }
    #         .to([''])
    #     end

    #     it 'handles edit in split' do
    #       expect { editor.command! "vnew #{editor.escape_filename(ctx1.absolute_path)}" }
    #         .to not_change { tabpages_list.count }
    #         .and not_change { editor.current_buffer_name }
    #         .and change { window_highlights.uniq.sort }
    #         .to(all(eq('')))
    #     end

    #     it 'handles edit in tab' do
    #       expect { editor.command! "tabedit #{editor.escape_filename(ctx2.absolute_path)}" }
    #         .to change { tabpages_list.count }
    #         .by(1)
    #         .and change { editor.current_buffer_name }
    #         .to(ctx2.absolute_path)
    #         .and change { window_highlights.uniq.sort }
    #         .to([''].sort)
    #     end
    #   end

    #   context 'when preview is opened' do
    #     include_context 'start search'
    #     before { editor.send_keys 'p' }

    #     it 'enters it' do
    #       expect { editor.send_keys 'P' }
    #         .to not_to_change { windows }
    #         .and change { editor.current_buffer_name }
    #         .to(ctx1.absolute_path)
    #         .and not_to_change { window_highlights.uniq.sort }
    #         .from(['', 'Normal:NormalFloat'].sort)
    #     end
    #   end

    #   context 'when preview is entered' do
    #     include_context 'start search'
    #     before  { editor.send_keys_separately 'P' }

    #     context 'when user closes the preview' do
    #       include_context 'verify test files content is not modified after a testcase'

    #       # regression on reentering
    #       it 'reenters consistently' do
    #         expect do
    #           editor.send_keys_separately ':quit', :enter
    #         end
    #           .to change { windows.count }
    #           .by(-1)
    #           .and change { editor.current_buffer_name }
    #           .to(include('Search'))
    #           .and change { window_highlights }
    #           .to(all(eq('')))

    #         expect {
    #           editor.send_keys 'P'
    #         } .to change { windows.count }
    #           .by(1)
    #           .and change { editor.current_buffer_name }
    #           .to(ctx1.absolute_path)
    #           .and change { window_highlights.uniq.sort }
    #           .to(['', 'Normal:NormalFloat'].sort)
    #       end
    #     end

    #     context 'when user switches to another buffer' do
    #       include_context 'verify test files content is not modified after a testcase'

    #       it 'closes the preview' do
    #         expect { editor.send_keys_separately '\\<C-w>j' }
    #           .to change { windows.count }
    #           .by(-1)
    #           .and change { editor.current_buffer_name }
    #           .to(include('Search'))
    #           .and change { window_highlights }
    #           .to(all(eq('')))
    #       end
    #     end
    #   end
    # end

    # xdescribe 'swapfiles' do
    #   # let(:swap_file) { file('swap_content', swap_path(ctx1.file.path)) }
    #   # let(:files) do
    #   #   contexts.first(1).map { |c| c.file = file(c.content, c.name) }
    #   # end

    #   # before do
    #   #   editor.command <<~VIML
    #   #     set swapfile directory=#{test_directory} updatecount=1
    #   #     set updatecount=1
    #   #   VIML
    #   #   # test_directory.files << swap_file
    #   #   # test_directory.persist!
    #   # end
    #   # include_context 'start search'
    #   # after do
    #   #   swap_file.unlink
    #   #   editor.command <<~VIML
    #   #     set noswapfile
    #   #     set updatecount=0
    #   #   VIML
    #   # end

    #   context 'when it enters the preview without confirmation window' do
    #     shared_examples 'it handles cancelling with' do |keys:|
    #       it 'clears options on cancelling' do
    #         editor.send_keys 'p'

    #         expect {
    #           editor.send_keys 'P'
    #           editor.raw_send_keys keys
    #         } .to change { windows.count }
    #           .by(-1)
    #           .and not_to_change { editor.current_buffer_name }

    #         expect(window_highlights).to all(eq(''))
    #       end
    #     end

    #     it_behaves_like 'it handles cancelling with', keys: 'a'
    #     it_behaves_like 'it handles cancelling with', keys: 'q'

    #     it "doesn't unload highlights and other options" do
    #       editor.send_keys 'p'

    #       expect {
    #         editor.send_keys 'P'
    #         editor.raw_send_keys 'e'
    #       } .to not_to_change { windows.count }
    #         .and change { editor.current_buffer_name }
    #         .to(ctx1.absolute_path)
    #         .and not_to_change { window_highlights.uniq.sort }
    #         .from(['', 'Normal:NormalFloat'].sort)
    #     end
    #   end

    #   context 'when showing the preview window' do
    #     after { expect(window_highlights).to all eq(default_highlight) }

    #     it 'handles buffer opened staying in the current window' do
    #       expect { editor.send_keys 'p' }
    #         .to change { windows.count }
    #         .by(1)
    #         .and not_to_change { editor.current_buffer_name }
    #         .and change { editor.ls }
    #         .to include('[Scratch]')

    #       expect { editor.raw_send_keys('S', 'e') }
    #         .to not_change { windows.count }
    #         .and not_to_change { editor.current_buffer_name }
    #     end

    #     # regression bug caused by raising error on nvim_open_win after
    #     # specifying a buffer with existing swap that is already opened
    #     it 'handles previously opened buffer' do
    #       2.times do
    #         expect { editor.send_keys 'p' }
    #           .to change { windows.count }
    #           .by(1)
    #           .and not_to_change { editor.current_buffer_name }

    #         # split and press (A)bort
    #         expect { editor.raw_send_keys('s', 'a') }
    #           .to change { windows.count }
    #           .by(-1)
    #           .and not_to_change { editor.current_buffer_name }
    #       end
    #     end
    #   end
    # end

    # describe 'handle blank results' do
    #   let(:search_string) { 'a' }
    #   let(:contexts) { [Context.new('file2.txt', 'b')] }

    #   it "doesn't fail on blank results" do
    #     expect { editor.send_keys 'p' }
    #       .to not_change { editor.messages }
    #       .and not_to_change { window_highlights }
    #       .and not_to_change { windows }
    #   end
    # end

    # describe 'handle opening multiple files' do
    #   include_context 'start search'

    #   context 'when opening with stay option' do
    #     it 'resets options on opening files' do
    #       expect do
    #         ctx1.locate!
    #         editor.send_keys_separately 'p', 'T'
    #         ctx2.locate!
    #         editor.send_keys_separately 'p', 'T'
    #       end
    #         .to change { windows.count }
    #         .by(2)
    #         .and not_to_change { window_highlights.uniq }
    #         .from([''])
    #     end
    #   end

    #   context 'when opening without stay option' do
    #     it 'resets options on opening files' do
    #       expect do
    #         ctx1.locate!
    #         editor.send_keys_separately 'p'
    #         ctx2.locate!
    #         editor.send_keys_separately 'p', 's'
    #       end
    #         .to change { windows.count }
    #         .by(1)
    #         .and not_to_change { window_highlights.uniq }
    #         .from([''])
    #     end
    #   end
    # end

    # describe 'bouncing keypress' do
    #   include_context 'start search'
    #   include_context "open preview and verify it's correctness"

    #   context 'bouncing split with staying in the current window' do
    #     let(:split_silent) { '\\<Plug>(esearch-win-split-silent)' }

    #     include_context 'verify test files content is not modified after a testcase'

    #     # regression bug when the second opened buffer had incorrect
    #     # winhighlight
    #     it 'resets window-local highlight for all opened windows' do
    #       expect { editor.send_keys split_silent, split_silent }
    #         .to change { windows.count }
    #         .by(1)
    #         .and not_to_change { editor.current_buffer_name }
    #       expect(window_highlights).to all eq(default_highlight)
    #     end
    #   end

    #   context 'when bouncing opening preview' do
    #     it 'keeps only a single preview window opened' do
    #       expect { editor.send_keys 'p', 'p' }
    #         .to not_change { windows.count }
    #         .and not_to_change { editor.current_buffer_name }
    #       expect(window_highlights[..-2]).to all eq(default_highlight)
    #       expect(window_highlights.last).to eq('Normal:NormalFloat')
    #     end
    #   end
    # end
  end
end
