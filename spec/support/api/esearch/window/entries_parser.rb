# frozen_string_literal: true

class API::ESearch::Window::EntriesParser
  class MissingEntryError < RuntimeError; end

  FILE_NAME_REGEXP = /\A[^ ]/.freeze
  FILE_ENTRY_REGEXP = /\A\s+\d+/.freeze

  attr_reader :editor, :lines_iterator

  def initialize(editor)
    @editor = editor
    @lines_iterator = editor.lines(3..).with_index
  end

  def parse
    return enum_for(:parse) unless block_given?

    lines_iterator.rewind

    loop do
      relative_path = next_file_relative_path!
      raise MissingEntryError, lines_iterator.peek[0] unless line_with_entry?

      next_lines_with_entries! do |line|
        yield API::ESearch::Window::Entry.new(editor, relative_path, *line)
      end
    rescue StopIteration
      nil
    end
  end

  private

  def line_with_entry?
    lines_iterator.peek[0].match?(FILE_ENTRY_REGEXP)
  end

  def next_file_relative_path!
    relative_path = lines_iterator.next[0] while relative_path !~ FILE_NAME_REGEXP
    relative_path
  end

  def next_lines_with_entries!
    yield lines_iterator.next while line_with_entry?
  end
end
