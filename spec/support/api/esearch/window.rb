# frozen_string_literal: true

require 'pathname'
require 'active_support/core_ext/numeric/time'

# rubocop:disable Metrics/ClassLength
class API::ESearch::Window
  include API::Mixins::BecomeTruthyWithinTimeout
  include VimlValue::SerializationHelpers

  class MissingEntryError < RuntimeError; end

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

  def has_live_update_search_started?(timeout: search_event_timeout)
    became_truthy_within?(timeout) do
      break true if editor.with_ignore_cache { inside_live_update_window? }
    end
  end

  def has_no_live_update_search_started?(timeout: search_event_timeout)
    !has_live_update_search_started?(timeout: timeout)
  end

  def has_search_started?(timeout: search_event_timeout)
    became_truthy_within?(timeout) do
      break true if editor.with_ignore_cache { inside_search_window? }
    end
  end

  def has_search_finished?(timeout: search_event_timeout)
    became_truthy_within?(timeout) do
      break true if editor.with_ignore_cache { parser.header_finished? || has_reported_errors_in_messages? }
    end
  end

  def has_output_message?(_message, timeout: search_event_timeout)
    became_truthy_within?(timeout) do
      editor.messages.any? { |message| message.include?(message) }
    end
  end

  def has_valid_buffer_basename?(basename, timeout: search_event_timeout)
    became_truthy_within?(timeout) do
      expected = "Search #{esearch.configuration.ql}#{basename}#{esearch.configuration.qr}"
      break true if editor.with_ignore_cache { editor.current_buffer_basename == expected }
    end
  end

  def has_filename_highlight?(relative_path)
    # Both a valid. The only difference is that vim escapes > and + only when
    # they are leading
    filename_variations = [editor.escape_regexp(editor.escape_filename(relative_path)),
                           editor.escape_regexp(editor.escape_filename("./#{relative_path}")),
                           "^\\x\\{40}:#{editor.escape_regexp(relative_path)}",]
    editor.syntax_aliases_at([filename_variations.join('\|')]) ==
      [%w[esearchFilename Directory]]
  end

  def has_search_highlight?(relative_path, line, column)
    entry = find_entry(relative_path, line)
    raise MissingEntryError if entry.empty?

    padding = entry.left_padding

    expected_match = [entry.line_in_window,
                      padding + column.begin,
                      padding + column.end,]

    editor.matches_for('esearchMatch') == [expected_match]
  end

  def errors
    editor.lines
  end

  def has_reported_a_single_result?
    has_reported_single_result_in_header?
  end

  def has_not_reported_errors?
    !has_reported_errors_in_messages?
  end

  def has_reported_single_result_in_header?
    parser.header.tap { |h| return h.lines_count == 1 && h.files_count == 1 }
  end

  def has_reported_errors_in_messages?
    editor.messages.any? { |m| m.include?('returned status') }
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
    find_entry(entry.relative_path, entry.line_in_file)
  end

  def reloaded_entries!(entries)
    editor.invalidate_cache!
    entries.map { |entry| reload(entry) }
  end

  def entry_location(relative_path, line_in_file)
    entry = find_entry(relative_path, line_in_file)
    raise MissingEntryError, entry if entry.empty?

    entry.line_in_window
  end

  def location_in_file(relative_path, line_in_file)
    entry = find_entry(relative_path, line_in_file)
    raise MissingEntryError if entry.empty?

    entry.open { [editor.current_line_number, editor.current_column_number] }
  end

  def find_entry(relative_path, line_in_file)
    found = parser.entries.find do |entry|
      entry_path = Pathname(entry.relative_path).cleanpath.sub(/^\h{7,40}:/, '')

      # Both a valid. The only difference is that vim escapes > and + only when
      # they are leading
      path_variations = [Pathname(editor.escape_filename("./#{relative_path}")).cleanpath,
                         Pathname(editor.escape_filename(relative_path)).cleanpath,]

      path_variations.include?(entry_path) && entry.line_in_file == line_in_file
    end

    found || MissingEntry.new(relative_path, line_in_file)
  end

  def entries
    parser.entries
  end

  def inside_live_update_window?
    editor.current_buffer_name.match?(/\[esearch\]/)
  end

  def inside_search_window?
    editor.current_buffer_basename.match?(/^Search/)
  end

  private

  def parser
    @parser ||= Parser.new(editor)
  end
end
# rubocop:enable Metrics/ClassLength
