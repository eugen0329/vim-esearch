# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#out#win#open' do
  include Helpers::FileSystem
  include Helpers::ReportEditorStateOnError
  include VimlValue::SerializationHelpers
  include Helpers::Modifiable
  include Helpers::Open
  Context ||= Helpers::Modifiable::Context

  let(:contexts) do
    [Context.new('file1.txt', "111\n222"),
     Context.new('file2.txt', "333\n444"),]
  end
  let(:files) do
    contexts.map { |c| c.file = file(c.content, c.name) }
  end
  let!(:test_directory) { directory(files).persist! }
  let(:ctx1) { contexts[0] }
  let(:ctx2) { contexts[1] }

  shared_context 'start search matching any lines' do
    before do
      esearch.configure!(
        out:          'win',
        regex:        1,
        backend:      'system',
        adapter:      'ag',
        root_markers: []
      )
      esearch.cd! test_directory
      esearch.search!('^')
    end
  end

  after do
    expect(editor.messages).not_to include('Error')
    esearch.cleanup!
  end

  include_context 'report editor state on error'

  # TODO: test cmdarg and mods more thoroughly

  describe 'split_preview' do
    # Tested here as it's literally a wrapper around regular open
    before do
      editor.command! <<~VIML
        call esearch#out#win#map('e', { es -> es.split_preview() })
      VIML
    end
    include_context 'start search matching any lines'
    before { ctx1.entries[0].locate! }

    it 'opens preview in a split' do
      expect { editor.send_keys 'e' }
        .to change { tabpage_buffers_list.count }
        .by(1)
        .and not_to_change { editor.current_buffer_name }
        .and not_to_change { tabpages_list.count }
        .and change { editor.buffers.last }
        .to(ctx1.absolute_path)
    end

    context 'when previewing multiple lines within the same files' do
      before do
        editor.command <<~VIML
          let g:opens_count = 0
          au BufRead * let g:opens_count += 1
        VIML
      end

      it "doesn't read a buffer opened in a window twice" do
        expect do
          ctx1.entries[0].locate!
          editor.send_keys 'e'
        end.to change { editor.echo(var('g:opens_count')) }
        expect do
          ctx1.entries[1].locate!
          editor.send_keys 'e'
        end.not_to change { editor.echo(var('g:opens_count')) }
      end
    end

    context 'when folds are enabled' do
      it 'unfolds using nofoldenable' do
        editor.send_keys 'e'
        expect(editor.window_variable(tabpage_windows_list.first, '&foldenable'))
          .to eq(1)
        expect(editor.window_variable(tabpage_windows_list.last, '&foldenable'))
          .to eq(0)
      end
    end

    context 'when bouncing call' do
      before do
        editor.command <<~VIML
          let g:jumps_count = 0
          au BufWinEnter * let g:jumps_count += 1
        VIML
      end

      it "doesn't jump if the line is located" do
        expect { editor.send_keys 'e' }
          .to change { editor.echo(var('g:jumps_count')) }
        expect { editor.send_keys_separately 'e', 'l', 'e' }
          .not_to change { editor.echo(var('g:jumps_count')) }
      end
    end
  end

  describe 'via mappings defined by user' do
    context 'when callable rhs' do
      context 'when callable opener given' do
        context 'when once options are given' do
          before do
            editor.command! <<~VIML.gsub("\n", ' ')
              call esearch#out#win#map('e', { ->
              b:esearch.open({filename -> execute('vsplit ' . filename)}, {'reuse': 1, 'stay': 1})
              })
            VIML
          end
          include_context 'start search matching any lines'
          before { ctx1.locate! }

          # Every lambda has it's own internal id showed when string() is
          # called, so lambda callers are needed to be handled differently

          it 'handles recognizes lambdas with the same bodies as openers' do
            expect { editor.send_keys 'e', 'e' }
              .to change { tabpage_buffers_list.count }
              .by(1)
              .and not_to_change { editor.current_buffer_name }
              .and not_to_change { tabpages_list.count }
          end
        end

        context 'when without options' do
          before do
            editor.command! <<~VIML.gsub("\n", ' ')
              call esearch#out#win#map('e', {->
              b:esearch.open({filename -> execute('vsplit '. filename)})
              })
            VIML
          end
          include_context 'start search matching any lines'
          before { ctx1.locate! }

          it 'handles callable rhs with callable opener' do
            expect { editor.send_keys 'e' }
              .to change { tabpage_buffers_list.count }
              .by(1)
              .and change { editor.current_buffer_name }
              .to(ctx1.absolute_path)
              .and not_to_change { tabpages_list.count }
          end
        end
      end

      context 'when string opener given' do
        # BUG #105
        context 'when CTRL-U mappings are defined' do
          before do
            editor.command! <<~VIML
              cnoremap <c-u> <c-u><bs>
              call esearch#out#win#map('e', { -> b:esearch.open('vsplit') })
            VIML
          end
          include_context 'start search matching any lines'
          before { ctx1.locate! }
          after { editor.command! 'cunmap <c-u>' }

          it 'handles recognizes lambdas with the same bodies as openers' do
            expect { editor.send_keys 'e' }
              .to change { tabpage_buffers_list.count }
              .by(1)
              .and change { editor.current_buffer_name }
              .to(ctx1.absolute_path)
              .and not_to_change { tabpages_list.count }
          end
        end

        context 'when once options are given' do
          before do
            editor.command! <<~VIML.gsub("\n", ' ')
              call esearch#out#win#map('e', { ->
              b:esearch.open('split',
              {'cmdarg': '++enc=utf8', 'mods': 'topleft', 'stay': 1, 'reuse': 1, 'let': {'&eventignore': 'all'}})
              })
            VIML
          end
          include_context 'start search matching any lines'
          before { ctx1.locate! }

          it 'handles callable rhs according to provided options' do
            expect { editor.send_keys 'e', 'e' }
              .to change { tabpage_buffers_list.count }
              .by(1)
              .and not_to_change { editor.current_buffer_name }
              .and not_to_change { tabpages_list.count }
          end
        end

        context 'when without options' do
          before do
            editor.command! <<~VIML
              call esearch#out#win#map('e', { -> b:esearch.open('tab drop') })
            VIML
          end
          include_context 'start search matching any lines'
          before { ctx1.locate! }

          it 'handles callable rhs' do
            expect { editor.send_keys 'e' }
              .to change { tabpages_list.count }
              .by(1)
              .and change { editor.current_buffer_name }
              .to(ctx1.absolute_path)
              .and not_to_change { tabpage_buffers_list.count }
          end
        end
      end
    end
  end

  describe 'via default mappings' do
    include_context 'start search matching any lines'

    before  { ctx1.locate! }

    # BUG #105
    context 'when CTRL-U mappings are defined' do
      before { editor.command! 'cnoremap <c-u> <c-u><bs>' }
      include_context 'start search matching any lines'
      before { ctx1.locate! }
      after { editor.command! 'cunmap <c-u>' }

      it 'handles recognizes lambdas with the same bodies as openers' do
        expect { editor.send_keys 's' }
          .to change { tabpage_buffers_list.count }
          .by(1)
          .and change { editor.current_buffer_name }
          .to(ctx1.absolute_path)
          .and not_to_change { tabpages_list.count }
      end
    end

    context "when with 'stay' option" do
      describe 'mixing different openers' do
        context 'when for multiple files' do
          it 'ensures only a single window opened per split kind' do
            expect do
              ctx1.locate!
              editor.send_keys 'O'
              ctx2.locate!
              editor.send_keys 'S'
            end.to change { tabpage_buffers_list.count }
              .by(2)
              .and not_to_change { editor.current_buffer_name }
              .and not_to_change { tabpages_list.count }
          end
        end

        context 'when for a single file' do
          it 'ensures only a single window opened per split kind' do
            expect { editor.send_keys 'O', 'S' }
              .to change { tabpage_buffers_list.count }
              .by(2)
              .and not_to_change { editor.current_buffer_name }
              .and not_to_change { tabpages_list.count }
          end
        end
      end

      describe 'open in vertical split' do
        it 'opens only one window' do
          expect { editor.send_keys 'S', 'S' }
            .to change { tabpage_buffers_list.count }
            .by(1)
            .and not_to_change { editor.current_buffer_name }
            .and not_to_change { tabpages_list.count }
        end

        it 'opens staying in the window' do
          expect { editor.send_keys 'S' }
            .to change { tabpage_buffers_list.count }
            .by(1)
            .and not_to_change { editor.current_buffer_name }
            .and not_to_change { tabpages_list.count }
        end
      end

      describe 'open in horizontal split' do
        it 'opens only one window' do
          expect { editor.send_keys 'O', 'O' }
            .to change { tabpage_buffers_list.count }
            .by(1)
            .and not_to_change { editor.current_buffer_name }
            .and not_to_change { tabpages_list.count }
        end

        it 'opens staying in the window' do
          expect { editor.send_keys 'O' }
            .to change { tabpage_buffers_list.count }
            .by(1)
            .and not_to_change { editor.current_buffer_name }
            .and not_to_change { tabpages_list.count }
        end
      end

      describe 'open in tab' do
        it 'opens multiple tabs' do
          expect { editor.send_keys 'T', 'T' }
            .to change { tabpages_list.count }
            .by(2)
            .and not_to_change { editor.current_buffer_name }
            .and not_to_change { tabpage_buffers_list.count }
        end

        it 'opens staying in the window' do
          expect { editor.send_keys 'T' }
            .to change { tabpages_list.count }
            .by(1)
            .and not_to_change { editor.current_buffer_name }
            .and not_to_change { tabpage_buffers_list.count }
        end
      end
    end

    describe 'regular' do
      it 'opens a file and jumps to the window' do
        expect { editor.send_keys 's' }
          .to change { tabpage_buffers_list.count }
          .by(1)
          .and change { editor.current_buffer_name }
          .to(ctx1.absolute_path)
          .and not_to_change { tabpages_list.count }
      end

      it 'opens a file and jumps to the window' do
        expect { editor.send_keys 'o' }
          .to change { tabpage_buffers_list.count }
          .by(1)
          .and change { editor.current_buffer_name }
          .to(ctx1.absolute_path)
          .and not_to_change { tabpages_list.count }
      end

      it 'opens a file and jumps to the window' do
        expect { editor.send_keys 't' }
          .to change { tabpages_list.count }
          .by(1)
          .and change { editor.current_buffer_name }
          .to(ctx1.absolute_path)
          .and not_to_change { tabpage_buffers_list.count }
      end

      it 'opens a file reusing the current window' do
        expect { editor.send_keys :enter }
          .to not_change { tabpage_buffers_list.count }
          .and change { editor.current_buffer_name }
          .to(ctx1.absolute_path)
          .and not_to_change { tabpages_list.count }
      end
    end
  end
end
