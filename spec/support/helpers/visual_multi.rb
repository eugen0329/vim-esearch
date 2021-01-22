# frozen_string_literal: true

module Helpers::VisualMulti
  extend RSpec::Matchers::DSL

  shared_examples 'keep editor state unmodified' do |motion, mode: :normal|
    # are merged for performance reasons
    it 'keeps editor lines text' do
      expect { motion.call }.not_to change { editor.lines.to_a }
      expect(editor.mode).to eq(mode)
    end
  end

  shared_examples 'it disallows EXTEND mode motion' do |motion|
    before do
      locate_anchor({ctx: 0, entry: 0}, anchor)
      editor.send_keys_separately '\\<c-down>' * (ctx.entries.count - 1), 'siw'
    end

    include_examples 'keep editor state unmodified', motion
  end

  shared_examples 'it disallows NORMAL mode motion' do |motion|
    before do
      locate_anchor({ctx: 0, entry: 0}, anchor)
      editor.send_keys_separately '\\<c-down>' * (ctx.entries.count - 1)
    end

    include_examples 'keep editor state unmodified', motion
  end

  shared_examples 'it disallows non-INSERT motion' do |motion|
    it_behaves_like 'it disallows EXTEND mode motion', motion, mode: :normal
    it_behaves_like 'it disallows NORMAL mode motion', motion, mode: :normal
  end

  shared_examples 'it disallows INSERT mode motion' do |motion|
    before do
      locate_anchor({ctx: 0, entry: 0}, anchor)
      editor.send_keys_separately '\\<c-down>' * (ctx.entries.count - 1)
    end

    include_examples 'keep editor state unmodified', motion, mode: :insert
  end

  shared_examples 'delete word and whitespaces after' do |motion|
    before do
      locate_anchor({ctx: 0, entry: 0}, anchor)
      editor.send_keys_separately '\\<c-down>' * (ctx.entries.count - 1)
    end

    it 'deletes word and whitespaces after using multiple cursors' do
      motion.call

      ctx.entries.each do |entry|
        a_word = /#{anchor_char(anchor, {ctx: 0, entry: entry.index})}\s+/
        expect(entry.line_content).to eq(entry.cached_line_content.gsub(a_word, ''))
      end
    end
  end

  shared_examples 'delete word' do |motion|
    before do
      locate_anchor({ctx: 0, entry: 0}, anchor)
      editor.send_keys_separately '\\<c-down>' * (ctx.entries.count - 1)
    end

    it 'deletes word using multiple cursors' do
      motion.call

      ctx.entries.each do |entry|
        inner_word = anchor_char(anchor, {ctx: 0, entry: entry.index})
        expect(entry.line_content)
          .to eq(entry.cached_line_content.gsub(inner_word, ''))
      end
    end
  end
end
