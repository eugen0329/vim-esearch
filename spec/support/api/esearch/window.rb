# frozen_string_literal: true

require 'active_support/core_ext/numeric/time'

class API::ESearch::Window
  include API::Mixins::BecomeTruthyWithinTimeout
  include VimlValue::SerializationHelpers

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
      editor.trigger_cursor_moved_event!
      break true if inside_search_window?
    end
  end

  def has_search_finished?(timeout: search_event_timeout)
    became_truthy_within?(timeout) do
      editor.trigger_cursor_moved_event!
      break true if parser.header_finished? || parser.header_errors?
    end
  end

  def has_search_highlight?(relative_path, line, column)
    entry = find_entry(relative_path, line)
    raise MissingEntry unless entry

    padding = entry.left_padding

    expected_match = [entry.line_in_window,
                      padding + column.begin,
                      padding + column.end]

    editor.matches_for('esearchMatch') == [expected_match]
  end

  def errors
    editor.lines
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

  def has_outputted_result_from_file_in_line?(relative_path, line_in_file)
    find_entry(relative_path, line_in_file).present?
  end

  def has_search_freezed?(timeout: search_freeze_timeout)
    !became_truthy_within?(timeout) do
      editor.with_ignore_cache { parser.header_finished? }
    end
  end

  def locate_entry(relative_path, line_in_file)
    editor.locate_line!(entry_location(relative_path, line_in_file))
  end

  def reload(entry)
    return nil if entry.nil?

    find_entry(entry.relative_path, entry.line_in_file)
  rescue MissingEntry
    nil
  end

  def reloaded_entries!(entries)
    editor.handle_state_change!
    entries.map { |entry| reload(entry) }
  end

  def entry_location(relative_path, line_in_file)
    entry = find_entry(relative_path, line_in_file)
    raise MissingEntry, entry unless entry

    entry.line_in_window
  end

  def has_outputted_result_with_right_position_inside_file?(relative_path, line_in_file, column)
    location_in_file(relative_path, line_in_file) == [line_in_file, column]
  rescue MissingEntry
    false
  end

  def location_in_file(relative_path, line_in_file)
    entry = find_entry(relative_path, line_in_file)
    raise MissingEntry unless entry

    entry.open { [editor.current_line_number, editor.current_column_number] }
  end

  def find_entry(relative_path, line_in_file)
    parser.entries.find do |entry|
      entry.relative_path == relative_path && entry.line_in_file == line_in_file
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
