# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#preview' do
  include Helpers::FileSystem
  include Helpers::Output
  include Helpers::ReportEditorStateOnError
  include VimlValue::SerializationHelpers

  before  { esearch.configure(root_markers: []) }

  let!(:test_directory) { directory(files).persist! }

  let(:files) do
    [file('aaa', 'from.txt')]
  end

  describe 'neovim', :neovim do
    around(Configuration.vimrunner_switch_to_neovim_callback_scope) { |e| use_nvim(&e) }
    before do
      esearch.configure!(regex: 1, backend: 'system', adapter: 'ag', 'out': 'win', root_markers: [])
    end
    after { esearch.cleanup! }
    include_context 'report editor state on error'

    before do
      esearch.cd! test_directory
      esearch.search!('a')
      expect { editor.press! 'p' }
        .to change { editor.windows_list.count }
        .by(1)
      expect(editor.map_windows_options('winhighlight')).to contain_exactly('', '', 'Normal:NormalFloat')
    end

    it do
      expect { editor.press! 'l' } .to change { editor.windows_list.count } .by(-1)
      expect(editor.map_windows_options('winhighlight')).to contain_exactly('', '')
    end

    shared_examples 'silent open' do |key|
      it do
        expect { editor.send_keys key }
          .to not_change { editor.windows_list.count }
          .and not_to_change { editor.current_buffer_name }
        expect(editor.map_windows_options('winhighlight')).to all eq('')
        editor.locate_buffer! files.first.path
        expect(editor.lines.to_a).to eq(files.first.lines)
      end
    end

    shared_examples 'non-silent open' do |key|
      it do
        expect { editor.send_keys key }.not_to change { editor.windows_list.count }
        expect(editor.map_windows_options('winhighlight')).to all eq('')
        expect(editor.current_buffer_name).to eq(files.first.path.to_s)
        expect(editor.lines.to_a).to eq(files.first.lines)
      end
    end

    it do
      expect { editor.send_keys :enter }.to change { editor.windows_list.count }.by(-1)
      expect(editor.map_windows_options('winhighlight')).to all eq('')
      expect(editor.current_buffer_name).to eq(files.first.path.to_s)
      expect(editor.lines.to_a).to eq(files.first.lines)
    end

    it_behaves_like 'silent open', 'T'
    it_behaves_like 'silent open', 'S'
    it_behaves_like 'silent open', 'O'

    it_behaves_like 'non-silent open', 't'
    it_behaves_like 'non-silent open', 's'
    it_behaves_like 'non-silent open', 'o'

    context 'reset winhl' do
      it do
        expect { editor.send_keys 'S', 'S' }
          .to change { editor.windows_list.count }.by(1)
          .and not_to_change { editor.current_buffer_name }
        expect(editor.map_windows_options('winhighlight')).to all eq('')
        editor.locate_buffer! files.first.path
        expect(editor.lines.to_a).to eq(files.first.lines)
      end
    end
  end
end
