# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#option' do
  include VimlValue::SerializationHelpers
  include Helpers::Vim

  around { |e| editor.with_ignore_cache(&e) }

  describe 'esearch#option#make_local_to_buffer' do
    subject(:make_local_to_buffer) do
      lambda do |name, value, prevent_leak_event|
        editor.echo func('esearch#option#make_local_to_buffer', name, value, prevent_leak_event)
      end
    end

    let(:original) { 'eol' }
    let(:changed) { 'indent' }
    let(:name) { 'backspace' }
    let(:option) { "&#{name}" }

    before { editor.command! "set #{name}=#{original}" }

    after do
      editor.echo(func('esearch#option#reset'))
      editor.cleanup!
    end

    context 'when creating and switching to a new one (BufLeave)' do
      before do
        expect { make_local_to_buffer.call(name, changed, nil) }
          .to change_option(option)
          .to(changed)
      end

      it do
        expect { editor.command! 'tabnew' }
          .to change_option(option)
          .to(original)
      end
    end

    context 'when switching to an existing buffer (BufLeave)' do
      before do
        editor.command! 'tabnew'
        expect { make_local_to_buffer.call(name, changed, nil) }
          .to change_option(option)
          .to(changed)
      end

      it do
        expect { editor.command! 'tabnext' }
          .to change_option(option)
          .to(original)
      end
    end

    context 'when entering to previously configured buffer (BufEnter)' do
      before do
        editor.command! 'tabnew'
        expect { make_local_to_buffer.call(name, changed, nil) }
          .to change_option(option)
          .to(changed)
        expect { editor.command! 'tabnext' }.to change_option(option)
      end

      it do
        expect { editor.command! 'tabprev' }
          .to change_option(option)
          .to eq(changed)
      end
    end

    context 'when leaving with :noautocmd' do
      before do
        editor.command! 'tabnew'
        expect { make_local_to_buffer.call(name, changed, 'InsertEnter') }
          .to change_option(option)
          .to(changed)
      end

      it 'prevents option value leak' do
        expect { editor.command! 'noau tabnext' }.not_to change_option(option)

        expect { editor.send_keys_separately 'i' }
          .to change_option(option)
          .to(original)
      end

      it 'does restoring once' do
        expect { editor.command! 'noau tabnext' }.not_to change_option(option)
        editor.send_keys_separately 'i', :escape

        expect { editor.send_keys_separately 'i' }
          .not_to change_option(option)
      end

      it "doesn't restore original on event within buffer" do
        expect { editor.send_keys_separately 'i' }
          .not_to change_option(option)
      end
    end
  end
end
