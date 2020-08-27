# frozen_string_literal: true

require 'spec_helper'

describe 'Insert mode', :window do
  include Helpers::FileSystem
  include VimlValue::SerializationHelpers
  include Helpers::Modifiable
  include Helpers::Modifiable::Linewise
  include Helpers::Modifiable::Columnwise

  include_context 'setup modifiable testing'

  shared_context  'modify blockwise' do |from:, to:|
    include_context 'setup columnwise testing', from, to

    shared_context 'it modifies entries using anchors' do |anchor1, anchor2|
      shared_examples 'it modifies using motion' do |motion|
        let(:anchor2_char) { anchor_char(anchor2, to) }
        let(:column1) { anchor_column(anchor1, from) }
        let(:column2) { anchor_column(anchor2, to) }

        it do
          locate_anchor(from, anchor1)
          motion.call(anchor2_char)

          affected_entries.each do |entry|
            expect(entry.line_content)
              .to eq(delete_between_columns(entry, column1, column2))
          end
        end
      end

      it_behaves_like 'it modifies using motion',
        ->(anchor) { editor.send_keys_separately '\\<C-v>', "f#{anchor}", 'x' }
      it_behaves_like 'it modifies using motion',
        ->(anchor) { editor.send_keys_separately '\\<C-v>', "f#{anchor}", 's' }
    end

    it_behaves_like 'it modifies entries using anchors', :begin, :end
    it_behaves_like 'it modifies entries using anchors', :begin, :middle
    it_behaves_like 'it modifies entries using anchors', :middle, :end
    it_behaves_like 'it modifies entries using anchors', :end, :end
  end

  context 'from name to entry' do
    it_behaves_like 'modify blockwise', from: {ctx: 0,  ui: :name}, to: {ctx: 0,  entry: 1}
    it_behaves_like 'modify blockwise', from: {ctx: 0,  ui: :name}, to: {ctx: 1,  entry: -1}
    it_behaves_like 'modify blockwise', from: {ctx: 0,  ui: :name}, to: {ctx: -1, entry: -1}

    it_behaves_like 'modify blockwise', from: {ctx: 1,  ui: :name}, to: {ctx: 1,  entry: -1}
    it_behaves_like 'modify blockwise', from: {ctx: 1,  ui: :name}, to: {ctx: -1, entry: 1}

    it_behaves_like 'modify blockwise', from: {ctx: -1, ui: :name}, to: {ctx: -1, entry: 1}
  end

  context 'from entry to entry' do
    it_behaves_like 'modify blockwise', from: {ctx: 0,  entry: 0}, to: {ctx: 0,  entry: 1}
    it_behaves_like 'modify blockwise', from: {ctx: 0,  entry: 0}, to: {ctx: 1,  entry: -1}
    it_behaves_like 'modify blockwise', from: {ctx: 0,  entry: 0}, to: {ctx: -1, entry: -1}

    it_behaves_like 'modify blockwise', from: {ctx: 1,  entry: 0}, to: {ctx: 1,  entry: -1}
    it_behaves_like 'modify blockwise', from: {ctx: 1,  entry: 0}, to: {ctx: -1, entry: 1}

    it_behaves_like 'modify blockwise', from: {ctx: -1, entry: 0}, to: {ctx: -1, entry: 1}
  end
end
