# frozen_string_literal: true

require 'spec_helper'

describe 'Modify linewise', :window do
  include Helpers::FileSystem
  include VimlValue::SerializationHelpers
  include Helpers::Modifiable
  include Helpers::Modifiable::Linewise

  include_context 'setup modifiable testing'

  # Teting of 'Vjk' pressing is required to force vim to record linewise-visual
  # mode state (as there's no VisualEnter event)
  shared_context 'modify linewise' do |from:, to:|
    context "modify entries from #{from} to #{to}" do
      let(:from_ctx) { ctx_index(from) }
      let(:to_ctx) { ctx_index(to) }
      let(:from_entry) { entry_index(from) }
      let(:to_entry) { entry_index(to) }
      let(:affected_entries) { entries_from_range(from, to) }
      let(:unaffected_entries) { entries - affected_entries }
      let(:bounds) { [line_in_window(from), line_in_window(to)].reverse }
      let(:from_line) { bounds.first }
      let(:to_line)   { bounds.last }

      context 'when changing entries', :change do
        let!(:blanked_entry) { contexts[from_ctx].entries[from_entry] }
        let!(:deleted_entries) { affected_entries - [blanked_entry] }

        shared_context 'change entries' do |motion|
          it 'changes entries' do
            editor.locate_line! from_line

            expect { motion.call(to_line) }
              .not_to change { output.reloaded_entries!(unaffected_entries).map(&:line_content) }
            expect(output).to have_entries(entries).except(deleted_entries)

            if blanked_entry.present?
              expect(output.reload(blanked_entry).line_content)
                .to eq(blanked_entry.line_number_text)
            end
          end
        end

        context 'when normal mode' do
          include_examples 'change entries', ->(to_line) { editor.send_keys_separately "c#{to_line}gg" }
        end

        context 'when linewise-visual mode' do
          include_examples 'change entries', ->(to_line) { editor.send_keys_separately "V#{to_line}ggc" }
          include_examples 'change entries', ->(to_line) { editor.send_keys_separately 'Vjk', "#{to_line}ggc" }
        end
      end

      context 'when deleting entries', :delete do
        shared_context 'delete entries' do |motion|
          it 'deletes entries' do
            editor.locate_line! from_line

            expect { motion.call(to_line) }
              .not_to change { output.reloaded_entries!(unaffected_entries).map(&:line_content) }
            expect(output).to have_entries(entries).except(affected_entries)
          end
        end

        context 'when normal mode' do
          include_examples 'delete entries', ->(to_line) { editor.send_keys_separately "d#{to_line}gg" }
        end

        context 'when linewise-visual mode' do
          include_examples 'delete entries', ->(to_line) { editor.send_keys_separately "V#{to_line}ggx" }
          include_examples 'delete entries', ->(to_line) { editor.send_keys_separately 'Vjk', "#{to_line}ggx" }
        end
      end
    end
  end

  shared_context 'not modify' do |from:, to:|
    context "not modify entries from #{from} to #{to}" do
      let(:bounds) { [line_in_window(from), line_in_window(to)].reverse }
      let(:from_line) { bounds.first }
      let(:to_line)   { bounds.last }

      shared_context 'not modify entries' do |motion|
        it 'changes entries' do
          editor.locate_line! from_line

          expect { motion.call(to_line) }
            .not_to change { editor.lines.to_a }
        end
      end

      context 'when changing entries', :change do
        include_examples 'not modify entries', ->(to_line) { editor.send_keys_separately "c#{to_line}gg" }
        include_examples 'not modify entries', ->(to_line) { editor.send_keys_separately "V#{to_line}ggc" }
        include_examples 'not modify entries', ->(to_line) { editor.send_keys_separately "Vjk#{to_line}ggc" }
      end

      context 'when deleting entries', :delete do
        include_examples 'not modify entries', ->(to_line) { editor.send_keys_separately "d#{to_line}gg" }
        include_examples 'not modify entries', ->(to_line) { editor.send_keys_separately "V#{to_line}ggx" }
        include_examples 'not modify entries', ->(to_line) { editor.send_keys_separately "Vjk#{to_line}ggx" }
      end
    end
  end

  context 'when from the header' do
    include_examples 'not modify', from: {ctx: :header, ui: :name}, to: {ctx: :header, ui: :name}
    include_examples 'not modify', from: {ctx: :header, ui: :name}, to: {ctx: :header, ui: :separator}
    include_examples 'not modify', from: {ctx: :header, ui: :separator}, to: {ctx: :header, ui: :separator}

    %i[name separator].each do |ui|
      include_examples 'modify linewise', from: {ctx: :header, ui: ui}, to: {ctx: 0, entry: 0}
      include_examples 'modify linewise', from: {ctx: :header, ui: ui}, to: {ctx: 0, entry: 1}
      include_examples 'modify linewise', from: {ctx: :header, ui: ui}, to: {ctx: 0, entry: -1}
      include_examples 'not modify',      from: {ctx: :header, ui: ui}, to: {ctx: 0, ui: :name}
      include_examples 'modify linewise', from: {ctx: :header, ui: ui}, to: {ctx: 0, ui: :separator}

      include_examples 'modify linewise', from: {ctx: :header, ui: ui}, to: {ctx: 1, entry: 0}
      include_examples 'modify linewise', from: {ctx: :header, ui: ui}, to: {ctx: 1, entry: 1}
      include_examples 'modify linewise', from: {ctx: :header, ui: ui}, to: {ctx: 1, entry: -1}
      include_examples 'modify linewise', from: {ctx: :header, ui: ui}, to: {ctx: 1, ui: :name}
      include_examples 'modify linewise', from: {ctx: :header, ui: ui}, to: {ctx: 1, ui: :separator}

      include_examples 'modify linewise', from: {ctx: :header, ui: ui}, to: {ctx: -1, entry: 0}
      include_examples 'modify linewise', from: {ctx: :header, ui: ui}, to: {ctx: -1, entry: 1}
      include_examples 'modify linewise', from: {ctx: :header, ui: ui}, to: {ctx: -1, entry: -1}
      include_examples 'modify linewise', from: {ctx: :header, ui: ui}, to: {ctx: -1, ui: :name}
    end
  end

  context 'when from the 1st context' do
    context 'when from a filename' do
      context 'when within a context' do
        include_examples 'modify linewise', from: {ctx: 0, ui: :name}, to: {ctx: 0, entry: 0}
        include_examples 'modify linewise', from: {ctx: 0, ui: :name}, to: {ctx: 0, entry: 1}
        include_examples 'modify linewise', from: {ctx: 0, ui: :name}, to: {ctx: 0, entry: -1}
        include_examples 'not modify',      from: {ctx: 0, ui: :name}, to: {ctx: 0, ui: :name}
        include_examples 'modify linewise', from: {ctx: 0, ui: :name}, to: {ctx: 0, ui: :separator}
      end

      context 'when across multiple contexts' do
        include_examples 'modify linewise', from: {ctx: 0, ui: :name}, to: {ctx: 1, entry: 0}
        include_examples 'modify linewise', from: {ctx: 0, ui: :name}, to: {ctx: 1, entry: 1}
        include_examples 'modify linewise', from: {ctx: 0, ui: :name}, to: {ctx: 1, entry: -1}
        include_examples 'modify linewise', from: {ctx: 0, ui: :name}, to: {ctx: 1, ui: :name}
        include_examples 'modify linewise', from: {ctx: 0, ui: :name}, to: {ctx: 1, ui: :separator}

        include_examples 'modify linewise', from: {ctx: 0, ui: :name}, to: {ctx: -1, entry: 0}
        include_examples 'modify linewise', from: {ctx: 0, ui: :name}, to: {ctx: -1, entry: 1}
        include_examples 'modify linewise', from: {ctx: 0, ui: :name}, to: {ctx: -1, entry: -1}
        include_examples 'modify linewise', from: {ctx: 0, ui: :name}, to: {ctx: -1, ui: :name}
      end
    end

    context 'when from the 1st entry' do
      context 'when within a context' do
        include_examples 'modify linewise', from: {ctx: 0, entry: 0}, to: {ctx: 0, entry: 0}
        include_examples 'modify linewise', from: {ctx: 0, entry: 0}, to: {ctx: 0, entry: 1}
        include_examples 'modify linewise', from: {ctx: 0, entry: 0}, to: {ctx: 0, entry: -1}
        include_examples 'modify linewise', from: {ctx: 0, entry: 0}, to: {ctx: 0, ui: :separator}
      end

      context 'when across multiple contexts' do
        include_examples 'modify linewise', from: {ctx: 0, entry: 0}, to: {ctx: 1, entry: 0}
        include_examples 'modify linewise', from: {ctx: 0, entry: 0}, to: {ctx: 1, entry: 1}
        include_examples 'modify linewise', from: {ctx: 0, entry: 0}, to: {ctx: 1, entry: -1}
        include_examples 'modify linewise', from: {ctx: 0, entry: 0}, to: {ctx: 1, ui: :name}
        include_examples 'modify linewise', from: {ctx: 0, entry: 0}, to: {ctx: 1, ui: :separator}

        include_examples 'modify linewise', from: {ctx: 0, entry: 0}, to: {ctx: -1, entry: 0}
        include_examples 'modify linewise', from: {ctx: 0, entry: 0}, to: {ctx: -1, entry: 1}
        include_examples 'modify linewise', from: {ctx: 0, entry: 0}, to: {ctx: -1, entry: -1}
        include_examples 'modify linewise', from: {ctx: 0, entry: 0}, to: {ctx: -1, ui: :name}
      end
    end

    context 'when from the 2nd entry' do
      context 'when within a context' do
        include_examples 'modify linewise', from: {ctx: 0, entry: 1}, to: {ctx: 0, entry: 1}
        include_examples 'modify linewise', from: {ctx: 0, entry: 1}, to: {ctx: 0, entry: -1}
        include_examples 'modify linewise', from: {ctx: 0, entry: 1}, to: {ctx: 0, ui: :separator}
      end

      context 'when across multiple contexts' do
        include_examples 'modify linewise', from: {ctx: 0, entry: 1}, to: {ctx: 1, entry: 0}
        include_examples 'modify linewise', from: {ctx: 0, entry: 1}, to: {ctx: 1, entry: 1}
        include_examples 'modify linewise', from: {ctx: 0, entry: 1}, to: {ctx: 1, entry: -1}
        include_examples 'modify linewise', from: {ctx: 0, entry: 1}, to: {ctx: 1, ui: :name}
        include_examples 'modify linewise', from: {ctx: 0, entry: 1}, to: {ctx: 1, ui: :separator}

        include_examples 'modify linewise', from: {ctx: 0, entry: 1}, to: {ctx: -1, entry: 0}
        include_examples 'modify linewise', from: {ctx: 0, entry: 1}, to: {ctx: -1, entry: 1}
        include_examples 'modify linewise', from: {ctx: 0, entry: 1}, to: {ctx: -1, entry: -1}
        include_examples 'modify linewise', from: {ctx: 0, entry: 1}, to: {ctx: -1, ui: :name}
      end
    end

    context 'when from a separator' do
      context 'when within a context' do
        include_examples 'not modify',      from: {ctx: 0, ui: :separator}, to: {ctx: 0, ui: :separator}
      end

      context 'when across multiple contexts' do
        include_examples 'modify linewise', from: {ctx: 0, ui: :separator}, to: {ctx: 1, entry: 0}
        include_examples 'modify linewise', from: {ctx: 0, ui: :separator}, to: {ctx: 1, entry: 1}
        include_examples 'modify linewise', from: {ctx: 0, ui: :separator}, to: {ctx: 1, entry: -1}
        include_examples 'not modify',      from: {ctx: 0, ui: :separator}, to: {ctx: 1, ui: :name}
        include_examples 'modify linewise', from: {ctx: 0, ui: :separator}, to: {ctx: 1, ui: :separator}

        include_examples 'modify linewise', from: {ctx: 0, ui: :separator}, to: {ctx: -1, entry: 0}
        include_examples 'modify linewise', from: {ctx: 0, ui: :separator}, to: {ctx: -1, entry: 1}
        include_examples 'modify linewise', from: {ctx: 0, ui: :separator}, to: {ctx: -1, entry: -1}
        include_examples 'modify linewise', from: {ctx: 0, ui: :separator}, to: {ctx: -1, ui: :name}
      end
    end
  end

  context 'when from the 2nd context' do
    context 'when from a filename' do
      context 'when within a context' do
        include_examples 'modify linewise', from: {ctx: 1, ui: :name}, to: {ctx: 1, entry: 0}
        include_examples 'modify linewise', from: {ctx: 1, ui: :name}, to: {ctx: 1, entry: 1}
        include_examples 'modify linewise', from: {ctx: 1, ui: :name}, to: {ctx: 1, entry: -1}
        include_examples 'modify linewise', from: {ctx: 1, ui: :name}, to: {ctx: 1, ui: :separator}
      end

      context 'when across multiple contexts' do
        include_examples 'modify linewise', from: {ctx: 1, ui: :name}, to: {ctx: -1, entry: 0}
        include_examples 'modify linewise', from: {ctx: 1, ui: :name}, to: {ctx: -1, entry: 1}
        include_examples 'modify linewise', from: {ctx: 1, ui: :name}, to: {ctx: -1, entry: -1}
        include_examples 'modify linewise', from: {ctx: 1, ui: :name}, to: {ctx: -1, ui: :name}
      end
    end

    context 'when from the 1st entry' do
      context 'when within a context' do
        include_examples 'modify linewise', from: {ctx: 1, entry: 0}, to: {ctx: 1, entry: 0}
        include_examples 'modify linewise', from: {ctx: 1, entry: 0}, to: {ctx: 1, entry: 1}
        include_examples 'modify linewise', from: {ctx: 1, entry: 0}, to: {ctx: 1, entry: -1}
        include_examples 'modify linewise', from: {ctx: 1, entry: 0}, to: {ctx: 1, ui: :separator}
      end

      context 'when across multiple contexts' do
        include_examples 'modify linewise', from: {ctx: 1, entry: 0}, to: {ctx: -1, entry: 0}
        include_examples 'modify linewise', from: {ctx: 1, entry: 0}, to: {ctx: -1, entry: 1}
        include_examples 'modify linewise', from: {ctx: 1, entry: 0}, to: {ctx: -1, entry: -1}
        include_examples 'modify linewise', from: {ctx: 1, entry: 0}, to: {ctx: -1, ui: :name}
      end
    end

    context 'when from the 2nd entry' do
      context 'when within a context' do
        include_examples 'modify linewise', from: {ctx: 1, entry: 1}, to: {ctx: 1, entry: 1}
        include_examples 'modify linewise', from: {ctx: 1, entry: 1}, to: {ctx: 1, entry: -1}
        include_examples 'modify linewise', from: {ctx: 1, entry: 1}, to: {ctx: 1, ui: :separator}
      end

      context 'when across multiple contexts' do
        include_examples 'modify linewise', from: {ctx: 1, entry: 1}, to: {ctx: -1, entry: 0}
        include_examples 'modify linewise', from: {ctx: 1, entry: 1}, to: {ctx: -1, entry: 1}
        include_examples 'modify linewise', from: {ctx: 1, entry: 1}, to: {ctx: -1, entry: -1}
        include_examples 'modify linewise', from: {ctx: 1, entry: 1}, to: {ctx: -1, ui: :name}
      end
    end

    context 'when from a separator' do
      context 'when within a context' do
        include_examples 'not modify',      from: {ctx: 1, ui: :separator}, to: {ctx: 1, ui: :separator}
      end

      context 'when across multiple contexts' do
        include_examples 'modify linewise', from: {ctx: 1, ui: :separator}, to: {ctx: -1, entry: 0}
        include_examples 'modify linewise', from: {ctx: 1, ui: :separator}, to: {ctx: -1, entry: 1}
        include_examples 'modify linewise', from: {ctx: 1, ui: :separator}, to: {ctx: -1, entry: -1}
        include_examples 'not modify',      from: {ctx: 1, ui: :separator}, to: {ctx: -1, ui: :name}
      end
    end
  end
end
