# frozen_string_literal: true

class API::ESearch::Window::Entry
  include API::Mixins::RollbackState

  class OpenEntryError < RuntimeError; end

  class_attribute :rollback_inside_buffer_on_open, default: true

  attr_reader :editor, :context, :line_in_window, :relative_path

  def initialize(editor, relative_path, context, line_in_window)
    @editor = editor
    @relative_path = relative_path
    @context = context
    @line_in_window = line_in_window
  end

  def line_number
    context.to_i # takes leading int
  end

  def open
    old_buffer_name = editor.current_buffer_name

    editor.ignoring_cache do
      rollback_open do
        editor.locate_line! line_in_window + 1
        editor.press_with_user_mappings! '\<Enter>'
        raise OpenEntryError, "can't open entry #{inspect}" if old_buffer_name == editor.current_buffer_name

        yield
      end
    end
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
