# frozen_string_literal: true

class API::ESearch::Window::EntriesParser
  class MissingEntryError < RuntimeError; end

  class MissingBlankLineError < RuntimeError; end

  FILE_NAME_REGEXP = /\A[^ ]/.freeze
  FILE_ENTRY_REGEXP = /\A\s{1,3}[1-9]\d*\s/.freeze

  attr_reader :editor, :lines_enum

  def initialize(editor)
    @editor = editor
    @lines_enum = editor.lines.with_index(1)
  end

  def parse
    return enum_for(:parse) unless block_given?

    lines_enum.rewind
    lines_enum.next # skip header

    loop do
      raise MissingBlankLineError unless lines_enum.peek[0].empty?

      lines_enum.next

      relative_path = next_file_relative_path!
      raise MissingEntryError, lines_enum.peek[0] unless line_with_entry?

      next_lines_with_entries! do |line_content, line_in_window|
        yield API::ESearch::Window::Entry
          .new(editor,
            relative_path,
            line_content,
            line_in_window)
      end
    end
  rescue StopIteration
    nil
  end

  private

  def line_with_entry?
    lines_enum.peek[0].match?(FILE_ENTRY_REGEXP)
  end

  def next_file_relative_path!
    lines_enum.next[0]
  end

  def next_lines_with_entries!
    yield lines_enum.next while line_with_entry?
  end
end
