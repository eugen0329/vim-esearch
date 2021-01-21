# frozen_string_literal: true

require 'active_support/core_ext/object/instance_variables'

class API::ESearch::Window::Entry
  include API::Mixins::RollbackState
  include API::Mixins::BecomeTruthyWithinTimeout

  class OpenEntryError < RuntimeError; end

  class_attribute :rollback_inside_buffer_on_open, default: true

  attr_reader :editor, :line_content, :line_in_window, :relative_path

  def initialize(editor, relative_path, line_content, line_in_window)
    @editor = editor
    @relative_path = relative_path
    @line_content = line_content
    @line_in_window = line_in_window
  end

  def line_in_file
    line_content.to_i # takes leading int
  end

  def line_number_text
    line_content.scan(/\s+\d+\s/)[0]
  end

  def result_text
    @result_text ||= line_content.scan(/\s+\d+\s(.*)/)[0][0]
  end

  def left_padding
    line_content.scan(/\s+\d+\s/).first.length
  end

  def locate!
    editor.locate_cursor!(line_in_window, left_padding + 1)
  end

  def open(timeout: 20)
    old_buffer_name = editor.current_buffer_name

    unless block_given?
      editor.locate_line! line_in_window
      editor.press_with_user_mappings! '\<enter>'
    end

    rollback_open do
      editor.locate_line! line_in_window
      editor.press_with_user_mappings! '\<enter>'

      opened_correctly = editor.with_ignore_cache do
        became_truthy_within?(timeout) do
          old_buffer_name != editor.current_buffer_name
        end
      end

      raise OpenEntryError, "Entry was opened incorrectly #{inspect}" unless opened_correctly

      yield
    end
  end

  def empty?
    false
  end

  def inspect
    "#{relative_path}:#{line_in_file.inspect}: #{result_text} (line #{line_in_window})".inspect
  end

  def eql?(other)
    self == other
  end

  def ==(other)
    line_content == other.line_content &&
      relative_path == other.relative_path
  end

  private

  def rollback_open(&block)
    if rollback_inside_buffer_on_open?
      rollback_cursor_location(editor, &block)
    else
      rollback_current_buffer(editor, &block)
    end
  end
end
