# frozen_string_literal: true

require 'active_support/core_ext/numeric/time'

class API::ESearch::Window
  include API::Mixins::BecomeTruthyWithinTimeout

  class MissingEntry < RuntimeError; end

  class_attribute :search_event_timeout, default: Configuration.search_event_timeout
  class_attribute :search_freeze_timeout, default: Configuration.search_freeze_timeout
  attr_reader :editor

  def initialize(editor)
    @editor = editor
  end

  def close_search!
    # TODO: Should be ignore_unsaved_changes: false, but it ignores bdelete! command
    editor.delete_current_buffer!(ignore_unsaved_changes: false) if inside_search_window?
  end

  def has_search_started?(timeout: search_event_timeout)
    became_truthy_within?(timeout) do
      editor.press!('lh') # press jk to close "Press ENTER or type command to continue" prompt
      inside_search_window?
    end
  end

  def has_search_finished?(timeout: search_event_timeout)
    became_truthy_within?(timeout) do
      editor.press!('lh') # press jk to close "Press ENTER or type command to continue" prompt
      parser.header_finished? || parser.header_errors?
    end
  end

  def has_reported_a_single_result?
    has_reported_single_result_in_header?
  end

  def has_not_reported_errors?
    !has_reported_errors_in_header?
  end

  def has_reported_single_result_in_header?
    parser.header.tap { |h| return h.lines_count == 1 && h.files_count == 1 }
  end

  def has_reported_errors_in_header?
    parser.header_errors?
  end

  def has_outputted_result_from_file_in_line?(relative_path, line)
    find_entry(relative_path, line).present?
  end

  def has_search_freezed?(timeout: search_freeze_timeout)
    !became_truthy_within?(timeout) do
      editor.with_ignore_cache { parser.header_finished? }
    end
  end

  def has_outputted_result_with_right_position_inside_file?(relative_path, line, column)
    location_in_file(relative_path, line) == [line, column]
  rescue MissingEntry
    false
  end

  def location_in_file(relative_path, line)
    entry = find_entry(relative_path, line)
    raise MissingEntry unless entry

    entry.open { return [editor.current_line_number, editor.current_column_number] }
  end

  def find_entry(relative_path, line)
    parser.entries.find do |entry|
      entry.relative_path == relative_path && entry.line_number == line
    end
  end

  def entries
    parser.entries
  end

  def inside_search_window?
    editor.current_buffer_name.match?(/Search/)
  end

  private

  def parser
    @parser ||= Parser.new(editor)
  end
end
