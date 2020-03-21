# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#preview' do
  include Helpers::FileSystem
  include Helpers::ReportEditorStateOnError
  include VimlValue::SerializationHelpers
  include Helpers::Modifiable
  include Helpers::Open
  Context ||= Helpers::Modifiable::Context

  describe 'neovim' do
    let(:contexts) do
      [Context.new('file1.txt', '111'),
       Context.new('file2.txt', '222')]
    end
    let(:files) do
      contexts.map { |c| c.file = file(c.content, c.name) }
    end
    let!(:test_directory) { directory(files).persist! }

    before do
      esearch.configure!(
        out: 'win',
        regex: 1,
        backend: 'system',
        adapter: 'ag',
        root_markers: []
      )
      esearch.cd! test_directory
      esearch.search!('^')
    end

    after do
      expect(editor.messages).not_to include('Error')
      esearch.cleanup!
    end

    include_context 'report editor state on error'

    describe 'defined by user' do
    end

    describe 'defaults' do
      let(:ctx1) { contexts[0] }
      let(:ctx2) { contexts[1] }

      before  { ctx1.locate! }

      context "when with 'stay' option" do
        describe 'mixing vertical and horizontal splits' do
          context 'when for multiple files' do
            it "ensures only a single window opened per split kind" do
              expect {
                ctx1.locate!
                editor.send_keys 'O'
                ctx2.locate!
                editor.send_keys 'S'
              }.to change { tabpage_windows_list.count }
                .by(2)
                .and not_to_change { editor.current_buffer_name }
                .and not_to_change { tabpages_list.count }
            end
          end

          context 'when for a single file' do
            it "ensures only a single window opened per split kind" do
              expect { editor.send_keys 'O', 'S' }
                .to change { tabpage_windows_list.count }
                .by(2)
                .and not_to_change { editor.current_buffer_name }
                .and not_to_change { tabpages_list.count }
            end
          end
        end

        describe 'open in vertical split' do
          it "opens only one window" do
            expect { editor.send_keys 'S', 'S' }
              .to change { tabpage_windows_list.count }
              .by(1)
              .and not_to_change { editor.current_buffer_name }
              .and not_to_change { tabpages_list.count }
          end

          it "opens staying in the window" do
            expect { editor.send_keys 'S' }
              .to change { tabpage_windows_list.count }
              .by(1)
              .and not_to_change { editor.current_buffer_name }
              .and not_to_change { tabpages_list.count }
          end
        end

        describe 'open in horizontal split' do
          it "opens only one window" do
            expect { editor.send_keys 'O', 'O' }
              .to change { tabpage_windows_list.count }
              .by(1)
              .and not_to_change { editor.current_buffer_name }
              .and not_to_change { tabpages_list.count }
          end

          it "opens staying in the window" do
            expect { editor.send_keys 'O' }
              .to change { tabpage_windows_list.count }
              .by(1)
              .and not_to_change { editor.current_buffer_name }
              .and not_to_change { tabpages_list.count }
          end
        end

        describe 'open in tab' do
          it "opens multiple tabs" do
            expect { editor.send_keys 'T', 'T' }
              .to change { tabpages_list.count }
              .by(2)
              .and not_to_change { editor.current_buffer_name }
              .and not_to_change { tabpage_windows_list.count }
          end

          it "opens staying in the window" do
            expect { editor.send_keys 'T' }
              .to change { tabpages_list.count }
              .by(1)
              .and not_to_change { editor.current_buffer_name }
              .and not_to_change { tabpage_windows_list.count }
          end
        end
      end

      describe 'regular' do
        it "opens a file and jumps to the window" do
          expect { editor.send_keys 's' }
            .to change { tabpage_windows_list.count }
            .by(1)
            .and change { editor.current_buffer_name }
            .to(ctx1.absolute_path)
            .and not_to_change { tabpages_list.count }
        end

        it "opens a file and jumps to the window" do
          expect { editor.send_keys 'o' }
            .to change { tabpage_windows_list.count }
            .by(1)
            .and change { editor.current_buffer_name }
            .to(ctx1.absolute_path)
            .and not_to_change { tabpages_list.count }
        end

        it "opens a file and jumps to the window" do
          expect { editor.send_keys 't' }
            .to change { tabpages_list.count }
            .by(1)
            .and change { editor.current_buffer_name }
            .to(ctx1.absolute_path)
            .and not_to_change { tabpage_windows_list.count }
        end

        it "opens a file reusing the current window" do
          expect { editor.send_keys :enter }
            .to not_change { tabpage_windows_list.count }
            .and change { editor.current_buffer_name }
            .to(ctx1.absolute_path)
            .and not_to_change { tabpages_list.count }
        end
      end
    end
  end
end
